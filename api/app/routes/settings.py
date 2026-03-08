"""
Settings Routes
Stores and retrieves UI/tenant settings from public.settings
"""

import logging
from fastapi import APIRouter, Depends, Header, HTTPException, Query
from pydantic import BaseModel
from typing import Any, Dict, Optional
from middlewares.auth import verify_jwt_token, resolve_bearer_to_user, PAT_PREFIX
from utils.db import get_db
import json

logger = logging.getLogger("noolva_api")

ALLOWED_USER_TYPES = ["saas_admin", "saas_employee", "tenant_admin", "tenant_user"]


# Optional PAT scopes required for settings (if PAT has scopes set, must include one of these)
SETTINGS_PAT_SCOPES = ("settings", "user_settings", "*")


async def verify_jwt_or_pat(authorization: Optional[str] = Header(None, alias="Authorization")) -> Optional[Dict]:
    """Resolve Bearer to user via JWT or PAT; require one of ALLOWED_USER_TYPES. Used for endpoints that accept PAT (e.g. update user-scoped settings)."""
    if not authorization or not str(authorization).strip():
        logger.info("PUT /settings 401: Authorization header missing or empty")
        raise HTTPException(
            status_code=401,
            detail="Missing Authorization header. Use: Authorization: Bearer <your-jwt-or-pat>",
        )
    raw_token = (authorization.split(" ", 1)[1].strip() if authorization.strip().startswith("Bearer ") else "") or ""
    token_hint = f"prefix={raw_token[:12]}..." if len(raw_token) > 12 else "(short)"
    user = await resolve_bearer_to_user(authorization)
    if not user:
        logger.info("PUT /settings 401: token rejected (invalid/expired/wrong). Token %s", token_hint)
        raise HTTPException(
            status_code=401,
            detail="Invalid or expired token. Use a valid JWT or PAT (PAT must start with nvpat_).",
        )
    if user.get("user_type") not in ALLOWED_USER_TYPES:
        raise HTTPException(status_code=403, detail="Access denied")
    # When auth is via PAT and PAT has scopes, require settings scope
    pat_scopes = user.get("pat_scopes")
    if isinstance(pat_scopes, list) and len(pat_scopes) > 0:
        if not any(s in SETTINGS_PAT_SCOPES for s in (pat_scopes or [])):
            raise HTTPException(
                status_code=403,
                detail="PAT does not have permission for settings. Required scope: settings, user_settings, or *.",
            )
    return user

router = APIRouter(prefix="/settings", tags=["Settings"])


@router.get("/row-exposure-modes")
async def get_row_exposure_modes(db=Depends(get_db)):
    """Return exposure modes for dropdowns (e.g. Current User Mode setting)."""
    rows = await db.fetch(
        "SELECT exposure_mode_id, name, description, expose_data FROM public.row_exposure_modes ORDER BY exposure_mode_id"
    )
    return {
        "options": [
            {"label": r["name"] or f"Mode {r['exposure_mode_id']}", "value": r["exposure_mode_id"]}
            for r in (rows or [])
        ],
        "modes": [dict(r) for r in (rows or [])],
    }


# Keys that any user can set for themselves (stored per user_uuid)
USER_SCOPED_SETTING_KEYS = {"current_user_mode"}


class UpdateSettingsRequest(BaseModel):
    settings: Dict[str, Any]
    scope: str = "global"  # 'global', 'tenant', or 'user' (per-user value)
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

    # Definitions: template rows only (user_uuid IS NULL)
    where = ["s.scope = $1", "s.user_uuid IS NULL"]
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
            ft.default_props_json AS default_props_json,
            s.default_value,
            s.value
        FROM public.settings s
        LEFT JOIN public.field_types ft ON ft.field_type_id = s.field_type_id
        WHERE {' AND '.join(where)}
        ORDER BY s.group_name, s.setting_name
    """
    rows = await db.fetch(query, *args)

    # Resolve effective value per setting: user-specific override or global default
    user_uuid = user.get("user_uuid") if user else None
    if user_uuid:
        for r in rows:
            eff = await db.fetchrow(
                """
                SELECT value FROM public.settings
                WHERE setting_key = $1 AND (tenant_id IS NOT DISTINCT FROM $2)
                  AND (user_uuid = $3 OR user_uuid IS NULL)
                ORDER BY user_uuid DESC NULLS LAST
                LIMIT 1
                """,
                r["setting_key"],
                tenant_id if scope == "tenant" else None,
                user_uuid,
            )
            if eff and eff.get("value") is not None:
                r["value"] = eff["value"]
    for r in rows:
        if r.get("value") is None:
            r["value"] = r.get("default_value")
    return {"settings": rows, "scope": scope, "tenant_id": tenant_id}


@router.get("")
async def get_settings(
    keys: Optional[str] = Query(None, description="Comma-separated setting keys"),
    scope: str = Query("global", description="global or tenant"),
    tenant_id: Optional[int] = Query(None, description="tenant_id when scope=tenant"),
    user: Dict = Depends(verify_jwt_or_pat),
    db=Depends(get_db),
):
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    keys_list = [k.strip() for k in (keys or "").split(",") if k.strip()]

    # User-scoped settings are stored as scope='global' + user_uuid (override) or user_uuid NULL (template)
    query_scope = "global" if scope == "user" else scope
    where = ["scope = $1"]
    args = [query_scope]
    if scope == "tenant":
        if tenant_id is None:
            raise HTTPException(status_code=400, detail="tenant_id is required when scope=tenant")
        where.append("tenant_id = $2")
        args.append(tenant_id)
    else:
        where.append("tenant_id IS NULL")

    # Prefer user-specific value over global (user_uuid NULL). For scope=user we query scope='global' (user overrides live there).
    user_uuid = user.get("user_uuid") if user else None
    if user_uuid:
        tenant_arg = tenant_id if scope == "tenant" else None
        args_with_user = [query_scope, tenant_arg, user_uuid]
        key_filter = "AND setting_key = ANY($4)" if keys_list else ""
        if keys_list:
            args_with_user.append(keys_list)
        query = f"""
            SELECT DISTINCT ON (setting_key) setting_key, value, default_value
            FROM public.settings
            WHERE scope = $1 AND (tenant_id IS NOT DISTINCT FROM $2)
              AND (user_uuid = $3 OR user_uuid IS NULL)
              {key_filter}
            ORDER BY setting_key, user_uuid DESC NULLS LAST
        """
        rows = await db.fetch(query, *args_with_user)
    else:
        where.append("user_uuid IS NULL")
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
    user: Dict = Depends(verify_jwt_or_pat),
    db=Depends(get_db),
):
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    if payload.scope not in ("global", "tenant", "user"):
        raise HTTPException(status_code=400, detail="scope must be 'global', 'tenant', or 'user'")

    if payload.scope == "tenant" and payload.tenant_id is None:
        raise HTTPException(status_code=400, detail="tenant_id is required when scope=tenant")

    # scope=user: only tenant_user and above; only keys in USER_SCOPED_SETTING_KEYS
    if payload.scope == "user":
        for key in (payload.settings or {}).keys():
            if key not in USER_SCOPED_SETTING_KEYS:
                raise HTTPException(status_code=403, detail=f"User-scoped updates allowed only for: {USER_SCOPED_SETTING_KEYS}")
    elif payload.scope in ("global", "tenant"):
        # global/tenant: only saas_admin or tenant_admin
        if user.get("user_type") not in ("saas_admin", "tenant_admin", "saas_employee"):
            raise HTTPException(status_code=403, detail="Only admins can update global/tenant settings")

    field_type_ids = await _get_field_type_ids(db)
    tenant_id = payload.tenant_id if payload.scope == "tenant" else None
    user_uuid = user.get("user_uuid") if payload.scope == "user" else None

    updated = []
    for key, value in (payload.settings or {}).items():
        value_json_str = json.dumps(value)

        if payload.scope == "user" and user_uuid:
            # Upsert user-specific row: update if exists, else insert (template from global row)
            def_row = await db.fetchrow(
                """
                SELECT group_name, setting_name, description, field_type_id, default_value
                FROM public.settings
                WHERE setting_key = $1 AND tenant_id IS NULL AND user_uuid IS NULL
                LIMIT 1
                """,
                key,
            )
            if not def_row:
                raise HTTPException(status_code=400, detail=f"Unknown user setting: {key}")
            nr = await db.execute(
                """
                UPDATE public.settings
                SET value = $1::jsonb, last_updated = CURRENT_TIMESTAMP
                WHERE setting_key = $2 AND tenant_id IS NULL AND user_uuid = $3
                """,
                value_json_str,
                key,
                user_uuid,
            )
            if nr and nr.endswith("0"):
                await db.execute(
                    """
                    INSERT INTO public.settings (
                        group_name, setting_key, setting_name, description,
                        field_type_id, default_value, value, scope, tenant_id, user_uuid, is_built_in
                    )
                    VALUES ($1, $2, $3, $4, $5, $6::jsonb, $7::jsonb, 'global', NULL, $8, TRUE)
                    """,
                    def_row["group_name"],
                    key,
                    def_row["setting_name"],
                    def_row["description"] or "",
                    def_row["field_type_id"],
                    def_row["default_value"],
                    value_json_str,
                    user_uuid,
                )
            updated.append(key)
            continue

        status = await db.execute(
            """
            UPDATE public.settings
            SET value = $1::jsonb,
                last_updated = CURRENT_TIMESTAMP
            WHERE setting_key = $2
              AND scope = $3
              AND (tenant_id IS NOT DISTINCT FROM $4)
              AND user_uuid IS NULL
            """,
            value_json_str,
            key,
            payload.scope,
            tenant_id,
        )

        if status.endswith("0"):
            inferred = _infer_field_type_code(value)
            ft_id = field_type_ids.get(inferred) or field_type_ids.get("text")
            setting_name = key.replace("_", " ").title()
            await db.execute(
                """
                INSERT INTO public.settings (
                    group_name, setting_key, setting_name, description,
                    field_type_id, default_value, value, scope, tenant_id, user_uuid, is_built_in
                )
                VALUES ($1, $2, $3, $4, $5, $6::jsonb, $7::jsonb, $8, $9, NULL, FALSE)
                ON CONFLICT (setting_key, tenant_id) WHERE user_uuid IS NULL
                DO UPDATE SET value = EXCLUDED.value, last_updated = CURRENT_TIMESTAMP
                """,
                "Theme",
                key,
                setting_name,
                f"Auto-created setting for {key}",
                ft_id,
                value_json_str,
                value_json_str,
                payload.scope,
                tenant_id,
            )
        updated.append(key)

    return {"message": "Settings updated", "updated_keys": updated, "scope": payload.scope, "tenant_id": payload.tenant_id}

