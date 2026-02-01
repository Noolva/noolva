"""
Themes Routes
CRUD for themes table - global (user_id NULL) and user-scoped themes
"""

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from typing import Any, Dict, Optional, List
from middlewares.auth import verify_jwt_token
from utils.db import get_db
import json
import os

router = APIRouter(prefix="/themes", tags=["Themes"])

# APP_SCOPE: saas | tenant - controls which scope themes are shown/edited
APP_SCOPE = os.getenv("APP_SCOPE", "saas")


class ThemeCreate(BaseModel):
    theme_name: str
    theme_key: str
    theme_json: Dict[str, Any]
    scope: str = "saas"
    tenant_id: Optional[int] = None
    apply_default_saas: Optional[bool] = False
    apply_default_tenant: Optional[bool] = False


class ThemeUpsertMine(BaseModel):
    theme_json: Dict[str, Any]


class ThemeUpdate(BaseModel):
    theme_name: Optional[str] = None
    theme_json: Optional[Dict[str, Any]] = None
    is_default: Optional[bool] = None


@router.get("")
async def list_themes(
    scope: str = Query("saas", description="saas or tenant"),
    user_id: Optional[int] = Query(None, description="Filter by user_id, null=global"),
    tenant_id: Optional[int] = Query(None, description="For tenant scope"),
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"])),
    db=Depends(get_db),
):
    """List themes for scope. user_id=None returns global themes."""
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    where = ["t.scope = $1"]
    args = [scope]
    if user_id is not None:
        where.append("t.user_id = $2")
        args.append(user_id)
    else:
        where.append("t.user_id IS NULL")

    if scope == "tenant" and tenant_id:
        where.append("(t.tenant_id IS NULL OR t.tenant_id = $3)")
        args.append(tenant_id)

    query = f"""
        SELECT theme_id, theme_uuid, theme_name, theme_key, theme_json,
               user_id, scope, tenant_id, is_builtin, is_default,
               created_at, last_updated
        FROM public.themes t
        WHERE {' AND '.join(where)}
        ORDER BY t.is_default DESC, t.theme_name
    """
    rows = await db.fetch(query, *args)
    return {"themes": [dict(r) for r in rows], "scope": scope}


@router.get("/active")
async def get_active_theme(
    scope: str = Query("saas", description="saas or tenant"),
    user_id: Optional[int] = Query(None, description="User for My Account theme"),
    tenant_id: Optional[int] = Query(None, description="For tenant scope"),
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"])),
    db=Depends(get_db),
):
    """
    Get active theme: user-scoped if user_id provided, else default global.
    Merges with settings (default_saas_theme, default_tenant_theme) for theme key.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    # If user_id provided, try user's theme first
    if user_id:
        row = await db.fetchrow(
            """
            SELECT theme_id, theme_uuid, theme_name, theme_key, theme_json
            FROM public.themes
            WHERE scope = $1 AND user_id = $2
            ORDER BY is_default DESC
            LIMIT 1
            """,
            scope,
            user_id,
        )
        if row:
            return {"theme": dict(row), "source": "user"}

    # Fallback: default global theme
    default_key = "default"
    if scope == "saas":
        s = await db.fetchrow(
            "SELECT value FROM public.settings WHERE setting_key = 'default_saas_theme' AND tenant_id IS NULL"
        )
    else:
        s = await db.fetchrow(
            "SELECT value FROM public.settings WHERE setting_key = 'default_tenant_theme' AND tenant_id IS NULL"
        )
    if s and s.get("value"):
        try:
            v = s["value"]
            if isinstance(v, str):
                v = json.loads(v) if v.startswith('"') else v
            default_key = v.strip('"') if isinstance(v, str) else str(v)
        except Exception:
            pass

    row = await db.fetchrow(
        """
        SELECT theme_id, theme_uuid, theme_name, theme_key, theme_json
        FROM public.themes
        WHERE scope = $1 AND user_id IS NULL AND (theme_key = $2 OR is_default = TRUE)
        ORDER BY (theme_key = $2) DESC, is_default DESC
        LIMIT 1
        """,
        scope,
        default_key,
    )
    if row:
        return {"theme": dict(row), "source": "global"}
    raise HTTPException(status_code=404, detail="No theme found")


@router.get("/{theme_id}")
async def get_theme(
    theme_id: int,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"])),
    db=Depends(get_db),
):
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    row = await db.fetchrow("SELECT * FROM public.themes WHERE theme_id = $1", theme_id)
    if not row:
        raise HTTPException(status_code=404, detail="Theme not found")
    return dict(row)


@router.post("")
async def create_theme(
    payload: ThemeCreate,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "tenant_admin"])),
    db=Depends(get_db),
):
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    if payload.scope not in ("saas", "tenant"):
        raise HTTPException(status_code=400, detail="scope must be saas or tenant")

    theme_json_str = json.dumps(payload.theme_json)
    user_id_val = user.get("user_id") if payload.theme_key.startswith("custom_") else None

    row = await db.fetchrow(
        """
        INSERT INTO public.themes (theme_name, theme_key, theme_json, user_id, scope, tenant_id, is_builtin, is_default, created_by)
        VALUES ($1, $2, $3::jsonb, $4, $5, $6, FALSE, FALSE, $7)
        RETURNING theme_id, theme_uuid, theme_name, theme_key, theme_json, user_id, scope, tenant_id, is_builtin, is_default, created_at, last_updated
        """,
        payload.theme_name,
        payload.theme_key,
        theme_json_str,
        user_id_val,
        payload.scope,
        payload.tenant_id,
        user.get("user_id"),
    )
    result = dict(row)

    # Apply as default for SAAS/Tenant if requested
    if payload.apply_default_saas and result.get("theme_key"):
        await db.execute(
            """
            UPDATE public.settings SET value = $1::jsonb, last_updated = CURRENT_TIMESTAMP
            WHERE setting_key = 'default_saas_theme' AND tenant_id IS NULL
            """,
            json.dumps(result["theme_key"]),
        )
    if payload.apply_default_tenant and result.get("theme_key"):
        await db.execute(
            """
            UPDATE public.settings SET value = $1::jsonb, last_updated = CURRENT_TIMESTAMP
            WHERE setting_key = 'default_tenant_theme' AND tenant_id IS NULL
            """,
            json.dumps(result["theme_key"]),
        )

    return result


@router.put("/mine")
async def upsert_my_theme(
    payload: ThemeUpsertMine,
    scope: str = Query("saas", description="saas or tenant"),
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"])),
    db=Depends(get_db),
):
    """Upsert current user's theme - one record per user. Create if none, update if exists."""
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    user_id = user.get("user_id")
    if not user_id:
        raise HTTPException(status_code=400, detail="User ID required")

    theme_json_str = json.dumps(payload.theme_json)

    # Check if user already has a theme
    existing = await db.fetchrow(
        "SELECT theme_id FROM public.themes WHERE scope = $1 AND user_id = $2 LIMIT 1",
        scope,
        user_id,
    )

    if existing:
        await db.execute(
            """
            UPDATE public.themes SET theme_json = $1::jsonb, last_updated = CURRENT_TIMESTAMP
            WHERE theme_id = $2
            """,
            theme_json_str,
            existing["theme_id"],
        )
        row = await db.fetchrow("SELECT * FROM public.themes WHERE theme_id = $1", existing["theme_id"])
    else:
        row = await db.fetchrow(
            """
            INSERT INTO public.themes (theme_name, theme_key, theme_json, user_id, scope, tenant_id, is_builtin, is_default, created_by)
            VALUES ($1, $2, $3::jsonb, $4, $5, NULL, FALSE, FALSE, $6)
            RETURNING theme_id, theme_uuid, theme_name, theme_key, theme_json, user_id, scope, tenant_id, is_builtin, is_default, created_at, last_updated
            """,
            "My Theme",
            "user_theme",
            theme_json_str,
            user_id,
            scope,
            user_id,
        )

    return dict(row)


@router.put("/{theme_id}")
async def update_theme(
    theme_id: int,
    payload: ThemeUpdate,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "tenant_admin"])),
    db=Depends(get_db),
):
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    updates = []
    args = []
    i = 1
    if payload.theme_name is not None:
        updates.append(f"theme_name = ${i}")
        args.append(payload.theme_name)
        i += 1
    if payload.theme_json is not None:
        updates.append(f"theme_json = ${i}::jsonb")
        args.append(json.dumps(payload.theme_json))
        i += 1
    if payload.is_default is not None:
        updates.append(f"is_default = ${i}")
        args.append(payload.is_default)
        i += 1

    if not updates:
        raise HTTPException(status_code=400, detail="No fields to update")

    updates.append("last_updated = CURRENT_TIMESTAMP")
    args.append(theme_id)

    result = await db.execute(
        f"""
        UPDATE public.themes
        SET {', '.join(updates)}
        WHERE theme_id = ${i}
        """,
        *args,
    )
    row = await db.fetchrow("SELECT * FROM public.themes WHERE theme_id = $1", theme_id)
    if not row:
        raise HTTPException(status_code=404, detail="Theme not found")
    return dict(row)


@router.delete("/{theme_id}")
async def delete_theme(
    theme_id: int,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "tenant_admin"])),
    db=Depends(get_db),
):
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    row = await db.fetchrow("SELECT is_builtin FROM public.themes WHERE theme_id = $1", theme_id)
    if not row:
        raise HTTPException(status_code=404, detail="Theme not found")
    if row["is_builtin"]:
        raise HTTPException(status_code=400, detail="Cannot delete built-in theme")
    await db.execute("DELETE FROM public.themes WHERE theme_id = $1", theme_id)
    return {"message": "Theme deleted"}
