"""
Upload route: upload files to the default S3 bucket from integrations table.
Authenticated via JWT or Personal Access Token (PAT). Use this endpoint for forms
and external apps (e.g. other app connecting with PAT) to upload to default S3.
Supports single and multi-file uploads. Uses default S3 integration config
(url, bucket_prefix, etc.). Public files: CDN open access; private: signed URL required.
"""
import json
import logging
import os
import re
import uuid
from typing import Optional, List, Tuple, Any

from fastapi import APIRouter, HTTPException, Header, UploadFile, File, Form, Query
from fastapi.responses import RedirectResponse, StreamingResponse
from classes.postgres_db import PostgresDB
from middlewares.auth import resolve_bearer_to_user
from io import BytesIO

router = APIRouter()
logger = logging.getLogger(__name__)


async def _require_user(authorization: Optional[str] = Header(None)):
    """Require valid Bearer token (JWT or PAT)."""
    user = await resolve_bearer_to_user(authorization)
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required (Bearer JWT or PAT)")
    return user


def _get_company_id_for_s3(user: dict) -> Optional[int]:
    """Resolve company_id for fetching default S3 integration (user's company or first company)."""
    cid = user.get("company_id")
    if cid is not None:
        return int(cid)
    return None


async def _get_default_s3_service(company_id: Optional[int]):
    """
    Load default S3 integration for company, decrypt credentials, return S3Service.
    If company_id is None, use first company (single-tenant / setup default).
    """
    from utils.encryption_service import get_encryption_service
    from utils.s3_service import S3Service

    if company_id is None:
        row = await PostgresDB.fetchrow(
            """
            SELECT i.integration_id, i.company_id, i.encrypted_credentials, i.config
            FROM public.integrations i
            WHERE i.provider_name = 'aws_s3' AND i.is_default = TRUE AND i.is_active = TRUE
            ORDER BY i.company_id NULLS LAST
            LIMIT 1
            """
        )
    else:
        row = await PostgresDB.fetchrow(
            """
            SELECT i.integration_id, i.company_id, i.encrypted_credentials, i.config
            FROM public.integrations i
            WHERE i.provider_name = 'aws_s3' AND i.is_default = TRUE AND i.is_active = TRUE
              AND i.company_id = $1
            LIMIT 1
            """,
            company_id,
        )
    if not row:
        raise HTTPException(
            status_code=503,
            detail="Default S3 integration not configured. Configure S3 in setup or integrations.",
        )
    enc = get_encryption_service()
    try:
        credentials = enc.decrypt(row["encrypted_credentials"])
    except Exception as e:
        raise HTTPException(status_code=500, detail="Failed to decrypt S3 credentials") from e
    # credentials may be stored as JSON string; normalize to dict
    if isinstance(credentials, str):
        try:
            credentials = json.loads(credentials) if credentials.strip() else {}
        except Exception:
            credentials = {}
    if not isinstance(credentials, dict):
        credentials = {}
    raw_config = row.get("config")
    if isinstance(raw_config, dict):
        config = raw_config
    else:
        config = {}
    # Merge: credentials hold secrets; config holds bucket_name, region, bucket_prefix, url (CDN base for model-attachments)
    merged = {
        "aws_access_key_id": credentials.get("aws_access_key_id"),
        "aws_secret_access_key": credentials.get("aws_secret_access_key"),
        "bucket_name": config.get("bucket_name") or credentials.get("bucket_name"),
        "aws_region": config.get("region") or credentials.get("aws_region") or "us-east-1",
        "bucket_prefix": config.get("bucket_prefix") or credentials.get("bucket_prefix"),
        "endpoint_url": credentials.get("endpoint_url"),
        "cdn_url": config.get("url") or config.get("cdn_url") or credentials.get("cdn_url"),
    }
    if not merged.get("aws_access_key_id") or not merged.get("aws_secret_access_key") or not merged.get("bucket_name"):
        raise HTTPException(status_code=500, detail="Default S3 integration missing required credentials")
    return S3Service.from_integration_config(merged)


def _is_safe_identifier(value: str) -> bool:
    return bool(re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", value or ""))


def _looks_like_uuid(value: str) -> bool:
    """Return True if value looks like a UUID string."""
    if not value or not isinstance(value, str):
        return False
    return bool(re.fullmatch(r"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}", value.strip()))


async def _get_primary_key_column(table_name: str) -> Optional[str]:
    """Return the primary key column name for the table, or None."""
    row = await PostgresDB.fetchrow(
        """
        SELECT kcu.column_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
        WHERE tc.table_schema = 'public' AND tc.table_name = $1 AND tc.constraint_type = 'PRIMARY KEY'
        LIMIT 1
        """,
        table_name,
    )
    return (row or {}).get("column_name")


async def _resolve_record_id_column_and_value(table_name: str, record_id: str) -> Tuple[Optional[str], Any]:
    """
    Resolve (column_name, value) for WHERE clause when looking up by record_id.
    Supports both integer PK and UUID: if record_id looks like UUID and table has a uuid column, use it; else use PK.
    """
    if not _is_safe_identifier(table_name) or not record_id:
        return (None, None)
    pk_col = await _get_primary_key_column(table_name)
    if not pk_col:
        return (None, None)
    record_id = record_id.strip()
    if _looks_like_uuid(record_id):
        uuid_cols = await PostgresDB.fetch(
            """
            SELECT column_name FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = $1 AND data_type = 'uuid'
            ORDER BY column_name
            """,
            table_name,
        )
        if uuid_cols:
            col = (uuid_cols[0] or {}).get("column_name")
            if col:
                return (col, record_id)
    pk_type_row = await PostgresDB.fetchrow(
        """
        SELECT data_type FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = $1 AND column_name = $2
        """,
        table_name,
        pk_col,
    )
    data_type = (pk_type_row or {}).get("data_type", "")
    if data_type in ("integer", "bigint", "smallint", "serial", "bigserial"):
        try:
            return (pk_col, int(record_id))
        except ValueError:
            return (pk_col, record_id)
    return (pk_col, record_id)


async def _get_field_config_and_type(model_name: str, field_name: str) -> Tuple[Optional[dict], Optional[str], Optional[str]]:
    """Get (field_config_json, type_code, encryption_method) for a file/image field. type_code is 'file' or 'image'."""
    if not _is_safe_identifier(model_name) or not _is_safe_identifier(field_name):
        return (None, None, None)
    row = await PostgresDB.fetchrow(
        """
        SELECT dmf.field_config_json, LOWER(ft.type_code) AS type_code,
               COALESCE(LOWER(TRIM(dmf.encryption_method::text)), 'none') AS encryption_method
        FROM public.data_models dm
        JOIN public.data_model_fields dmf ON dmf.model_id = dm.model_id
        JOIN public.field_types ft ON ft.field_type_id = dmf.field_type_id
        WHERE dm.model_name = $1 AND dm.is_active = TRUE
          AND dmf.field_name = $2
          AND LOWER(ft.type_code) IN ('file', 'image')
        LIMIT 1
        """,
        model_name,
        field_name,
    )
    if not row:
        return (None, None, None)
    val = row.get("field_config_json")
    type_code = (row.get("type_code") or "").strip() or None
    encryption_method = (row.get("encryption_method") or "none").strip() or None
    if isinstance(val, dict):
        config = val
    elif isinstance(val, str):
        try:
            parsed = json.loads(val)
            config = parsed if isinstance(parsed, dict) else None
        except (json.JSONDecodeError, TypeError):
            config = None
    else:
        config = None
    return (config, type_code, encryption_method)


def _thumbnail_key_from_main_key(main_key: str) -> str:
    """Given main S3 key e.g. path/subfolder/myfile.jpg, return path/subfolder/myfile_thumb.jpg."""
    if not main_key:
        return main_key
    dirname = os.path.dirname(main_key)
    base = os.path.basename(main_key)
    name, ext = os.path.splitext(base)
    ext = ext or ".jpg"
    thumb_basename = f"{name}_thumb{ext}"
    if not dirname:
        return thumb_basename
    return f"{dirname}/{thumb_basename}"


def _allowed_extensions_from_config(config: Optional[dict]) -> Optional[List[str]]:
    """Return list of allowed extensions (e.g. ['.jpg', '.png']) or None if any."""
    if not config:
        return None
    filters = config.get("filters")
    if not filters or not isinstance(filters, list):
        return None
    return [x if x.startswith(".") else f".{x}" for x in filters if isinstance(x, str)]


async def _get_current_attachment_path(model_name: str, field_name: str, record_id: str) -> Optional[str]:
    """Fetch current value of an attachment field for a record (for delete-old on upload)."""
    paths = await _get_current_attachment_paths(model_name, field_name, record_id)
    return paths[0] if paths else None


async def _get_current_attachment_paths(model_name: str, field_name: str, record_id: str) -> List[str]:
    """Fetch current value(s) of an attachment field (single path or JSON array of paths)."""
    if not _is_safe_identifier(model_name) or not _is_safe_identifier(field_name) or not record_id:
        return []
    model = await PostgresDB.fetchrow(
        "SELECT table_name FROM public.data_models WHERE model_name = $1 AND is_active = TRUE",
        model_name,
    )
    if not model:
        return []
    table_name = model.get("table_name")
    if not table_name or not _is_safe_identifier(table_name):
        return []
    where_col, where_val = await _resolve_record_id_column_and_value(table_name, record_id)
    if not where_col or where_val is None:
        return []
    row = await PostgresDB.fetchrow(
        f'SELECT "{field_name}" AS val FROM public."{table_name}" WHERE "{where_col}" = $1',
        where_val,
    )
    if not row or row.get("val") is None:
        return []
    val = row["val"]
    if val is None:
        return []
    if isinstance(val, str):
        val = val.strip()
        if not val:
            return []
        # May be JSON array of paths (for multiple file field)
        if val.startswith("["):
            try:
                arr = json.loads(val)
                if isinstance(arr, list):
                    return [str(x).strip() for x in arr if x and str(x).strip() and not str(x).strip().startswith(("http://", "https://"))]
                return [val]
            except (json.JSONDecodeError, TypeError):
                return [val] if not val.startswith(("http://", "https://")) else []
    return [str(val).strip()] if not str(val).strip().startswith(("http://", "https://")) else []


def _validate_file_against_field_config(
    filename: Optional[str],
    file_size: int,
    field_config: Optional[dict],
) -> None:
    """Raise HTTPException if file does not match field config (filters, max_size_mb)."""
    if not field_config:
        return
    allowed = _allowed_extensions_from_config(field_config)
    if allowed and filename:
        ext = os.path.splitext(filename or "")[1].lower()
        if ext and ext not in [e.lower() for e in allowed]:
            raise HTTPException(
                status_code=400,
                detail=f"File type not allowed. Allowed: {', '.join(allowed)}",
            )
    max_mb = field_config.get("max_size_mb")
    if max_mb is not None and isinstance(max_mb, (int, float)):
        max_bytes = int(max_mb * 1024 * 1024)
        if file_size > max_bytes:
            raise HTTPException(
                status_code=400,
                detail=f"File size exceeds max {max_mb} MB",
            )


@router.post("/upload")
async def upload_to_default_s3(
    file: Optional[UploadFile] = File(None, description="Single file (use this or files, not both)."),
    files: Optional[List[UploadFile]] = File(None, description="Multiple files (alternative to file)."),
    key: Optional[str] = Form(None, description="Optional S3 key/path. Omit when using model_name (model-attachments path)."),
    is_public: str = Form("true", description="Whether the file(s) are public (true) or private (false). Private requires signed URL for access."),
    model_name: Optional[str] = Form(None, description="Model name for model-attachments path (e.g. persons)."),
    field_name: Optional[str] = Form(None, description="Field name (e.g. profile_photo). Used for delete-old and optional field_config validation (filters, max_size_mb)."),
    record_id: Optional[str] = Form(None, description="Record id; with field_name, previous file(s) for this field are deleted from S3."),
    authorization: Optional[str] = Header(None),
):
    """
    Upload one or more files to the default S3 bucket (from integrations table).
    Auth: Bearer token (JWT or Personal Access Token).
    Either key or model_name must be provided. For model-attachments: path = bucket_prefix + public|private + model-attachments + model_name + unique_id.
    Public: CDN open access (config.url). Private: stored under private/; access via signed URL.
    When model_name + field_name are provided, field_config (filters, max_size_mb) is applied if the field is file/image type.
    Thumbnails are generated for image fields, or file fields when the uploaded file is an image format, when the field's stored config has generate_thumbnail=true (no need to pass it in the request).
    Single file: response has s3_key, path, public_url. Multiple: response has uploads array.
    """
    user = await _require_user(authorization)
    company_id = _get_company_id_for_s3(user)
    s3 = await _get_default_s3_service(company_id)

    if not key and not model_name:
        raise HTTPException(status_code=400, detail="Either key or model_name is required")
    if key and model_name:
        raise HTTPException(status_code=400, detail="Provide key OR model_name, not both")

    # Collect file list: prefer multiple 'files', else single 'file'
    file_list: List[UploadFile] = []
    if files:
        file_list = [f for f in files if f and getattr(f, "filename", None) is not None]
    if not file_list and file and getattr(file, "filename", None) is not None:
        file_list = [file]
    if not file_list:
        raise HTTPException(status_code=400, detail="At least one file is required (file or files)")

    is_public_bool = (is_public or "true").strip().lower() in ("true", "1", "yes")

    # Optional field config, type, and encryption for validation, thumbnail, and file-content encryption
    field_config: Optional[dict] = None
    field_type_code: Optional[str] = None
    field_encryption_method: Optional[str] = None
    if model_name and field_name and _is_safe_identifier(model_name) and _is_safe_identifier(field_name):
        field_config, field_type_code, field_encryption_method = await _get_field_config_and_type(model_name, field_name)

    # Delete old attachment(s) and their thumbnails when replacing
    if model_name and record_id and field_name and _is_safe_identifier(field_name) and len(file_list) >= 1:
        old_paths = await _get_current_attachment_paths(model_name, field_name, record_id)
        for old_path in old_paths:
            try:
                s3.delete_object(old_path)
            except Exception:
                pass
            # Delete thumbnail if it exists (path/subfolder/myfile_thumb.jpg for path/subfolder/myfile.jpg)
            try:
                thumb_path = _thumbnail_key_from_main_key(old_path)
                if thumb_path != old_path:
                    s3.delete_object(thumb_path)
            except Exception:
                pass

    segment = "public" if is_public_bool else "private"
    use_model_attachments = bool(model_name and _is_safe_identifier(model_name))
    uploads_result: List[dict] = []

    for f in file_list:
        filename = getattr(f, "filename", None) or ""
        try:
            content = await f.read()
            file_size = len(content)
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Could not read file {filename}: {str(e)}") from e

        _validate_file_against_field_config(filename, file_size, field_config)

        # For file/image fields with encryption: encrypt file content before upload (path stays plain in DB)
        method = (field_encryption_method or "none").strip().lower() if field_encryption_method else "none"
        if field_type_code in ("file", "image") and method in ("xor_cipher", "aes"):
            from utils.field_encryption import encrypt_file_content
            encrypted_content = encrypt_file_content(method, content)
            if encrypted_content is not None:
                content = encrypted_content

        ext = os.path.splitext(filename or "")[1] or ""
        unique_id = f"{uuid.uuid4().hex}{ext}"
        if use_model_attachments:
            s3_key = f"{segment}/model-attachments/{model_name}/{unique_id}"
        else:
            if not filename and not key:
                raise HTTPException(status_code=400, detail="Either file name or key is required")
            s3_key = key.strip().lstrip("/") if key and not uploads_result else f"uploads/{uuid.uuid4().hex}{ext}"

        content_type = getattr(f, "content_type", None) or None
        try:
            from io import BytesIO
            result = s3.upload_fileobj(
                BytesIO(content),
                s3_key=s3_key,
                is_public=is_public_bool,
                content_type=content_type,
            )
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Upload failed for {filename}: {str(e)}") from e

        if not result.get("success"):
            raise HTTPException(
                status_code=500,
                detail=result.get("message", "Upload failed"),
            )
        full_path = result.get("s3_key")
        # Generate and upload thumbnail for image/file fields when generate_thumbnail is true (file: only if content is image)
        if model_name and field_name and _is_safe_identifier(model_name) and _is_safe_identifier(field_name):
            if field_type_code not in ("image", "file"):
                logger.info("thumbnail skipped: field is not image/file type (type=%s)", field_type_code or "unknown")
            elif not field_config:
                logger.info(
                    "thumbnail skipped: no field config (model_name=%s, field_name=%s; check field exists as file/image and has field_config_json)",
                    model_name,
                    field_name,
                )
            elif field_config.get("generate_thumbnail") is not True:
                logger.info("thumbnail skipped: generate_thumbnail not true in field config")
            elif not content:
                logger.info("thumbnail skipped: no file content")
            else:
                from utils.thumbnail import generate_thumbnail

                crop_ratio = field_config.get("crop_ratio") if isinstance(field_config.get("crop_ratio"), str) else None
                thumb_bytes = generate_thumbnail(content, crop_ratio=crop_ratio)
                if thumb_bytes:
                    thumb_key = _thumbnail_key_from_main_key(s3_key)
                    try:
                        s3.upload_fileobj(
                            BytesIO(thumb_bytes),
                            s3_key=thumb_key,
                            is_public=is_public_bool,
                            content_type="image/jpeg",
                        )
                        logger.info("thumbnail generated: key=%s", thumb_key)
                    except Exception as e:
                        logger.warning("thumbnail generated but upload failed: key=%s error=%s", thumb_key, e)
                else:
                    logger.info("thumbnail not generated: generate_thumbnail returned None (invalid image or PIL error)")
        # Return path without bucket_prefix for storage (prefix is in S3 config; display URL = config.url + prefix + path)
        prefix = getattr(s3, "bucket_prefix", None) or ""
        if prefix and full_path and full_path.startswith(prefix):
            path_for_storage = full_path[len(prefix) :].lstrip("/") or full_path
        else:
            path_for_storage = full_path
        uploads_result.append({
            "s3_key": path_for_storage,
            "path": path_for_storage,
            "original_key": result.get("original_key"),
            "bucket": result.get("bucket"),
            "public_url": result.get("public_url"),
            "is_public": result.get("is_public", is_public_bool),
            "filename": filename or None,
        })

    if len(uploads_result) == 1:
        out = uploads_result[0].copy()
        out["success"] = True
        for k in ("filename",):
            out.pop(k, None)
        return out
    return {
        "success": True,
        "uploads": uploads_result,
        "count": len(uploads_result),
    }


@router.get("/private-file")
async def get_private_file(
    path: str = Query(..., description="S3 storage path (e.g. private/model-attachments/model_name/uuid.ext)"),
    redirect: bool = Query(True, description="If True, redirect to signed URL; if False, return JSON with url"),
    decrypt: bool = Query(False, description="If True, stream decrypted file content instead of signed URL (requires model_name, field_name)"),
    model_name: Optional[str] = Query(None, description="Model name (required when decrypt=true)"),
    field_name: Optional[str] = Query(None, description="Field name (required when decrypt=true)"),
    authorization: Optional[str] = Header(None),
):
    """
    Access a private file by path. Requires Bearer auth (JWT or PAT).
    - redirect=true (default): redirect to presigned S3 URL.
    - redirect=false: return JSON { "url": "<presigned_url>" }.
    - decrypt=true: require model_name and field_name; fetch file from S3, decrypt content (for encrypted file/image fields), and stream the decrypted file. No redirect.
    """
    user = await _require_user(authorization)
    company_id = _get_company_id_for_s3(user)
    s3 = await _get_default_s3_service(company_id)

    path = (path or "").strip().lstrip("/")
    if not path:
        raise HTTPException(status_code=400, detail="path is required")

    if decrypt:
        if not model_name or not _is_safe_identifier(model_name) or not field_name or not _is_safe_identifier(field_name):
            raise HTTPException(
                status_code=400,
                detail="When decrypt=true, model_name and field_name are required",
            )
        _, _, encryption_method = await _get_field_config_and_type(model_name, field_name)
        method = (encryption_method or "none").strip().lower()

        stream, metadata = s3.get_file_stream(path)
        if stream is None:
            raise HTTPException(status_code=404, detail="File not found or inaccessible")
        try:
            raw_bytes = stream.read()
        finally:
            try:
                stream.close()
            except Exception:
                pass

        if method in ("xor_cipher", "aes"):
            from utils.field_encryption import decrypt_file_content
            decrypted = decrypt_file_content(method, raw_bytes)
            if decrypted is None:
                raise HTTPException(status_code=500, detail="Decryption failed")
            raw_bytes = decrypted

        content_type = (metadata.get("content_type") or "application/octet-stream") if isinstance(metadata, dict) else "application/octet-stream"
        return StreamingResponse(
            BytesIO(raw_bytes),
            media_type=content_type,
            headers={"Content-Disposition": f'inline; filename="{os.path.basename(path)}"'},
        )

    # Signed URL (redirect or JSON)
    presigned_url = s3.generate_presigned_url(path)
    if not presigned_url:
        raise HTTPException(status_code=500, detail="Could not generate signed URL")

    if redirect:
        return RedirectResponse(url=presigned_url)
    return {"url": presigned_url}
