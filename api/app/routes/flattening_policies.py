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
from utils.flattening_materializer import ensure_flattened_table_and_model, delete_flattened_table_and_model

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
    if model:
        model_id = int(model["model_id"])
        model_name = model["model_name"]
    else:
        model_id = None
        model_name = None

    outgoing = []
    incoming = []

    if model_id is not None:
        # Outgoing relations (m2o) from model metadata
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

        # Incoming relations (o2m) from other models pointing to this model
        incoming_rows = await PostgresDB.fetch(
            """
            SELECT dm.model_id, dm.model_name, dm.table_name, dm.display_name,
                   dmf.field_name, dmf.display_name AS field_display_name
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
        for r in incoming_rows or []:
            child_table = r.get("table_name")
            fk_field = r.get("field_name")
            rel_key = f"{child_table}.{fk_field}" if child_table and fk_field else f"{r.get('model_name')}.{fk_field}"
            incoming.append(
                {
                    "key": rel_key,
                    "label": f'{rel_key} — {(r.get("display_name") or r.get("model_name"))} → {model_name}',
                    "kind": "incoming",
                    "child_model_name": r.get("model_name"),
                    "child_table_name": child_table,
                    "child_fk_field": fk_field,
                    "suggested_relation_type": "o2m",
                    "suggested_strategy": "json",
                }
            )
    else:
        # Fallback for DB tables (non-model): use information_schema FK constraints
        outgoing_fk = await PostgresDB.fetch(
            """
            SELECT
              kcu.column_name AS fk_column,
              ccu.table_name AS ref_table
            FROM information_schema.table_constraints tc
            JOIN information_schema.key_column_usage kcu
              ON tc.constraint_name = kcu.constraint_name
             AND tc.table_schema = kcu.table_schema
            JOIN information_schema.constraint_column_usage ccu
              ON ccu.constraint_name = tc.constraint_name
             AND ccu.table_schema = tc.table_schema
            WHERE tc.constraint_type = 'FOREIGN KEY'
              AND tc.table_schema = 'public'
              AND tc.table_name = $1
            ORDER BY kcu.column_name
            """,
            tn,
        )
        for r in outgoing_fk or []:
            fk_col = r.get("fk_column")
            ref_table = r.get("ref_table")
            cols = await PostgresDB.fetch(
                """
                SELECT column_name
                FROM information_schema.columns
                WHERE table_schema = 'public' AND table_name = $1
                ORDER BY ordinal_position
                """,
                ref_table,
            )
            ref_cols = [c["column_name"] for c in (cols or []) if c.get("column_name")]
            outgoing.append(
                {
                    "key": fk_col,
                    "label": f"{fk_col} → {ref_table}",
                    "kind": "outgoing",
                    "field_name": fk_col,
                    "target_model": ref_table,
                    "target_table_name": ref_table,
                    "target_columns": ref_cols,
                    "suggested_relation_type": "m2o",
                    "suggested_strategy": "denormalize",
                }
            )
        incoming_fk = await PostgresDB.fetch(
            """
            SELECT
              tc.table_name AS child_table,
              kcu.column_name AS fk_column
            FROM information_schema.table_constraints tc
            JOIN information_schema.key_column_usage kcu
              ON tc.constraint_name = kcu.constraint_name
             AND tc.table_schema = kcu.table_schema
            JOIN information_schema.constraint_column_usage ccu
              ON ccu.constraint_name = tc.constraint_name
             AND ccu.table_schema = tc.table_schema
            WHERE tc.constraint_type = 'FOREIGN KEY'
              AND tc.table_schema = 'public'
              AND ccu.table_name = $1
            ORDER BY tc.table_name, kcu.column_name
            """,
            tn,
        )
        for r in incoming_fk or []:
            child_table = r.get("child_table")
            fk_field = r.get("fk_column")
            rel_key = f"{child_table}.{fk_field}"
            cols = await PostgresDB.fetch(
                """
                SELECT column_name
                FROM information_schema.columns
                WHERE table_schema = 'public' AND table_name = $1
                ORDER BY ordinal_position
                """,
                child_table,
            )
            child_cols = [c["column_name"] for c in (cols or []) if c.get("column_name")]
            incoming.append(
                {
                    "key": rel_key,
                    "label": f"{rel_key} → {tn}",
                    "kind": "incoming",
                    "child_table_name": child_table,
                    "child_fk_field": fk_field,
                    "target_table_name": child_table,
                    "target_columns": child_cols,
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
    destination: Optional[str] = "postgres"  # postgres | s3 | iceberg
    is_db_table: bool = False
    is_public_on_s3: Optional[bool] = None
    refresh_strategy: Optional[str] = None
    refresh_interval_minutes: Optional[int] = None
    batch_size: Optional[int] = None
    is_snapshot: bool = False
    is_active: bool = True


class FlatteningTablePolicyUpdate(BaseModel):
    table_name: Optional[str] = None
    destination: Optional[str] = None
    is_db_table: Optional[bool] = None
    is_public_on_s3: Optional[bool] = None
    target_table_name: Optional[str] = None
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
        SELECT id, table_name, destination, is_db_table, is_public_on_s3, target_table_name,
               refresh_strategy, refresh_interval_minutes, batch_size,
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
    # Snapshot is not supported; force false always.
    payload["is_snapshot"] = False
    try:
        validate_table_policy_row(payload)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    uid = user.get("user_id")
    row = await PostgresDB.fetchrow(
        """
        INSERT INTO public.flattening_table_policy (
            table_name, destination, is_db_table, is_public_on_s3, target_table_name,
            refresh_strategy, refresh_interval_minutes, batch_size,
            is_snapshot, is_active
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
        RETURNING id, table_name, destination, is_db_table, is_public_on_s3, target_table_name,
                  refresh_strategy, refresh_interval_minutes, batch_size,
                  is_snapshot, is_active, created_at
        """,
        payload["table_name"].strip(),
        (payload.get("destination") or "postgres"),
        bool(payload.get("is_db_table") or False),
        payload.get("is_public_on_s3"),
        (f"flat_{payload['table_name'].strip()}" if (payload.get("destination") or "postgres") == "postgres" else None),
        payload.get("refresh_strategy"),
        payload.get("refresh_interval_minutes"),
        payload.get("batch_size"),
        False,
        payload.get("is_active", True),
    )
    if not row:
        raise HTTPException(status_code=500, detail="Insert failed")
    policy_id = int(row["id"])
    paths = []
    dest = (payload.get("destination") or "postgres").strip().lower()
    if dest == "postgres":
        # Create flat table + Data Model at policy creation time (not in job).
        flat_name = row.get("target_table_name") or f"flat_{payload['table_name'].strip()}"
        try:
            await ensure_flattened_table_and_model(
                policy_id=policy_id,
                source_table=payload["table_name"].strip(),
                target_table=flat_name,
                created_by=uid,
            )
            paths = await ensure_flattening_read_endpoints(policy_id, flat_name, uid)
        except Exception:
            paths = []
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
        SELECT id, table_name, destination, is_db_table, is_public_on_s3, target_table_name,
               refresh_strategy, refresh_interval_minutes, batch_size,
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
    # Snapshot is not supported; force false always.
    merged["is_snapshot"] = False
    try:
        validate_table_policy_row(merged)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    uid = user.get("user_id")
    updates = body.model_dump(exclude_unset=True)
    if "is_snapshot" in updates:
        updates.pop("is_snapshot", None)
    # Snapshot is not supported; force false always.
    updates["is_snapshot"] = False
    if not updates:
        row = existing
        paths = []
        if row.get("destination") == "postgres" and not row.get("is_db_table"):
            # Create GET-only endpoints for the flattened target table (flat_<table_name>).
            try:
                flat_name = row.get("target_table_name") or f"flat_{row.get('table_name')}"
                paths = await ensure_flattening_read_endpoints(policy_id, flat_name, uid)
            except Exception:
                paths = []
        return {**dict(row), "read_endpoints": paths}
    fields = []
    args = []
    idx = 1
    if "table_name" in updates:
        fields.append(f"table_name = ${idx}")
        args.append(updates["table_name"].strip())
        idx += 1
    for col in (
        "destination",
        "is_db_table",
        "is_public_on_s3",
        "target_table_name",
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
    paths = []
    if row.get("destination") == "postgres":
        try:
            flat_name = row.get("target_table_name") or f"flat_{tn}"
            await ensure_flattened_table_and_model(
                policy_id=int(policy_id),
                source_table=tn,
                target_table=flat_name,
                created_by=uid,
            )
            paths = await ensure_flattening_read_endpoints(policy_id, flat_name, uid)
        except Exception:
            paths = []
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
        "SELECT id, table_name, destination, target_table_name FROM public.flattening_table_policy WHERE id = $1",
        policy_id,
    )
    if not existing:
        raise HTTPException(status_code=404, detail="Policy not found")
    await delete_flattening_read_endpoints(policy_id)
    if (existing.get("destination") or "postgres") == "postgres":
        tt = existing.get("target_table_name") or f"flat_{existing.get('table_name')}"
        try:
            await delete_flattened_table_and_model(policy_id=int(policy_id), target_table=str(tt))
        except Exception:
            pass
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
    # If destination=postgres, adjust flat table schema + model + read endpoints immediately.
    try:
        pol = await PostgresDB.fetchrow(
            "SELECT id, destination, target_table_name FROM public.flattening_table_policy WHERE table_name = $1 LIMIT 1",
            payload["table_name"].strip(),
        )
        if pol and (pol.get("destination") or "postgres") == "postgres":
            pid = int(pol["id"])
            uid = user.get("user_id")
            flat_name = pol.get("target_table_name") or f"flat_{payload['table_name'].strip()}"
            await ensure_flattened_table_and_model(
                policy_id=pid,
                source_table=payload["table_name"].strip(),
                target_table=flat_name,
                created_by=uid,
            )
            await ensure_flattening_read_endpoints(pid, flat_name, uid)
    except Exception:
        pass
    await PostgresDB.execute(
        "UPDATE public.flattening_table_policy SET last_updated = CURRENT_TIMESTAMP WHERE table_name = $1",
        payload["table_name"].strip(),
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
    # If destination=postgres, adjust flat table schema + model + read endpoints immediately.
    try:
        pol = await PostgresDB.fetchrow(
            "SELECT id, destination, target_table_name FROM public.flattening_table_policy WHERE table_name = $1 LIMIT 1",
            row.get("table_name"),
        )
        if pol and (pol.get("destination") or "postgres") == "postgres":
            pid = int(pol["id"])
            uid = user.get("user_id")
            flat_name = pol.get("target_table_name") or f"flat_{row.get('table_name')}"
            await ensure_flattened_table_and_model(
                policy_id=pid,
                source_table=row.get("table_name"),
                target_table=flat_name,
                created_by=uid,
            )
            await ensure_flattening_read_endpoints(pid, flat_name, uid)
    except Exception:
        pass
    await PostgresDB.execute(
        "UPDATE public.flattening_table_policy SET last_updated = CURRENT_TIMESTAMP WHERE table_name = $1",
        (row.get("table_name") or "").strip(),
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
        "SELECT id, table_name FROM public.flattening_relation_policy WHERE id = $1",
        relation_id,
    )
    if not ex:
        raise HTTPException(status_code=404, detail="Relation policy not found")
    await PostgresDB.execute(
        "DELETE FROM public.flattening_relation_policy WHERE id = $1",
        relation_id,
    )
    await PostgresDB.execute(
        "UPDATE public.flattening_table_policy SET last_updated = CURRENT_TIMESTAMP WHERE table_name = $1",
        (ex.get("table_name") or "").strip(),
    )
    # If destination=postgres, adjust flat table schema + model + read endpoints immediately.
    try:
        pol = await PostgresDB.fetchrow(
            "SELECT id, destination, target_table_name FROM public.flattening_table_policy WHERE table_name = $1 LIMIT 1",
            ex.get("table_name"),
        )
        if pol and (pol.get("destination") or "postgres") == "postgres":
            pid = int(pol["id"])
            uid = user.get("user_id")
            flat_name = pol.get("target_table_name") or f"flat_{ex.get('table_name')}"
            await ensure_flattened_table_and_model(
                policy_id=pid,
                source_table=ex.get("table_name"),
                target_table=flat_name,
                created_by=uid,
            )
            await ensure_flattening_read_endpoints(pid, flat_name, uid)
    except Exception:
        pass
    return {"ok": True}
