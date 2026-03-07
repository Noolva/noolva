"""
Generate image thumbnails for S3 uploads.
Supports optional crop_ratio (e.g. "1:1") from field config before resizing.
"""
import logging
from io import BytesIO
from typing import Optional, Tuple

logger = logging.getLogger(__name__)

try:
    from PIL import Image
    PIL_AVAILABLE = True
except ImportError:
    PIL_AVAILABLE = False

# Default max dimension for thumbnail (longest side)
THUMB_MAX_SIZE = 300


def _parse_ratio(ratio: str) -> Optional[Tuple[float, float]]:
    """Parse crop_ratio string like '1:1' or '16:9' into (w, h). Returns None if invalid."""
    if not ratio or not isinstance(ratio, str):
        return None
    parts = ratio.strip().split(":")
    if len(parts) != 2:
        return None
    try:
        w, h = float(parts[0].strip()), float(parts[1].strip())
        if w <= 0 or h <= 0:
            return None
        return (w, h)
    except (ValueError, TypeError):
        return None


def _center_crop_to_ratio(img: "Image.Image", ratio: Tuple[float, float]) -> "Image.Image":
    """Crop image to the given aspect ratio (center crop)."""
    w, h = img.size
    target_w_ratio, target_h_ratio = ratio[0], ratio[1]
    current_ratio = w / h
    target_ratio = target_w_ratio / target_h_ratio
    if current_ratio > target_ratio:
        # Image is wider: crop width
        new_w = int(h * target_ratio)
        left = (w - new_w) // 2
        return img.crop((left, 0, left + new_w, h))
    else:
        # Image is taller: crop height
        new_h = int(w / target_ratio)
        top = (h - new_h) // 2
        return img.crop((0, top, w, top + new_h))


def generate_thumbnail(
    image_bytes: bytes,
    crop_ratio: Optional[str] = None,
    max_size: int = THUMB_MAX_SIZE,
    output_format: str = "JPEG",
    quality: int = 85,
) -> Optional[bytes]:
    """
    Generate thumbnail from image bytes.
    If crop_ratio is provided (e.g. "1:1"), center-crop to that ratio before resizing.

    Returns thumbnail bytes (JPEG) or None if generation fails.
    """
    if not PIL_AVAILABLE or not image_bytes:
        if not PIL_AVAILABLE:
            logger.debug("thumbnail: PIL not available")
        return None
    try:
        img = Image.open(BytesIO(image_bytes))
        # Handle EXIF orientation and ensure RGB for JPEG
        if hasattr(img, "getexif") and img.getexif():
            try:
                from PIL import ImageOps
                img = ImageOps.exif_transpose(img)
            except Exception:
                pass
        if img.mode in ("RGBA", "P"):
            img = img.convert("RGB")
        elif img.mode != "RGB":
            img = img.convert("RGB")

        ratio = _parse_ratio(crop_ratio) if crop_ratio else None
        if ratio:
            img = _center_crop_to_ratio(img, ratio)

        img.thumbnail((max_size, max_size), Image.Resampling.LANCZOS)
        out = BytesIO()
        img.save(out, format=output_format, quality=quality, optimize=True)
        return out.getvalue()
    except Exception as e:
        logger.debug("thumbnail generation failed: %s", e)
        return None
