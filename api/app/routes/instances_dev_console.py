"""
Developer Console — client instances (per-product shells) and offline sync configuration.
Operators define read datasets and explicit write-endpoint allowlists. See docs/client_offline_sync.md.
"""
from __future__ import annotations

import json
import logging
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from middlewares.auth import verify_jwt_token
from utils.db import get_db
from classes.postgres_db import PostgresDB
from utils.instance_offline import (
    ensure_instance_offline_settings_row,
    validate_dataset_row,
    validate_write_endpoint_for_instance,
)

logger = logging.getLogger("noolva_api.instances_dev_console")

# Paths are explicit (no router prefix) so collection routes register reliably under /api
# (nested APIRouter + @get("") often does not match GET /api/dev-console/instances).
router = APIRouter(tags=["Developer Console - Client instances"])

_DEV_ROLES = ["saas_admin", "saas_employee", "tenant_admin"]


class InstanceCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = None
    company_id: Optional[int] = None


class InstanceUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=200)
    description: Optional[str] = None
    company_id: Optional[int] = None
    is_active: Optional[bool] = None


class OfflineSettingsUpdate(BaseModel):
    enable_offline_data: Optional[bool] = None
    schema_pack_version: Optional[str] = Field(None, max_length=64)
    operator_notes: Optional[str] = None


class DatasetCreate(BaseModel):
    dataset_key: str = Field(..., min_length=1, max_length=120)
    label: Optional[str] = None
    source_kind: str
    model_id: Optional[int] = None
    flattening_policy_id: Optional[int] = None
    read_endpoint_id: Optional[int] = None
    incremental_field: Optional[str] = None
    batch_size: Optional[int] = None
    local_lifecycle_jsonb: Optional[Dict[str, Any]] = None
    is_active: bool = True


class DatasetUpdate(BaseModel):
    dataset_key: Optional[str] = Field(None, min_length=1, max_length=120)
    label: Optional[str] = None
    source_kind: Optional[str] = None
    model_id: Optional[int] = None
    flattening_policy_id: Optional[int] = None
    read_endpoint_id: Optional[int] = None
    incremental_field: Optional[str] = None
    batch_size: Optional[int] = None
    local_lifecycle_jsonb: Optional[Dict[str, Any]] = None
    is_active: Optional[bool] = None


class WriteEndpointCreate(BaseModel):
    endpoint_id: int
    notes: Optional[str] = None
    is_active: bool = True


@router.get("/dev-console/instances")
async def list_instances(
    user: Dict = Depends(verify_jwt_token(_DEV_ROLES)),
    db=Depends(get_db),
):
    rows = await PostgresDB.fetch(
        """
        SELECT i.instance_id, i.instance_uuid, i.name, i.description, i.company_id, i.is_active,
               i.idate, i.last_updated,
               s.enable_offline_data, s.schema_pack_version
        FROM public.instances i
        LEFT JOIN public.instance_offline_settings s ON s.instance_id = i.instance_id
        ORDER BY i.name
        """
    )
    return [dict(r) for r in (rows or [])]


@router.post("/dev-console/instances")
async def create_instance(
    body: InstanceCreate,
    user: Dict = Depends(verify_jwt_token(_DEV_ROLES)),
    db=Depends(get_db),
):
    name = body.name.strip()
    row = await PostgresDB.fetchrow(
        """
        INSERT INTO public.instances (name, description, company_id)
        VALUES ($1, $2, $3)
        RETURNING *
        """,
        name,
        (body.description or "").strip() or None,
        body.company_id,
    )
    if not row:
        raise HTTPException(status_code=500, detail="Failed to create instance")
    iid = int(row["instance_id"])
    await ensure_instance_offline_settings_row(iid)
    return dict(row)


@router.get("/dev-console/instances/helpers/auto-crud-write-endpoints")
async def helper_auto_crud_writes(
    q: Optional[str] = Query(None, description="Search path or model_name"),
    limit: int = Query(80, le=200),
    user: Dict = Depends(verify_jwt_token(_DEV_ROLES)),
    db=Depends(get_db),
):
    """List POST/PUT/PATCH/DELETE auto_crud endpoints for picker UI."""
    pat = f"%{(q or '').strip()}%" if (q or "").strip() else None
    rows = await PostgresDB.fetch(
        """
        SELECT ae.endpoint_id, ae.path, ae.method, ae.related_model_id, dm.model_name, dm.table_name
        FROM public.api_endpoints ae
        LEFT JOIN public.data_models dm ON dm.model_id = ae.related_model_id
        WHERE ae.type = 'auto_crud'
          AND UPPER(ae.method) IN ('POST','PUT','PATCH','DELETE')
          AND ($1::text IS NULL OR ae.path ILIKE $1 OR COALESCE(dm.model_name,'') ILIKE $1)
        ORDER BY dm.model_name NULLS LAST, ae.path
        LIMIT $2
        """,
        pat,
        limit,
    )
    return [dict(r) for r in (rows or [])]


@router.get("/dev-console/instances/helpers/flattening-s3-policies")
async def helper_flattening_s3(
    user: Dict = Depends(verify_jwt_token(_DEV_ROLES)),
    db=Depends(get_db),
):
    rows = await PostgresDB.fetch(
        """
        SELECT id, table_name, destination, is_public_on_s3, last_refreshed, last_processed_value, is_active
        FROM public.flattening_table_policy
        WHERE LOWER(TRIM(destination)) = 's3'
        ORDER BY table_name
        """
    )
    return [dict(r) for r in (rows or [])]


@router.get("/dev-console/instances/helpers/flattening-postgres-policies")
async def helper_flattening_postgres_policies(
    user: Dict = Depends(verify_jwt_token(_DEV_ROLES)),
    db=Depends(get_db),
):
    """Postgres-destination flattening policies with a data model + flattening read GET route (for offline WARM API)."""
    rows = await PostgresDB.fetch(
        """
        SELECT ftp.id AS flattening_policy_id,
               ftp.table_name,
               dm.model_id,
               dm.model_name,
               dm.display_name
        FROM public.flattening_table_policy ftp
        INNER JOIN public.data_models dm
          ON dm.table_name = ftp.table_name AND dm.is_active IS NOT FALSE
        WHERE LOWER(TRIM(ftp.destination)) = 'postgres'
          AND ftp.is_active IS NOT FALSE
          AND EXISTS (
            SELECT 1 FROM public.api_endpoints ae
            WHERE ae.related_model_id = dm.model_id
              AND ae.type = 'auto_crud'
              AND UPPER(TRIM(ae.method)) = 'GET'
              AND (
                ae.custom_json @> '{"flattening_read_only": true}'::jsonb
                OR LOWER(TRIM(COALESCE(ae.custom_json->>'flattening_read_only', ''))) IN ('true', '1', 'yes')
              )
          )
        ORDER BY ftp.table_name
        """
    )
    return [dict(r) for r in (rows or [])]


@router.get("/dev-console/instances/helpers/data-models")
async def helper_data_models(
    q: Optional[str] = Query(None),
    limit: int = Query(100, le=300),
    user: Dict = Depends(verify_jwt_token(_DEV_ROLES)),
    db=Depends(get_db),
):
    pat = f"%{(q or '').strip()}%" if (q or "").strip() else None
    rows = await PostgresDB.fetch(
        """
        SELECT model_id, model_name, table_name, display_name
        FROM public.data_models
        WHERE is_active IS NOT FALSE
          AND ($1::text IS NULL OR model_name ILIKE $1 OR table_name ILIKE $1 OR COALESCE(display_name,'') ILIKE $1)
        ORDER BY model_name
        LIMIT $2
        """,
        pat,
        limit,
    )
    return [dict(r) for r in (rows or [])]


@router.get("/dev-console/instances/helpers/flattening-read-endpoints")
async def helper_flattening_read_endpoints(
    model_id: Optional[int] = Query(None, description="Filter by data_models.model_id"),
    limit: int = Query(80, le=200),
    user: Dict = Depends(verify_jwt_token(_DEV_ROLES)),
    db=Depends(get_db),
):
    """GET auto_crud routes marked flattening_read_only (WARM read list/detail)."""
    rows = await PostgresDB.fetch(
        """
        SELECT ae.endpoint_id, ae.path, ae.method, ae.related_model_id,
               dm.model_name, dm.display_name, dm.table_name
        FROM public.api_endpoints ae
        LEFT JOIN public.data_models dm ON dm.model_id = ae.related_model_id
        WHERE ae.type = 'auto_crud'
          AND UPPER(TRIM(ae.method)) = 'GET'
          AND (
            ae.custom_json @> '{"flattening_read_only": true}'::jsonb
            OR LOWER(TRIM(COALESCE(ae.custom_json->>'flattening_read_only', ''))) IN ('true', '1', 'yes')
          )
          AND ($1::int IS NULL OR ae.related_model_id = $1)
        ORDER BY dm.model_name NULLS LAST, ae.path
        LIMIT $2
        """,
        model_id,
        limit,
    )
    return [dict(r) for r in (rows or [])]


@router.get("/dev-console/instances/{instance_id}")
async def get_instance(
    instance_id: int,
    user: Dict = Depends(verify_jwt_token(_DEV_ROLES)),
    db=Depends(get_db),
):
    row = await PostgresDB.fetchrow(
        """
        SELECT i.*, s.enable_offline_data, s.schema_pack_version, s.operator_notes, s.last_updated AS settings_updated
        FROM public.instances i
        LEFT JOIN public.instance_offline_settings s ON s.instance_id = i.instance_id
        WHERE i.instance_id = $1
        """,
        instance_id,
    )
    if not row:
        raise HTTPException(status_code=404, detail="Instance not found")
    await ensure_instance_offline_settings_row(instance_id)
    return dict(row)


@router.put("/dev-console/instances/{instance_id}")
async def update_instance(
    instance_id: int,
    body: InstanceUpdate,
    user: Dict = Depends(verify_jwt_token(_DEV_ROLES)),
    db=Depends(get_db),
):
    cur = await PostgresDB.fetchrow(
        "SELECT instance_id FROM public.instances WHERE instance_id = $1",
        instance_id,
    )
    if not cur:
        raise HTTPException(status_code=404, detail="Instance not found")
    updates = body.model_dump(exclude_unset=True)
    if not updates:
        return await get_instance(instance_id, user, db)
    sets = []
    args: List[Any] = []
    i = 1
    if "name" in updates:
        sets.append(f"name = ${i}")
        args.append(updates["name"].strip())
        i += 1
    if "description" in updates:
        sets.append(f"description = ${i}")
        args.append((updates["description"] or "").strip() or None)
        i += 1
    if "company_id" in updates:
        sets.append(f"company_id = ${i}")
        args.append(updates["company_id"])
        i += 1
    if "is_active" in updates:
        sets.append(f"is_active = ${i}")
        args.append(updates["is_active"])
        i += 1
    sets.append("last_updated = CURRENT_TIMESTAMP")
    args.append(instance_id)
    await PostgresDB.execute(
        f"UPDATE public.instances SET {', '.join(sets)} WHERE instance_id = ${i}",
        *args,
    )
    return await get_instance(instance_id, user, db)


@router.delete("/dev-console/instances/{instance_id}")
async def delete_instance(
    instance_id: int,
    user: Dict = Depends(verify_jwt_token(_DEV_ROLES)),
    db=Depends(get_db),
):
    r = await PostgresDB.execute(
        "DELETE FROM public.instances WHERE instance_id = $1",
        instance_id,
    )
    return {"ok": True, "deleted": instance_id}


@router.put("/dev-console/instances/{instance_id}/offline-settings")
async def update_offline_settings(
    instance_id: int,
    body: OfflineSettingsUpdate,
    user: Dict = Depends(verify_jwt_token(_DEV_ROLES)),
    db=Depends(get_db),
):
    inst = await PostgresDB.fetchrow(
        "SELECT instance_id FROM public.instances WHERE instance_id = $1",
        instance_id,
    )
    if not inst:
        raise HTTPException(status_code=404, detail="Instance not found")
    await ensure_instance_offline_settings_row(instance_id)
    u = body.model_dump(exclude_unset=True)
    if not u:
        row = await PostgresDB.fetchrow(
            "SELECT * FROM public.instance_offline_settings WHERE instance_id = $1",
            instance_id,
        )
        return dict(row) if row else {}
    sets = []
    args: List[Any] = []
    i = 1
    if "enable_offline_data" in u:
        sets.append(f"enable_offline_data = ${i}")
        args.append(u["enable_offline_data"])
        i += 1
    if "schema_pack_version" in u:
        sets.append(f"schema_pack_version = ${i}")
        args.append((u["schema_pack_version"] or "1").strip())
        i += 1
    if "operator_notes" in u:
        sets.append(f"operator_notes = ${i}")
        args.append(u["operator_notes"])
        i += 1
    sets.append("last_updated = CURRENT_TIMESTAMP")
    args.append(instance_id)
    await PostgresDB.execute(
        f"UPDATE public.instance_offline_settings SET {', '.join(sets)} WHERE instance_id = ${i}",
        *args,
    )
    row = await PostgresDB.fetchrow(
        "SELECT * FROM public.instance_offline_settings WHERE instance_id = $1",
        instance_id,
    )
    return dict(row) if row else {}


@router.get("/dev-console/instances/{instance_id}/datasets")
async def list_datasets(
    instance_id: int,
    user: Dict = Depends(verify_jwt_token(_DEV_ROLES)),
    db=Depends(get_db),
):
    inst = await PostgresDB.fetchrow(
        "SELECT instance_id FROM public.instances WHERE instance_id = $1",
        instance_id,
    )
    if not inst:
        raise HTTPException(status_code=404, detail="Instance not found")
    rows = await PostgresDB.fetch(
        "SELECT * FROM public.client_offline_dataset WHERE instance_id = $1 ORDER BY dataset_key",
        instance_id,
    )
    return [dict(r) for r in (rows or [])]


@router.post("/dev-console/instances/{instance_id}/datasets")
async def create_dataset(
    instance_id: int,
    body: DatasetCreate,
    user: Dict = Depends(verify_jwt_token(_DEV_ROLES)),
    db=Depends(get_db),
):
    inst = await PostgresDB.fetchrow(
        "SELECT instance_id FROM public.instances WHERE instance_id = $1",
        instance_id,
    )
    if not inst:
        raise HTTPException(status_code=404, detail="Instance not found")
    sk = body.source_kind.strip()
    ok, err = await validate_dataset_row(sk, body.model_id, body.flattening_policy_id, body.read_endpoint_id)
    if not ok:
        raise HTTPException(status_code=400, detail=err)
    dk = body.dataset_key.strip()
    dup = await PostgresDB.fetchrow(
        "SELECT id FROM public.client_offline_dataset WHERE instance_id = $1 AND dataset_key = $2",
        instance_id,
        dk,
    )
    if dup:
        raise HTTPException(status_code=400, detail="dataset_key already exists for this instance")
    lc = body.local_lifecycle_jsonb if body.local_lifecycle_jsonb is not None else {}
    row = await PostgresDB.fetchrow(
        """
        INSERT INTO public.client_offline_dataset (
            instance_id, dataset_key, label, source_kind, model_id, flattening_policy_id,
            read_endpoint_id, incremental_field, batch_size, local_lifecycle_jsonb, is_active
        )
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10::jsonb,$11)
        RETURNING *
        """,
        instance_id,
        dk,
        (body.label or "").strip() or None,
        sk,
        body.model_id,
        body.flattening_policy_id,
        body.read_endpoint_id,
        (body.incremental_field or "").strip() or None,
        body.batch_size,
        json.dumps(lc),
        body.is_active,
    )
    return dict(row) if row else {}


@router.put("/dev-console/instances/{instance_id}/datasets/{dataset_id}")
async def update_dataset(
    instance_id: int,
    dataset_id: int,
    body: DatasetUpdate,
    user: Dict = Depends(verify_jwt_token(_DEV_ROLES)),
    db=Depends(get_db),
):
    cur = await PostgresDB.fetchrow(
        "SELECT * FROM public.client_offline_dataset WHERE id = $1 AND instance_id = $2",
        dataset_id,
        instance_id,
    )
    if not cur:
        raise HTTPException(status_code=404, detail="Dataset not found")
    u = body.model_dump(exclude_unset=True)
    merged = {**dict(cur), **u}
    dk = (merged.get("dataset_key") or "").strip()
    sk = (merged.get("source_kind") or "").strip()
    ok, err = await validate_dataset_row(
        sk,
        merged.get("model_id"),
        merged.get("flattening_policy_id"),
        merged.get("read_endpoint_id"),
    )
    if not ok:
        raise HTTPException(status_code=400, detail=err)
    dup = await PostgresDB.fetchrow(
        """
        SELECT id FROM public.client_offline_dataset
        WHERE instance_id = $1 AND dataset_key = $2 AND id <> $3
        """,
        instance_id,
        dk,
        dataset_id,
    )
    if dup:
        raise HTTPException(status_code=400, detail="dataset_key already exists")
    lc = merged.get("local_lifecycle_jsonb")
    lc_json = json.dumps(lc if isinstance(lc, dict) else _safe(lc))
    await PostgresDB.execute(
        """
        UPDATE public.client_offline_dataset SET
            dataset_key = $1,
            label = $2,
            source_kind = $3,
            model_id = $4,
            flattening_policy_id = $5,
            read_endpoint_id = $6,
            incremental_field = $7,
            batch_size = $8,
            local_lifecycle_jsonb = $9::jsonb,
            is_active = $10,
            last_updated = CURRENT_TIMESTAMP
        WHERE id = $11 AND instance_id = $12
        """,
        dk,
        merged.get("label"),
        sk,
        merged.get("model_id"),
        merged.get("flattening_policy_id"),
        merged.get("read_endpoint_id"),
        merged.get("incremental_field"),
        merged.get("batch_size"),
        lc_json,
        merged.get("is_active"),
        dataset_id,
        instance_id,
    )
    row = await PostgresDB.fetchrow(
        "SELECT * FROM public.client_offline_dataset WHERE id = $1",
        dataset_id,
    )
    return dict(row) if row else {}


def _safe(obj):
    if isinstance(obj, dict):
        return obj
    if obj is None:
        return {}
    try:
        return json.loads(obj) if isinstance(obj, str) and obj.strip() else {}
    except Exception:
        return {}


@router.delete("/dev-console/instances/{instance_id}/datasets/{dataset_id}")
async def delete_dataset(
    instance_id: int,
    dataset_id: int,
    user: Dict = Depends(verify_jwt_token(_DEV_ROLES)),
    db=Depends(get_db),
):
    await PostgresDB.execute(
        "DELETE FROM public.client_offline_dataset WHERE id = $1 AND instance_id = $2",
        dataset_id,
        instance_id,
    )
    return {"ok": True}


@router.get("/dev-console/instances/{instance_id}/write-endpoints")
async def list_write_endpoints(
    instance_id: int,
    user: Dict = Depends(verify_jwt_token(_DEV_ROLES)),
    db=Depends(get_db),
):
    inst = await PostgresDB.fetchrow(
        "SELECT instance_id FROM public.instances WHERE instance_id = $1",
        instance_id,
    )
    if not inst:
        raise HTTPException(status_code=404, detail="Instance not found")
    rows = await PostgresDB.fetch(
        """
        SELECT w.*, ae.path, ae.method, ae.related_model_id, dm.model_name
        FROM public.client_offline_write_endpoint w
        JOIN public.api_endpoints ae ON ae.endpoint_id = w.endpoint_id
        LEFT JOIN public.data_models dm ON dm.model_id = ae.related_model_id
        WHERE w.instance_id = $1
        ORDER BY ae.path, ae.method
        """,
        instance_id,
    )
    return [dict(r) for r in (rows or [])]


@router.post("/dev-console/instances/{instance_id}/write-endpoints")
async def create_write_endpoint(
    instance_id: int,
    body: WriteEndpointCreate,
    user: Dict = Depends(verify_jwt_token(_DEV_ROLES)),
    db=Depends(get_db),
):
    inst = await PostgresDB.fetchrow(
        "SELECT instance_id FROM public.instances WHERE instance_id = $1",
        instance_id,
    )
    if not inst:
        raise HTTPException(status_code=404, detail="Instance not found")
    ok, err = await validate_write_endpoint_for_instance(body.endpoint_id)
    if not ok:
        raise HTTPException(status_code=400, detail=err)
    try:
        row = await PostgresDB.fetchrow(
            """
            INSERT INTO public.client_offline_write_endpoint (instance_id, endpoint_id, notes, is_active)
            VALUES ($1, $2, $3, $4)
            RETURNING *
            """,
            instance_id,
            body.endpoint_id,
            body.notes,
            body.is_active,
        )
    except Exception as e:
        if "unique" in str(e).lower():
            raise HTTPException(status_code=400, detail="endpoint already allowlisted for this instance") from e
        raise
    return dict(row) if row else {}


@router.delete("/dev-console/instances/{instance_id}/write-endpoints/{row_id}")
async def delete_write_endpoint(
    instance_id: int,
    row_id: int,
    user: Dict = Depends(verify_jwt_token(_DEV_ROLES)),
    db=Depends(get_db),
):
    await PostgresDB.execute(
        "DELETE FROM public.client_offline_write_endpoint WHERE id = $1 AND instance_id = $2",
        row_id,
        instance_id,
    )
    return {"ok": True}


_CLIENT_TYPES = frozenset({"web", "android", "ios", "macos", "linux"})
_RENDER_MODES = frozenset({"web", "native", "webview"})


def _auth_user_id(user: Dict) -> Optional[int]:
    if not user:
        return None
    uid = user.get("user_id")
    if uid is None:
        return None
    try:
        return int(uid)
    except (TypeError, ValueError):
        return None


class ClientMenuConfigItem(BaseModel):
    client_type: str
    render_mode: str
    is_enabled: bool = True


class InstanceMenuCreate(BaseModel):
    menu_title: str = Field(..., min_length=1, max_length=500)
    route_path: Optional[str] = Field(None, max_length=1000)
    is_builtin: bool = False
    icon_key: Optional[str] = Field(None, max_length=120)
    parent_id: Optional[int] = None
    sort_order: int = 0
    client_configs: Optional[List[ClientMenuConfigItem]] = None


class InstanceMenuUpdate(BaseModel):
    menu_title: Optional[str] = Field(None, min_length=1, max_length=500)
    route_path: Optional[str] = Field(None, max_length=1000)
    is_builtin: Optional[bool] = None
    icon_key: Optional[str] = Field(None, max_length=120)
    parent_id: Optional[int] = None
    sort_order: Optional[int] = None


class InstanceMenuClientConfigsBody(BaseModel):
    configs: List[ClientMenuConfigItem]


async def _get_instance_or_404(instance_id: int) -> None:
    row = await PostgresDB.fetchrow(
        "SELECT instance_id FROM public.instances WHERE instance_id = $1",
        instance_id,
    )
    if not row:
        raise HTTPException(status_code=404, detail="Instance not found")


async def _validate_menu_parent(instance_id: int, parent_id: Optional[int], exclude_menu_id: Optional[int] = None):
    if parent_id is None:
        return
    q = await PostgresDB.fetchrow(
        """
        SELECT id FROM public.instance_menus
        WHERE id = $1 AND instance_id = $2
        """,
        parent_id,
        instance_id,
    )
    if not q:
        raise HTTPException(status_code=400, detail="parent_id is not a menu for this instance")
    if exclude_menu_id is not None and parent_id == exclude_menu_id:
        raise HTTPException(status_code=400, detail="Menu cannot be its own parent")


def _normalize_client_configs(items: Optional[List[ClientMenuConfigItem]]) -> List[ClientMenuConfigItem]:
    if not items:
        return []
    seen = set()
    out: List[ClientMenuConfigItem] = []
    for it in items:
        ct = (it.client_type or "").strip().lower()
        rm = (it.render_mode or "").strip().lower()
        if ct not in _CLIENT_TYPES:
            raise HTTPException(status_code=400, detail=f"Invalid client_type: {it.client_type}")
        if rm not in _RENDER_MODES:
            raise HTTPException(status_code=400, detail=f"Invalid render_mode: {it.render_mode}")
        if ct in seen:
            raise HTTPException(status_code=400, detail=f"Duplicate client_type: {ct}")
        seen.add(ct)
        out.append(ClientMenuConfigItem(client_type=ct, render_mode=rm, is_enabled=bool(it.is_enabled)))
    return out


async def _upsert_menu_client_configs(menu_id: int, items: List[ClientMenuConfigItem], user_id: Optional[int]):
    for it in items:
        await PostgresDB.execute(
            """
            INSERT INTO public.instance_menu_client_config
                (instance_menu_id, client_type, render_mode, is_enabled, created_by)
            VALUES ($1, $2, $3, $4, $5)
            ON CONFLICT (instance_menu_id, client_type) DO UPDATE SET
                render_mode = EXCLUDED.render_mode,
                is_enabled = EXCLUDED.is_enabled,
                last_updated = CURRENT_TIMESTAMP
            """,
            menu_id,
            it.client_type,
            it.render_mode,
            it.is_enabled,
            user_id,
        )
    if items:
        # Flattening → S3 uses MAX(instance_menus.last_updated) as part of the upload signature.
        # Client-config edits only touch instance_menu_client_config; bump parent so refresh_flattening_table re-exports.
        await PostgresDB.execute(
            "UPDATE public.instance_menus SET last_updated = CURRENT_TIMESTAMP WHERE id = $1",
            menu_id,
        )


async def _fetch_menus_with_configs(instance_id: int) -> List[Dict[str, Any]]:
    menus = await PostgresDB.fetch(
        """
        SELECT id, instance_id, menu_title, route_path, is_builtin, icon_key, parent_id, sort_order,
               created_by, idate, last_updated
        FROM public.instance_menus
        WHERE instance_id = $1
        ORDER BY parent_id NULLS FIRST, sort_order, menu_title
        """,
        instance_id,
    )
    if not menus:
        return []
    ids = [int(m["id"]) for m in menus]
    cfgs = await PostgresDB.fetch(
        """
        SELECT id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated
        FROM public.instance_menu_client_config
        WHERE instance_menu_id = ANY($1::int[])
        ORDER BY client_type
        """,
        ids,
    )
    by_menu: Dict[int, List[Dict[str, Any]]] = {i: [] for i in ids}
    for c in cfgs or []:
        mid = int(c["instance_menu_id"])
        if mid in by_menu:
            by_menu[mid].append(dict(c))
    return [{**dict(m), "client_configs": by_menu[int(m["id"])]} for m in menus]


@router.get("/dev-console/instances/{instance_id}/instance-menus")
async def list_instance_menus(
    instance_id: int,
    user: Dict = Depends(verify_jwt_token(_DEV_ROLES)),
    db=Depends(get_db),
):
    await _get_instance_or_404(instance_id)
    return {"menus": await _fetch_menus_with_configs(instance_id)}


@router.post("/dev-console/instances/{instance_id}/instance-menus")
async def create_instance_menu(
    instance_id: int,
    body: InstanceMenuCreate,
    user: Dict = Depends(verify_jwt_token(_DEV_ROLES)),
    db=Depends(get_db),
):
    await _get_instance_or_404(instance_id)
    await _validate_menu_parent(instance_id, body.parent_id)
    uid = _auth_user_id(user)
    title = body.menu_title.strip()
    rp = (body.route_path or "").strip() or None
    ik = (body.icon_key or "").strip() or None
    try:
        row = await PostgresDB.fetchrow(
            """
            INSERT INTO public.instance_menus (
                instance_id, menu_title, route_path, is_builtin, icon_key, parent_id, sort_order, created_by
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            RETURNING id
            """,
            instance_id,
            title,
            rp,
            body.is_builtin,
            ik,
            body.parent_id,
            body.sort_order,
            uid,
        )
    except Exception as e:
        err = str(e).lower()
        if "unique" in err:
            raise HTTPException(status_code=400, detail="A menu with this title already exists at this level") from e
        raise
    if not row:
        raise HTTPException(status_code=500, detail="Failed to create menu")
    mid = int(row["id"])
    cfgs = _normalize_client_configs(body.client_configs)
    if cfgs:
        await _upsert_menu_client_configs(mid, cfgs, uid)
    menus = await _fetch_menus_with_configs(instance_id)
    created = next((m for m in menus if m["id"] == mid), None)
    return created or {"id": mid}


@router.put("/dev-console/instances/{instance_id}/instance-menus/{menu_id}")
async def update_instance_menu(
    instance_id: int,
    menu_id: int,
    body: InstanceMenuUpdate,
    user: Dict = Depends(verify_jwt_token(_DEV_ROLES)),
    db=Depends(get_db),
):
    await _get_instance_or_404(instance_id)
    cur = await PostgresDB.fetchrow(
        "SELECT * FROM public.instance_menus WHERE id = $1 AND instance_id = $2",
        menu_id,
        instance_id,
    )
    if not cur:
        raise HTTPException(status_code=404, detail="Menu not found")
    u = body.model_dump(exclude_unset=True)
    new_parent = u.get("parent_id", cur["parent_id"])
    if "parent_id" in u:
        await _validate_menu_parent(instance_id, new_parent, exclude_menu_id=menu_id)
        # avoid simple cycles: parent chain
        if new_parent is not None:
            walk = new_parent
            steps = 0
            while walk is not None and steps < 64:
                if walk == menu_id:
                    raise HTTPException(status_code=400, detail="Invalid parent: would create a cycle")
                pr = await PostgresDB.fetchrow(
                    "SELECT parent_id FROM public.instance_menus WHERE id = $1 AND instance_id = $2",
                    walk,
                    instance_id,
                )
                walk = int(pr["parent_id"]) if pr and pr["parent_id"] is not None else None
                steps += 1
    if not u:
        menus = await _fetch_menus_with_configs(instance_id)
        return next((m for m in menus if m["id"] == menu_id), dict(cur))

    sets: List[str] = []
    args: List[Any] = []
    i = 1
    if "menu_title" in u:
        sets.append(f"menu_title = ${i}")
        args.append(u["menu_title"].strip())
        i += 1
    if "route_path" in u:
        sets.append(f"route_path = ${i}")
        args.append((u["route_path"] or "").strip() or None)
        i += 1
    if "is_builtin" in u:
        sets.append(f"is_builtin = ${i}")
        args.append(u["is_builtin"])
        i += 1
    if "icon_key" in u:
        sets.append(f"icon_key = ${i}")
        args.append((u["icon_key"] or "").strip() or None)
        i += 1
    if "parent_id" in u:
        sets.append(f"parent_id = ${i}")
        args.append(u["parent_id"])
        i += 1
    if "sort_order" in u:
        sets.append(f"sort_order = ${i}")
        args.append(u["sort_order"])
        i += 1
    sets.append("last_updated = CURRENT_TIMESTAMP")
    where_menu = i
    where_inst = i + 1
    args.extend([menu_id, instance_id])
    try:
        await PostgresDB.execute(
            f"""
            UPDATE public.instance_menus SET {", ".join(sets)}
            WHERE id = ${where_menu} AND instance_id = ${where_inst}
            """,
            *args,
        )
    except Exception as e:
        if "unique" in str(e).lower():
            raise HTTPException(status_code=400, detail="A menu with this title already exists at this level") from e
        raise
    menus = await _fetch_menus_with_configs(instance_id)
    return next((m for m in menus if m["id"] == menu_id), {})


@router.put("/dev-console/instances/{instance_id}/instance-menus/{menu_id}/client-configs")
async def replace_instance_menu_client_configs(
    instance_id: int,
    menu_id: int,
    body: InstanceMenuClientConfigsBody,
    user: Dict = Depends(verify_jwt_token(_DEV_ROLES)),
    db=Depends(get_db),
):
    await _get_instance_or_404(instance_id)
    cur = await PostgresDB.fetchrow(
        "SELECT id FROM public.instance_menus WHERE id = $1 AND instance_id = $2",
        menu_id,
        instance_id,
    )
    if not cur:
        raise HTTPException(status_code=404, detail="Menu not found")
    cfgs = _normalize_client_configs(body.configs)
    uid = _auth_user_id(user)
    await _upsert_menu_client_configs(menu_id, cfgs, uid)
    menus = await _fetch_menus_with_configs(instance_id)
    return next((m for m in menus if m["id"] == menu_id), {})


@router.delete("/dev-console/instances/{instance_id}/instance-menus/{menu_id}")
async def delete_instance_menu(
    instance_id: int,
    menu_id: int,
    user: Dict = Depends(verify_jwt_token(_DEV_ROLES)),
    db=Depends(get_db),
):
    await _get_instance_or_404(instance_id)
    await PostgresDB.execute(
        "DELETE FROM public.instance_menus WHERE id = $1 AND instance_id = $2",
        menu_id,
        instance_id,
    )
    return {"ok": True, "deleted": menu_id}
