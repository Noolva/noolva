"""
Developer Console — flattening table / relation policies CRUD.
"""
import json
from typing import Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from middlewares.auth import verify_jwt_token
from utils.db import get_db
from classes.postgres_db import PostgresDB
from utils.flattening_policy import (
    delete_flattening_read_endpoints,
    ensure_flattening_read_endpoints,
    validate_relation_row,
    validate_table_policy_row,
)

router = APIRouter(prefix="/dev-console/flattening-policies", tags=["Developer Console - Flattening Policies"])

def _safe_json(obj):
    try:
        if isinstance(obj, str):
            return json.loads(obj) if obj.strip() else {}
        return obj if isinstance(obj, dict) else {}
    except Exception:
        return {}


@router.get("/relation-candidates")
async def relation_candidates(
    table_name: str,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
    db=Depends(get_db),
):
    """
    Returns both:
    - outgoing (m2o): relation fields on this model
    - incoming (o2m): other models whose relation fields target this model
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    tn = (table_name or "").strip()
    if not tn:
        raise HTTPException(status_code=400, detail="table_name is required")

    model = await PostgresDB.fetchrow(
        """
        SELECT model_id, model_name, table_name, display_name
        FROM public.data_models
        WHERE table_name = $1
        LIMIT 1
        """,
        tn,
    )
    if not model:
        raise HTTPException(status_code=404, detail="No data model for table_name")
    model_id = int(model["model_id"])
    model_name = model["model_name"]

    # Outgoing relations (m2o)
    outgoing_rows = await PostgresDB.fetch(
        """
        SELECT dmf.field_name, dmf.display_name, dmf.field_config_json
        FROM public.data_model_fields dmf
        JOIN public.field_types ft ON ft.field_type_id = dmf.field_type_id
        WHERE dmf.model_id = $1
          AND ft.type_code = 'relation'
        ORDER BY dmf.order_no, dmf.field_name
        """,
        model_id,
    )
    outgoing = []
    for r in outgoing_rows or []:
        cfg = _safe_json(r.get("field_config_json"))
        target = cfg.get("target_model") or cfg.get("targetModel") or cfg.get("target_table")
        outgoing.append(
            {
                "key": r["field_name"],  # store directly in flattening_relation_policy.relation_name
                "label": f'{r["field_name"]} — {(r.get("display_name") or r["field_name"])}'
                + (f" → {target}" if target else ""),
                "kind": "outgoing",
                "field_name": r["field_name"],
                "target_model": target,
                "suggested_relation_type": "m2o",
                "suggested_strategy": "denormalize",
            }
        )

    # Incoming relations (o2m): other models that point to this model via field_config_json.target_model
    incoming_rows = await PostgresDB.fetch(
        """
        SELECT dm.model_id, dm.model_name, dm.table_name, dm.display_name,
               dmf.field_name, dmf.display_name AS field_display_name,
               dmf.field_config_json
        FROM public.data_model_fields dmf
        JOIN public.data_models dm ON dm.model_id = dmf.model_id
        JOIN public.field_types ft ON ft.field_type_id = dmf.field_type_id
        WHERE ft.type_code = 'relation'
          AND dmf.model_id <> $1
          AND (
            (dmf.field_config_json->>'target_model') = $2
            OR (dmf.field_config_json->>'target_model') = $3
          )
        ORDER BY dm.model_name, dmf.field_name
        """,
        model_id,
        model_name,
        tn,
    )
    incoming = []
    for r in incoming_rows or []:
        child_table = r.get("table_name")
        fk_field = r.get("field_name")
        # encode to keep unique and preserve FK info for later engine
        rel_key = f"{child_table}.{fk_field}" if child_table and fk_field else f"{r.get('model_name')}.{fk_field}"
        incoming.append(
            {
                "key": rel_key,  # store encoded in relation_name
                "label": f'{rel_key} — {(r.get("display_name") or r.get("model_name"))} → {model_name}',
                "kind": "incoming",
                "child_model_name": r.get("model_name"),
                "child_table_name": child_table,
                "child_fk_field": fk_field,
                "suggested_relation_type": "o2m",
                "suggested_strategy": "json",
            }
        )

    return {
        "model": {"model_id": model_id, "model_name": model_name, "table_name": tn},
        "outgoing": outgoing,
        "incoming": incoming,
    }


class FlatteningTablePolicyCreate(BaseModel):
    table_name: str
    refresh_strategy: Optional[str] = None
    refresh_interval_minutes: Optional[int] = None
    batch_size: Optional[int] = None
    is_snapshot: bool = True
    is_active: bool = True


class FlatteningTablePolicyUpdate(BaseModel):
    table_name: Optional[str] = None
    refresh_strategy: Optional[str] = None
    refresh_interval_minutes: Optional[int] = None
    batch_size: Optional[int] = None
    last_refreshed: Optional[str] = None
    last_processed_value: Optional[str] = None
    is_snapshot: Optional[bool] = None
    is_active: Optional[bool] = None


class FlatteningRelationPolicyCreate(BaseModel):
    table_name: str
    relation_name: str
    relation_type: str
    strategy: str
    include_fields: Optional[List[str]] = None
    target_table: Optional[str] = None
    is_required: bool = False


class FlatteningRelationPolicyUpdate(BaseModel):
    relation_name: Optional[str] = None
    relation_type: Optional[str] = None
    strategy: Optional[str] = None
    include_fields: Optional[List[str]] = None
    target_table: Optional[str] = None
    is_required: Optional[bool] = None


@router.get("/table-policies")
async def list_table_policies(
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
    db=Depends(get_db),
):
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    rows = await PostgresDB.fetch(
        """
        SELECT id, table_name, refresh_strategy, refresh_interval_minutes, batch_size,
               last_refreshed, last_processed_value, is_snapshot, is_active, created_at, last_updated
        FROM public.flattening_table_policy
        ORDER BY table_name
        """
    )
    return {"items": rows}


@router.post("/table-policies")
async def create_table_policy(
    body: FlatteningTablePolicyCreate,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
    db=Depends(get_db),
):
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    payload = body.model_dump()
    try:
        validate_table_policy_row(payload)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    uid = user.get("user_id")
    row = await PostgresDB.fetchrow(
        """
        INSERT INTO public.flattening_table_policy (
            table_name, refresh_strategy, refresh_interval_minutes, batch_size,
            is_snapshot, is_active
        ) VALUES ($1, $2, $3, $4, $5, $6)
        RETURNING id, table_name, refresh_strategy, refresh_interval_minutes, batch_size,
                  is_snapshot, is_active, created_at
        """,
        payload["table_name"].strip(),
        payload.get("refresh_strategy"),
        payload.get("refresh_interval_minutes"),
        payload.get("batch_size"),
        payload.get("is_snapshot", True),
        payload.get("is_active", True),
    )
    if not row:
        raise HTTPException(status_code=500, detail="Insert failed")
    policy_id = int(row["id"])
    try:
        paths = await ensure_flattening_read_endpoints(policy_id, payload["table_name"], uid)
    except ValueError as e:
        await PostgresDB.execute("DELETE FROM public.flattening_table_policy WHERE id = $1", policy_id)
        raise HTTPException(status_code=400, detail=str(e))
    return {**dict(row), "read_endpoints": paths}


@router.get("/table-policies/{policy_id}")
async def get_table_policy(
    policy_id: int,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
    db=Depends(get_db),
):
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    row = await PostgresDB.fetchrow(
        """
        SELECT id, table_name, refresh_strategy, refresh_interval_minutes, batch_size,
               last_refreshed, last_processed_value, is_snapshot, is_active, created_at, last_updated
        FROM public.flattening_table_policy WHERE id = $1
        """,
        policy_id,
    )
    if not row:
        raise HTTPException(status_code=404, detail="Policy not found")
    return dict(row)


@router.put("/table-policies/{policy_id}")
async def update_table_policy(
    policy_id: int,
    body: FlatteningTablePolicyUpdate,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
    db=Depends(get_db),
):
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    existing = await PostgresDB.fetchrow(
        "SELECT * FROM public.flattening_table_policy WHERE id = $1",
        policy_id,
    )
    if not existing:
        raise HTTPException(status_code=404, detail="Policy not found")
    merged = {**dict(existing), **{k: v for k, v in body.model_dump().items() if v is not None}}
    try:
        validate_table_policy_row(merged)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    uid = user.get("user_id")
    updates = body.model_dump(exclude_unset=True)
    if not updates:
        row = existing
        paths = await ensure_flattening_read_endpoints(policy_id, existing["table_name"], uid)
        return {**dict(row), "read_endpoints": paths}
    fields = []
    args = []
    idx = 1
    if "table_name" in updates:
        fields.append(f"table_name = ${idx}")
        args.append(updates["table_name"].strip())
        idx += 1
    for col in (
        "refresh_strategy",
        "refresh_interval_minutes",
        "batch_size",
        "is_snapshot",
        "is_active",
    ):
        if col in updates:
            fields.append(f"{col} = ${idx}")
            args.append(updates[col])
            idx += 1
    if "last_refreshed" in updates:
        fields.append(f"last_refreshed = ${idx}")
        args.append(updates["last_refreshed"])
        idx += 1
    if "last_processed_value" in updates:
        fields.append(f"last_processed_value = ${idx}")
        args.append(updates["last_processed_value"])
        idx += 1
    fields.append("last_updated = CURRENT_TIMESTAMP")
    args.append(policy_id)
    await PostgresDB.execute(
        f"UPDATE public.flattening_table_policy SET {', '.join(fields)} WHERE id = ${idx}",
        *args,
    )
    row = await PostgresDB.fetchrow(
        "SELECT * FROM public.flattening_table_policy WHERE id = $1",
        policy_id,
    )
    tn = row["table_name"]
    paths = await ensure_flattening_read_endpoints(policy_id, tn, uid)
    return {**dict(row), "read_endpoints": paths}


@router.delete("/table-policies/{policy_id}")
async def delete_table_policy(
    policy_id: int,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
    db=Depends(get_db),
):
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    existing = await PostgresDB.fetchrow(
        "SELECT id FROM public.flattening_table_policy WHERE id = $1",
        policy_id,
    )
    if not existing:
        raise HTTPException(status_code=404, detail="Policy not found")
    await delete_flattening_read_endpoints(policy_id)
    await PostgresDB.execute("DELETE FROM public.flattening_table_policy WHERE id = $1", policy_id)
    return {"ok": True}


@router.get("/relation-policies")
async def list_relation_policies(
    table_name: Optional[str] = None,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
    db=Depends(get_db),
):
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    if table_name:
        rows = await PostgresDB.fetch(
            """
            SELECT id, table_name, relation_name, relation_type, strategy, include_fields,
                   target_table, is_required, created_at
            FROM public.flattening_relation_policy
            WHERE table_name = $1
            ORDER BY relation_name
            """,
            table_name.strip(),
        )
    else:
        rows = await PostgresDB.fetch(
            """
            SELECT id, table_name, relation_name, relation_type, strategy, include_fields,
                   target_table, is_required, created_at
            FROM public.flattening_relation_policy
            ORDER BY table_name, relation_name
            """
        )
    return {"items": rows}


@router.post("/relation-policies")
async def create_relation_policy(
    body: FlatteningRelationPolicyCreate,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
    db=Depends(get_db),
):
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    payload = body.model_dump()
    inc = payload.get("include_fields")
    if isinstance(inc, str):
        payload["include_fields"] = [x.strip() for x in inc.split(",") if x.strip()] or None
    try:
        validate_relation_row(payload)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    parent = await PostgresDB.fetchrow(
        "SELECT 1 FROM public.flattening_table_policy WHERE table_name = $1",
        payload["table_name"].strip(),
    )
    if not parent:
        raise HTTPException(status_code=400, detail="Unknown flattening_table_policy.table_name")
    row = await PostgresDB.fetchrow(
        """
        INSERT INTO public.flattening_relation_policy (
            table_name, relation_name, relation_type, strategy, include_fields, target_table, is_required
        ) VALUES ($1, $2, $3, $4, $5, $6, $7)
        RETURNING id, table_name, relation_name, relation_type, strategy, include_fields, target_table,
                  is_required, created_at
        """,
        payload["table_name"].strip(),
        payload["relation_name"].strip(),
        payload["relation_type"],
        payload["strategy"],
        payload.get("include_fields"),
        payload.get("target_table"),
        payload.get("is_required", False),
    )
    return dict(row)


@router.put("/relation-policies/{relation_id}")
async def update_relation_policy(
    relation_id: int,
    body: FlatteningRelationPolicyUpdate,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
    db=Depends(get_db),
):
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    existing = await PostgresDB.fetchrow(
        "SELECT * FROM public.flattening_relation_policy WHERE id = $1",
        relation_id,
    )
    if not existing:
        raise HTTPException(status_code=404, detail="Relation policy not found")
    merged = {**dict(existing), **{k: v for k, v in body.model_dump().items() if v is not None}}
    try:
        validate_relation_row(merged)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    updates = body.model_dump(exclude_unset=True)
    if not updates:
        return dict(existing)
    if isinstance(updates.get("include_fields"), str):
        s = updates["include_fields"]
        updates["include_fields"] = [x.strip() for x in s.split(",") if x.strip()] or None
    fields = []
    args = []
    idx = 1
    for col in ("relation_name", "relation_type", "strategy", "include_fields", "target_table", "is_required"):
        if col in updates:
            fields.append(f"{col} = ${idx}")
            args.append(updates[col])
            idx += 1
    args.append(relation_id)
    await PostgresDB.execute(
        f"UPDATE public.flattening_relation_policy SET {', '.join(fields)} WHERE id = ${idx}",
        *args,
    )
    row = await PostgresDB.fetchrow(
        "SELECT * FROM public.flattening_relation_policy WHERE id = $1",
        relation_id,
    )
    return dict(row)


@router.delete("/relation-policies/{relation_id}")
async def delete_relation_policy(
    relation_id: int,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
    db=Depends(get_db),
):
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    ex = await PostgresDB.fetchrow(
        "SELECT id FROM public.flattening_relation_policy WHERE id = $1",
        relation_id,
    )
    if not ex:
        raise HTTPException(status_code=404, detail="Relation policy not found")
    await PostgresDB.execute(
        "DELETE FROM public.flattening_relation_policy WHERE id = $1",
        relation_id,
    )
    return {"ok": True}
