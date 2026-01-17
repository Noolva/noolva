"""
Settings Routes
Stores and retrieves UI/tenant settings from public.settings
"""

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from typing import Any, Dict, Optional
from middlewares.auth import verify_jwt_token
from utils.db import get_db
import json

router = APIRouter(prefix="/settings", tags=["Settings"])


class UpdateSettingsRequest(BaseModel):
    settings: Dict[str, Any]
    scope: str = "global"  # 'global' or 'tenant' (future)
    tenant_id: Optional[int] = None  # used when scope='tenant'


async def _get_field_type_ids(db) -> Dict[str, int]:
    rows = await db.fetch(
        "SELECT type_code, field_type_id FROM public.field_types WHERE type_code IN ('text','color','number','boolean')"
    )
    return {r["type_code"]: r["field_type_id"] for r in rows}


def _infer_field_type_code(value: Any) -> str:
    if isinstance(value, bool):
        return "boolean"
    if isinstance(value, (int, float)):
        return "number"
    # Hex colors like #RRGGBB
    if isinstance(value, str) and value.strip().startswith("#") and len(value.strip()) in (4, 7, 9):
        return "color"
    return "text"


@router.get("/definitions")
async def get_settings_definitions(
    scope: str = Query("global", description="global or tenant"),
    tenant_id: Optional[int] = Query(None, description="tenant_id when scope=tenant"),
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"])),
    db=Depends(get_db),
):
    """
    Returns settings with metadata for dynamic UI:
    group_name, setting_key, field_type_code, field_config_json, value/default_value.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    where = ["s.scope = $1"]
    args = [scope]
    if scope == "tenant":
        if tenant_id is None:
            raise HTTPException(status_code=400, detail="tenant_id is required when scope=tenant")
        where.append("s.tenant_id = $2")
        args.append(tenant_id)
    else:
        where.append("s.tenant_id IS NULL")

    query = f"""
        SELECT
            s.setting_id,
            s.group_name,
            s.setting_key,
            s.setting_name,
            s.description,
            s.field_type_id,
            ft.type_code AS field_type_code,
            COALESCE(s.field_config_json, '{{}}'::jsonb) AS field_config_json,
            s.default_value,
            s.value
        FROM public.settings s
        LEFT JOIN public.field_types ft ON ft.field_type_id = s.field_type_id
        WHERE {' AND '.join(where)}
        ORDER BY s.group_name, s.setting_name
    """

    rows = await db.fetch(query, *args)
    for r in rows:
        if r.get("value") is None:
            r["value"] = r.get("default_value")
    return {"settings": rows, "scope": scope, "tenant_id": tenant_id}


@router.get("")
async def get_settings(
    keys: Optional[str] = Query(None, description="Comma-separated setting keys"),
    scope: str = Query("global", description="global or tenant"),
    tenant_id: Optional[int] = Query(None, description="tenant_id when scope=tenant"),
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"])),
    db=Depends(get_db),
):
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    keys_list = [k.strip() for k in (keys or "").split(",") if k.strip()]

    where = ["scope = $1"]
    args = [scope]
    if scope == "tenant":
        if tenant_id is None:
            raise HTTPException(status_code=400, detail="tenant_id is required when scope=tenant")
        where.append("tenant_id = $2")
        args.append(tenant_id)
    else:
        where.append("tenant_id IS NULL")

    if keys_list:
        where.append(f"setting_key = ANY(${len(args) + 1})")
        args.append(keys_list)

    query = f"""
        SELECT setting_key, value, default_value
        FROM public.settings
        WHERE {' AND '.join(where)}
    """
    rows = await db.fetch(query, *args)

    settings: Dict[str, Any] = {}
    for r in rows:
        # Prefer value; fallback to default_value
        raw_value = r["value"] if r["value"] is not None else r["default_value"]
        
        # If value is a string (double-encoded JSON), parse it
        # Otherwise return as-is (already decoded JSONB)
        if isinstance(raw_value, str):
            try:
                parsed_value = json.loads(raw_value)
                # If parsed value is still a string (nested encoding), parse again
                if isinstance(parsed_value, str):
                    try:
                        settings[r["setting_key"]] = json.loads(parsed_value)
                    except (json.JSONDecodeError, TypeError):
                        settings[r["setting_key"]] = parsed_value
                else:
                    settings[r["setting_key"]] = parsed_value
            except (json.JSONDecodeError, TypeError):
                settings[r["setting_key"]] = raw_value
        else:
            settings[r["setting_key"]] = raw_value

    return {"settings": settings, "scope": scope, "tenant_id": tenant_id}


@router.put("")
async def update_settings(
    payload: UpdateSettingsRequest,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "tenant_admin"])),
    db=Depends(get_db),
):
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    if payload.scope not in ("global", "tenant"):
        raise HTTPException(status_code=400, detail="scope must be 'global' or 'tenant'")

    if payload.scope == "tenant" and payload.tenant_id is None:
        raise HTTPException(status_code=400, detail="tenant_id is required when scope=tenant")

    field_type_ids = await _get_field_type_ids(db)

    updated = []
    for key, value in (payload.settings or {}).items():
        tenant_id = payload.tenant_id if payload.scope == "tenant" else None
        # asyncpg requires JSON string for ::jsonb casting
        # Convert value to JSON string, then cast to JSONB
        # For simple types (str, int, float, bool), json.dumps() will produce correct JSON
        value_json_str = json.dumps(value)

        status = await db.execute(
            """
            UPDATE public.settings
            SET value = $1::jsonb,
                last_updated = CURRENT_TIMESTAMP
            WHERE setting_key = $2
              AND scope = $3
              AND (tenant_id IS NOT DISTINCT FROM $4)
            """,
            value_json_str,
            key,
            payload.scope,
            tenant_id,
        )

        # If row doesn't exist, create it (best-effort).
        if status.endswith("0"):
            inferred = _infer_field_type_code(value)
            ft_id = field_type_ids.get(inferred) or field_type_ids.get("text")
            setting_name = key.replace("_", " ").title()

            await db.execute(
                """
                INSERT INTO public.settings (
                    group_name, setting_key, setting_name, description,
                    field_type_id, default_value, value, scope, tenant_id, is_built_in
                )
                VALUES (
                    $1, $2, $3, $4,
                    $5, $6::jsonb, $7::jsonb, $8, $9, FALSE
                )
                ON CONFLICT (setting_key, tenant_id)
                DO UPDATE SET value = EXCLUDED.value, last_updated = CURRENT_TIMESTAMP
                """,
                "Theme",
                key,
                setting_name,
                f"Auto-created setting for {key}",
                ft_id,
                value_json_str,  # Default value as JSON string
                value_json_str,  # Actual value as JSON string
                payload.scope,
                tenant_id,
            )

        updated.append(key)

    return {"message": "Settings updated", "updated_keys": updated, "scope": payload.scope, "tenant_id": payload.tenant_id}

