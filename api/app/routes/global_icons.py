"""
Global icons: per-platform bundled assets (Web SVG, Android vector XML, iOS/macOS SVG,
Windows PNG, Linux SVG) with S3 paths; metadata for search. Fallback file API for Noolva console.
"""

from __future__ import annotations

import asyncio
import logging
import re
from io import BytesIO
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import FileResponse
from pydantic import BaseModel, Field

from classes.postgres_db import PostgresDB
from middlewares.auth import verify_jwt_token
from routes.upload import _get_company_id_for_s3, _get_default_s3_service

router = APIRouter()
logger = logging.getLogger(__name__)

ICON_KEY_RE = re.compile(r"^[a-z0-9_]+$")
ASSETS_GLOBAL_ICONS = Path(__file__).resolve().parent.parent.parent / "assets" / "global_icons"
_PLATFORMS = frozenset({"web", "android", "ios", "macos", "windows", "linux"})

_LOCAL_FILE: Dict[str, Tuple[str, str, str]] = {
    "web": ("web", "svg", "image/svg+xml"),
    "android": ("android", "xml", "application/xml"),
    "ios": ("ios", "svg", "image/svg+xml"),
    "macos": ("macos", "svg", "image/svg+xml"),
    "windows": ("windows", "png", "image/png"),
    "linux": ("linux", "svg", "image/svg+xml"),
}

_AUTH_ROLES = ["saas_admin", "saas_employee", "tenant_admin", "tenant_user"]


def _logical_web_path(row: Dict[str, Any]) -> str:
    p = (row.get("icon_path_web") or "").strip()
    if p:
        return p.lstrip("/")
    key = (row.get("icon_key") or "").strip()
    return f"public/global_icons/web/{key}.svg"


class SyncBody(BaseModel):
    icon_key: Optional[str] = Field(None, description="Sync a single icon by key (all platform files)")
    sync_all: bool = Field(False, description="Sync global_icons in batches (use cursor_after + icons_per_batch)")
    cursor_after: Optional[str] = Field(
        None,
        description='Start after this icon_key (exclusive). Omit or empty for the first batch.',
    )
    icons_per_batch: int = Field(
        20,
        ge=1,
        le=250,
        description="Max icon keys per HTTP request when sync_all (each key uploads up to 6 files). Lower if proxies timeout.",
    )


def _local_path_for_platform(icon_key: str, platform: str) -> Tuple[Path, str]:
    plat = (platform or "web").lower().strip()
    if plat not in _LOCAL_FILE:
        raise HTTPException(status_code=400, detail="Invalid platform (use web|android|ios|macos|windows|linux)")
    subdir, ext, media = _LOCAL_FILE[plat]
    return ASSETS_GLOBAL_ICONS / subdir / f"{icon_key}.{ext}", media


@router.get("/list")
async def list_global_icons(
    check_s3: bool = Query(
        False,
        description=(
            "If true, runs one S3 HEAD per icon to set s3_exists (slow, many API calls). "
            "Default false: return CDN URLs only; the browser loads CDN first and uses "
            "GET /global-icons/file only if the image errors."
        ),
    ),
    user: Dict = Depends(verify_jwt_token(_AUTH_ROLES)),
):
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    rows = await PostgresDB.fetch(
        """
        SELECT id, icon_key, icon_path_web, icon_path_android, icon_path_ios, icon_path_macos,
               icon_path_windows, icon_path_linux, description, keywords
        FROM public.global_icons
        ORDER BY icon_key
        """
    )
    s3 = None
    try:
        company_id = _get_company_id_for_s3(user)
        s3 = await _get_default_s3_service(company_id)
    except HTTPException:
        s3 = None
    except Exception as e:
        logger.warning("global_icons list: S3 not available: %s", e)
        s3 = None

    async def enrich(r: Dict[str, Any]) -> Dict[str, Any]:
        d = dict(r)
        logical = _logical_web_path(d)
        d["icon_path_web_resolved"] = logical
        if s3:
            d["public_url_web"] = s3.public_url_for_logical_key(logical)

            if check_s3:

                def _exists():
                    try:
                        return s3.object_exists(logical)
                    except Exception as ex:
                        logger.debug("head_object %s: %s", logical, ex)
                        return None

                d["s3_exists"] = await asyncio.to_thread(_exists)
            else:
                d["s3_exists"] = None
        else:
            d["public_url_web"] = None
            d["s3_exists"] = None
        return d

    enriched = await asyncio.gather(*[enrich(dict(r)) for r in rows])
    out: Dict[str, Any] = {
        "icons": enriched,
        "count": len(enriched),
        "preview_cdn_first": True,
        "check_s3": check_s3,
    }
    if s3 and getattr(s3, "cdn_url", None):
        out["cdn_base_url"] = s3.cdn_url
    return out


@router.get("/file/{icon_key}")
async def get_global_icon_file(
    icon_key: str,
    platform: str = Query("web", description="web | android | ios | macos | windows | linux"),
    user: Dict = Depends(verify_jwt_token(_AUTH_ROLES)),
):
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    key = (icon_key or "").strip().lower()
    if not ICON_KEY_RE.match(key):
        raise HTTPException(status_code=400, detail="Invalid icon_key")
    row = await PostgresDB.fetchrow(
        "SELECT 1 FROM public.global_icons WHERE icon_key = $1",
        key,
    )
    if not row:
        raise HTTPException(status_code=404, detail="Unknown icon_key")
    path, media = _local_path_for_platform(key, platform)
    if not path.is_file():
        raise HTTPException(status_code=404, detail="Bundled asset not found on Noolva API host")
    return FileResponse(path, media_type=media, filename=path.name)


@router.post("/sync")
async def sync_global_icons_to_s3(
    body: SyncBody,
    user: Dict = Depends(verify_jwt_token(_AUTH_ROLES)),
):
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    if not body.sync_all and not body.icon_key:
        raise HTTPException(status_code=400, detail="Provide icon_key or sync_all=true")
    company_id = _get_company_id_for_s3(user)
    s3 = await _get_default_s3_service(company_id)

    cols = (
        "icon_path_web",
        "icon_path_android",
        "icon_path_ios",
        "icon_path_macos",
        "icon_path_windows",
        "icon_path_linux",
    )
    col_to_plat = {c: c.replace("icon_path_", "") for c in cols}

    if body.sync_all:
        cur = (body.cursor_after or "").strip().lower()
        if cur and not ICON_KEY_RE.match(cur):
            raise HTTPException(status_code=400, detail="Invalid cursor_after icon_key")
        limit = body.icons_per_batch
        rows = await PostgresDB.fetch(
            f"""
            SELECT icon_key, {", ".join(cols)}
            FROM public.global_icons
            WHERE ($1::text IS NULL OR $1 = '' OR icon_key > $1)
            ORDER BY icon_key
            LIMIT $2
            """,
            cur or None,
            limit,
        )
        batch_complete = len(rows) < limit
        next_cursor: Optional[str] = None
        if rows and len(rows) == limit:
            next_cursor = rows[-1]["icon_key"]
    else:
        k = (body.icon_key or "").strip().lower()
        if not ICON_KEY_RE.match(k):
            raise HTTPException(status_code=400, detail="Invalid icon_key")
        rows = await PostgresDB.fetch(
            f"""
            SELECT icon_key, {", ".join(cols)}
            FROM public.global_icons
            WHERE icon_key = $1
            """,
            k,
        )
        if not rows:
            raise HTTPException(status_code=404, detail="Unknown icon_key")
        batch_complete = True
        next_cursor = None

    results: List[Dict[str, Any]] = []
    errors: List[str] = []

    upload_sem = asyncio.Semaphore(4)

    async def _upload_one(logical: str, local_path: Path, content_type: str, key: str, plat: str) -> None:
        if not local_path.is_file():
            errors.append(f"{key}: missing local file {local_path.name} ({plat})")
            return

        async def _run():
            data = local_path.read_bytes()

            def _put():
                return s3.upload_fileobj(
                    BytesIO(data),
                    s3_key=logical,
                    is_public=True,
                    content_type=content_type,
                )

            return await asyncio.to_thread(_put)

        async with upload_sem:
            try:
                up = await _run()
            except Exception as e:
                logger.exception("sync global icon %s %s", key, plat)
                errors.append(f"{key}/{plat}: {str(e)}")
                return
        if not up.get("success"):
            errors.append(f"{key}/{plat}: {up.get('message', 'upload failed')}")
            return
        results.append(
            {
                "icon_key": key,
                "platform": plat,
                "s3_key": up.get("s3_key"),
                "public_url": up.get("public_url"),
            }
        )

    tasks: List[Any] = []
    for r in rows:
        key = r["icon_key"]
        for col in cols:
            logical = (r.get(col) or "").strip().lstrip("/")
            if not logical:
                continue
            plat = col_to_plat[col]
            try:
                local_path, content_type = _local_path_for_platform(key, plat)
            except HTTPException:
                errors.append(f"{key}: bad platform for {col}")
                continue
            tasks.append(
                asyncio.create_task(_upload_one(logical, local_path, content_type, key, plat))
            )

    if tasks:
        await asyncio.gather(*tasks)

    out: Dict[str, Any] = {
        "success": len(errors) == 0,
        "uploaded": results,
        "errors": errors,
        "count": len(results),
        "icons_in_batch": len(rows),
        "files_uploaded": len(results),
    }
    if body.sync_all:
        out["batch_complete"] = batch_complete
        out["next_cursor"] = next_cursor
    return out
