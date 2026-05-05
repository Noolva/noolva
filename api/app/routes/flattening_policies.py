"""
Developer Console — flattening table / relation policies CRUD.
"""
import json
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
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

_VALID_DESTINATIONS = frozenset({"postgres", "s3", "iceberg"})

# Columns added by db-structure/update_old_db_flattening_policy_destination_and_db_tables.sql
_TABLE_POLICY_ROW_SELECT = """
        id, table_name, destination, is_db_table, is_public_on_s3, target_table_name,
        refresh_strategy, refresh_interval_minutes, batch_size,
        last_refreshed, last_processed_value, is_snapshot, is_active, created_at, last_updated
"""


async def _sync_flattening_read_endpoints(
    policy_id: int,
    table_name: str,
    destination: Optional[str],
    user_id: Optional[int],
) -> List[str]:
    """GET-only Auto CRUD routes apply to postgres flatten targets only."""
    dest = (destination or "postgres").strip().lower()
    if dest == "postgres":
        return await ensure_flattening_read_endpoints(policy_id, table_name, user_id)
    await delete_flattening_read_endpoints(policy_id)
    return []


def _parse_field_config(raw: Any) -> Dict[str, Any]:
    if raw is None:
        return {}
    if isinstance(raw, dict):
        return dict(raw)
    if isinstance(raw, str):
        try:
            parsed = json.loads(raw)
            return parsed if isinstance(parsed, dict) else {}
        except (json.JSONDecodeError, TypeError):
            return {}
    return {}


async def _pg_fk_columns_from_table(table_name: str) -> List[Dict[str, Any]]:
    """FK columns defined on table_name (child side of m2o from that table's perspective)."""
    rows = await PostgresDB.fetch(
        """
        SELECT kcu.column_name AS fk_column, ccu.table_name AS ref_table
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
        table_name,
    )
    return [dict(r) for r in rows] if rows else []


async def _pg_fk_incoming_to_table(parent_table: str) -> List[Dict[str, Any]]:
    """Other tables with an FK column referencing parent_table."""
    rows = await PostgresDB.fetch(
        """
        SELECT tc.table_name AS child_table, kcu.column_name AS fk_column
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
        parent_table,
    )
    return [dict(r) for r in rows] if rows else []


async def _pg_column_names(table_name: str) -> List[str]:
    rows = await PostgresDB.fetch(
        """
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = $1
        ORDER BY ordinal_position
        """,
        table_name,
    )
    return [r["column_name"] for r in (rows or []) if r.get("column_name")]


async def _model_name_for_table(table_name: str) -> Optional[str]:
    row = await PostgresDB.fetchrow(
        """
        SELECT model_name FROM public.data_models
        WHERE table_name = $1 AND COALESCE(is_active, true) = true
        ORDER BY model_id DESC
        LIMIT 1
        """,
        table_name,
    )
    return row["model_name"] if row and row.get("model_name") else None


def _merge_candidate(
    bucket: Dict[str, Dict[str, Any]],
    key: str,
    entry: Dict[str, Any],
    prefer_existing: bool = True,
) -> None:
    if not key:
        return
    if key not in bucket:
        bucket[key] = entry
        return
    if prefer_existing:
        old = bucket[key]
        for fld in ("label", "target_model", "target_columns"):
            if (not old.get(fld)) and entry.get(fld):
                old[fld] = entry[fld]


class FlatteningTablePolicyCreate(BaseModel):
    table_name: str
    destination: str = "postgres"
    is_db_table: bool = False
    is_public_on_s3: Optional[bool] = None
    target_table_name: Optional[str] = None
    refresh_strategy: Optional[str] = None
    refresh_interval_minutes: Optional[int] = None
    batch_size: Optional[int] = None
    is_snapshot: bool = True
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
        f"""
        SELECT {_TABLE_POLICY_ROW_SELECT.strip()}
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
    dest = (payload.get("destination") or "postgres").strip().lower()
    if dest not in _VALID_DESTINATIONS:
        raise HTTPException(status_code=400, detail=f"destination must be one of {sorted(_VALID_DESTINATIONS)}")
    payload["destination"] = dest
    try:
        validate_table_policy_row(payload)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    uid = user.get("user_id")
    row = await PostgresDB.fetchrow(
        f"""
        INSERT INTO public.flattening_table_policy (
            table_name, destination, is_db_table, is_public_on_s3, target_table_name,
            refresh_strategy, refresh_interval_minutes, batch_size,
            is_snapshot, is_active
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
        RETURNING {_TABLE_POLICY_ROW_SELECT.strip()}
        """,
        payload["table_name"].strip(),
        dest,
        bool(payload.get("is_db_table", False)),
        payload.get("is_public_on_s3"),
        (payload.get("target_table_name") or "").strip() or None,
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
        paths = await _sync_flattening_read_endpoints(policy_id, payload["table_name"], dest, uid)
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
        f"""
        SELECT {_TABLE_POLICY_ROW_SELECT.strip()}
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
    raw_updates = body.model_dump(exclude_unset=True)
    if "destination" in raw_updates and raw_updates["destination"] is not None:
        d = str(raw_updates["destination"]).strip().lower()
        if d not in _VALID_DESTINATIONS:
            raise HTTPException(status_code=400, detail=f"destination must be one of {sorted(_VALID_DESTINATIONS)}")
        raw_updates["destination"] = d
    merged = {**dict(existing), **raw_updates}
    try:
        validate_table_policy_row(merged)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    uid = user.get("user_id")
    updates = raw_updates
    if not updates:
        row = existing
        paths = await _sync_flattening_read_endpoints(
            policy_id,
            existing["table_name"],
            existing.get("destination"),
            uid,
        )
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
    paths = await _sync_flattening_read_endpoints(policy_id, tn, row.get("destination"), uid)
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


@router.get("/relation-candidates")
async def list_relation_candidates(
    table_name: str = Query(..., description="Source physical table / data_models.table_name"),
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
    db=Depends(get_db),
):
    """
    Suggest relation policies for a flattening parent table: outgoing m2o (FK on parent)
    and incoming o2m (child_table.fk_column), aligned with FlattenedDatas.jsx.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    tn = (table_name or "").strip()
    if not tn:
        raise HTTPException(status_code=400, detail="table_name is required")

    outgoing_map: Dict[str, Dict[str, Any]] = {}
    incoming_map: Dict[str, Dict[str, Any]] = {}

    parent_model = await PostgresDB.fetchrow(
        """
        SELECT model_id, model_name, table_name
        FROM public.data_models
        WHERE table_name = $1 AND COALESCE(is_active, true) = true
        ORDER BY model_id DESC
        LIMIT 1
        """,
        tn,
    )
    # --- Outgoing m2o: relation fields on this model (many_to_one → FK on parent row)
    if parent_model:
        rel_fields = await PostgresDB.fetch(
            """
            SELECT dmf.field_name, dmf.display_name, dmf.field_config_json
            FROM public.data_model_fields dmf
            JOIN public.field_types ft ON ft.field_type_id = dmf.field_type_id
            WHERE dmf.model_id = $1 AND LOWER(ft.type_code) = 'relation'
            ORDER BY dmf.order_no, dmf.field_name
            """,
            int(parent_model["model_id"]),
        )
        for rf in rel_fields or []:
            cfg = _parse_field_config(rf.get("field_config_json"))
            rel_type = (cfg.get("relation_type") or "many_to_one").strip().lower()
            if rel_type != "many_to_one":
                continue
            target_model = (cfg.get("target_model") or "").strip() or None
            if not target_model:
                continue
            fname = (rf.get("field_name") or "").strip()
            if not fname:
                continue
            label = fname
            if rf.get("display_name"):
                label = f"{fname} — {rf['display_name']}"
            entry: Dict[str, Any] = {
                "key": fname,
                "label": label,
                "suggested_relation_type": "m2o",
                "suggested_strategy": "denormalize",
                "target_model": target_model,
                "target_columns": [],
            }
            tgt_table = await PostgresDB.fetchrow(
                """
                SELECT table_name FROM public.data_models
                WHERE model_name = $1 AND COALESCE(is_active, true) = true
                ORDER BY model_id DESC LIMIT 1
                """,
                target_model,
            )
            if tgt_table and tgt_table.get("table_name"):
                entry["target_columns"] = await _pg_column_names(tgt_table["table_name"])
            _merge_candidate(outgoing_map, fname, entry, prefer_existing=False)

    # Outgoing: Postgres FKs on this table (covers non–data-model relations / DB-table mode)
    for fk in await _pg_fk_columns_from_table(tn):
        col = (fk.get("fk_column") or "").strip()
        ref_t = (fk.get("ref_table") or "").strip()
        if not col or not ref_t:
            continue
        tgt_model = await _model_name_for_table(ref_t) or ref_t
        cols = await _pg_column_names(ref_t)
        label = f"{col} → {ref_t}"
        entry = {
            "key": col,
            "label": label,
            "suggested_relation_type": "m2o",
            "suggested_strategy": "denormalize",
            "target_model": tgt_model,
            "target_columns": cols,
        }
        _merge_candidate(outgoing_map, col, entry, prefer_existing=True)

    # --- Incoming o2m: other models' many_to_one fields pointing at this model
    if parent_model:
        pm_name = (parent_model.get("model_name") or "").strip()
        incoming_fields = await PostgresDB.fetch(
            """
            SELECT dm.model_name AS child_model_name, dm.table_name AS child_table_name,
                   dmf.field_name, dmf.display_name, dmf.field_config_json
            FROM public.data_model_fields dmf
            JOIN public.data_models dm ON dm.model_id = dmf.model_id
            JOIN public.field_types ft ON ft.field_type_id = dmf.field_type_id
            WHERE LOWER(ft.type_code) = 'relation'
              AND dmf.model_id <> $1
              AND COALESCE(dm.is_active, true) = true
            """,
            int(parent_model["model_id"]),
        )
        for row in incoming_fields or []:
            cfg = _parse_field_config(row.get("field_config_json"))
            rel_type = (cfg.get("relation_type") or "many_to_one").strip().lower()
            if rel_type != "many_to_one":
                continue
            tm = (cfg.get("target_model") or "").strip()
            if not tm:
                continue
            if tm != pm_name and tm != tn:
                continue
            ct = (row.get("child_table_name") or "").strip()
            fn = (row.get("field_name") or "").strip()
            if not ct or not fn:
                continue
            key = f"{ct}.{fn}"
            label = key
            if row.get("display_name"):
                label = f"{key} — {row['display_name']}"
            entry = {
                "key": key,
                "label": label,
                "suggested_relation_type": "o2m",
                "suggested_strategy": "json",
                "target_model": (row.get("child_model_name") or "").strip() or None,
                "target_columns": [],
            }
            _merge_candidate(incoming_map, key, entry, prefer_existing=False)

    for fk in await _pg_fk_incoming_to_table(tn):
        ct = (fk.get("child_table") or "").strip()
        fc = (fk.get("fk_column") or "").strip()
        if not ct or not fc:
            continue
        key = f"{ct}.{fc}"
        child_model_name = await _model_name_for_table(ct) or ct
        entry = {
            "key": key,
            "label": f"{key} (FK)",
            "suggested_relation_type": "o2m",
            "suggested_strategy": "json",
            "target_model": child_model_name,
            "target_columns": [],
        }
        _merge_candidate(incoming_map, key, entry, prefer_existing=True)

    def _sort_key(c: Dict[str, Any]) -> str:
        return (c.get("key") or "").lower()

    outgoing = sorted(outgoing_map.values(), key=_sort_key)
    incoming = sorted(incoming_map.values(), key=_sort_key)
    return {"table_name": tn, "outgoing": outgoing, "incoming": incoming}


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
