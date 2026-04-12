"""
Developer Console — data_lifecycle_policy CRUD, allowed sources, batch ledger.
"""
import logging
import re
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from middlewares.auth import verify_jwt_token
from utils.db import get_db
from classes.postgres_db import PostgresDB
from utils.data_lifecycle_policy import validate_lifecycle_row
from utils.data_lifecycle_ledger import list_batch_ledger_rows
from utils.data_lifecycle_sync import lifecycle_destination_table
from utils.data_lifecycle_sources import (
    compute_policy_destination_table,
    default_iceberg_table_identifier,
    is_allowed_lifecycle_source,
    list_archived_physical_tables,
    list_flattening_flat_targets,
    resolve_lifecycle_root_for_source,
)
from utils.lifecycle_read_endpoints import (
    delete_lifecycle_generated_model,
    delete_lifecycle_policy_read_endpoints,
    provision_lifecycle_policy_read_endpoints,
)

router = APIRouter(prefix="/dev-console/data-lifecycle-policies", tags=["Developer Console - Data Lifecycle"])

_SAFE_TABLE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")

logger = logging.getLogger("noolva_api.routes.data_lifecycle_policies")


async def _try_provision_read_endpoints(policy_id: int, user_id: Optional[int]) -> Dict[str, Any]:
    try:
        pol = await _fetch_lifecycle_policy(policy_id)
        return await provision_lifecycle_policy_read_endpoints(policy_id, pol, user_id)
    except Exception:
        logger.exception("lifecycle read endpoint provisioning failed policy_id=%s", policy_id)
        return {
            "lifecycle_archive_read_endpoints": [],
            "lifecycle_iceberg_read_stub": None,
            "read_endpoints_error": True,
        }


@router.get("/source-table-options")
async def lifecycle_source_table_options(
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
    db=Depends(get_db),
):
    """Allowed physical sources: flattening flat targets and archived_* tables."""
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    flats = await list_flattening_flat_targets()
    flat_opts = []
    for r in flats:
        ft = (r.get("flat_table") or "").strip()
        root = (r.get("root_table") or "").strip()
        if not ft:
            continue
        flat_opts.append(
            {
                "value": ft,
                "label": f"{ft} (root: {root})",
                "root_table": root,
                "kind": "flat",
            }
        )
    arch = await list_archived_physical_tables()
    arch_opts = [{"value": a, "label": a, "kind": "archived"} for a in arch]
    return {"flat_sources": flat_opts, "archived_sources": arch_opts}


@router.get("/batch-ledger")
async def lifecycle_batch_ledger(
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
    db=Depends(get_db),
    policy_id: Optional[int] = Query(None),
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
):
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    rows = await list_batch_ledger_rows(policy_id, limit=limit, offset=offset)
    if policy_id is not None:
        c = await PostgresDB.fetchrow(
            """
            SELECT COUNT(*)::int AS n FROM public.data_lifecycle_batch_ledger WHERE policy_id = $1
            """,
            int(policy_id),
        )
    else:
        c = await PostgresDB.fetchrow(
            "SELECT COUNT(*)::int AS n FROM public.data_lifecycle_batch_ledger",
        )
    total = int(c["n"]) if c else 0
    return {"items": rows, "total": total, "limit": limit, "offset": offset}


@router.get("/table-hints")
async def lifecycle_table_hints(
    table_name: str,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
    db=Depends(get_db),
):
    """
    PK/time hints for a physical lifecycle source table (flat or archived_*).
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    tn = (table_name or "").strip()
    if not tn or not _SAFE_TABLE.match(tn):
        raise HTTPException(status_code=400, detail="Invalid table_name")

    exists = await PostgresDB.fetchrow(
        """
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = $1
        """,
        tn,
    )
    if not exists:
        raise HTTPException(status_code=404, detail=f"Table not found: {tn}")

    pk_row = await PostgresDB.fetchrow(
        """
        SELECT kcu.column_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu
          ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
        WHERE tc.table_schema = 'public' AND tc.table_name = $1 AND tc.constraint_type = 'PRIMARY KEY'
        ORDER BY kcu.ordinal_position
        LIMIT 1
        """,
        tn,
    )
    pk_column = (pk_row["column_name"] if pk_row and pk_row.get("column_name") else "id") or "id"

    time_candidates = ["last_updated", "updated_at", "modified_at", "updated_on", "idate", "created_at"]
    time_row = await PostgresDB.fetchrow(
        """
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = $1
          AND column_name = ANY($2::text[])
        ORDER BY array_position($2::text[], column_name)
        LIMIT 1
        """,
        tn,
        time_candidates,
    )
    preferred_time_column = time_row["column_name"] if time_row else None

    present_cols = await PostgresDB.fetch(
        """
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = $1
        ORDER BY ordinal_position
        """,
        tn,
    )
    col_set = {r["column_name"] for r in (present_cols or []) if r.get("column_name")}
    time_column_options = [c for c in time_candidates if c in col_set]

    ftp = await PostgresDB.fetchrow(
        """
        SELECT table_name::text AS root_table, target_table_name::text AS flat_table
        FROM public.flattening_table_policy
        WHERE TRIM(target_table_name::text) = $1 AND COALESCE(is_active, true)
        LIMIT 1
        """,
        tn,
    )
    lifecycle_root = (ftp.get("root_table") or "").strip() if ftp else None
    flattening_flat = (ftp.get("flat_table") or "").strip() if ftp else None

    if tn.startswith("archived_"):
        next_iceberg = default_iceberg_table_identifier(tn)
        archive_export_key = lifecycle_destination_table(tn)
    else:
        next_iceberg = default_iceberg_table_identifier(lifecycle_destination_table(tn))
        archive_export_key = lifecycle_destination_table(tn)

    return {
        "table_name": tn,
        "pk_column": pk_column,
        "time_column": preferred_time_column,
        "time_column_options": time_column_options,
        "suggested_policy_label": f"Lifecycle: {tn}",
        "lifecycle_root_table": lifecycle_root,
        "flattening_target_table": flattening_flat or (tn if not tn.startswith("archived_") else None),
        "archive_export_key": archive_export_key,
        "suggested_iceberg_identifier": next_iceberg,
        "example": {
            "physical_source": tn,
            "postgres_archive_target": archive_export_key if not tn.startswith("archived_") else None,
            "iceberg_logical_name": next_iceberg if tn.startswith("archived_") else None,
        },
    }


class DataLifecycleCreate(BaseModel):
    policy_label: Optional[str] = None
    table_name: str
    pk_column: str = "id"
    transfer_mode: str = "time_based"
    time_column: Optional[str] = None
    filter_condition: Optional[str] = None
    destination_type: str
    destination_table: Optional[str] = None
    archive_source_table: Optional[str] = None
    is_public_on_s3: Optional[bool] = None
    movement_type: str
    sync_strategy: str
    sync_batch_size: int = 1000
    sync_interval_minutes: Optional[int] = None
    purge_enabled: bool = False
    purge_after_interval_minutes: Optional[int] = None
    is_active: bool = True


class DataLifecycleUpdate(BaseModel):
    policy_label: Optional[str] = None
    table_name: Optional[str] = None
    pk_column: Optional[str] = None
    transfer_mode: Optional[str] = None
    time_column: Optional[str] = None
    filter_condition: Optional[str] = None
    destination_type: Optional[str] = None
    destination_table: Optional[str] = None
    archive_source_table: Optional[str] = None
    is_public_on_s3: Optional[bool] = None
    movement_type: Optional[str] = None
    sync_strategy: Optional[str] = None
    sync_batch_size: Optional[int] = None
    sync_interval_minutes: Optional[int] = None
    purge_enabled: Optional[bool] = None
    purge_after_interval_minutes: Optional[int] = None
    last_synced_at: Optional[str] = None
    last_processed_value: Optional[str] = None
    is_active: Optional[bool] = None


@router.get("/")
async def list_policies(
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
    db=Depends(get_db),
):
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    rows = await PostgresDB.fetch(
        """
        SELECT id, policy_label, table_name, pk_column, transfer_mode::text AS transfer_mode,
               time_column, filter_condition, destination_type::text AS destination_type,
               destination_table, archive_source_table, is_public_on_s3, lifecycle_root_table,
               movement_type::text AS movement_type,
               sync_strategy::text AS sync_strategy, sync_batch_size, sync_interval_minutes,
               purge_enabled, purge_after_interval_minutes,
               last_synced_at, last_processed_value, last_archive_completed_at, last_purge_completed_at,
               is_active, created_at, last_updated
        FROM public.data_lifecycle_policy
        ORDER BY table_name, id
        """
    )
    return {"items": rows}


@router.post("/")
async def create_policy(
    body: DataLifecycleCreate,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
    db=Depends(get_db),
):
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    payload = body.model_dump()
    tn = payload["table_name"].strip()
    dest_raw = payload["destination_type"]
    dest = str(dest_raw).rsplit(".", 1)[-1]

    ok, err = await is_allowed_lifecycle_source(tn, dest)
    if not ok:
        raise HTTPException(status_code=400, detail=err)

    root = await resolve_lifecycle_root_for_source(tn)
    if payload.get("purge_enabled") and dest in ("postgres_archive", "s3") and not root:
        raise HTTPException(
            status_code=400,
            detail="Purge requires a flat materialized source linked to a flattening root.",
        )

    ice_override = (payload.get("destination_table") or "").strip() or None
    dest_table_val = compute_policy_destination_table(tn, dest, ice_override if dest == "iceberg" else None)
    payload["destination_table"] = dest_table_val
    payload["table_name"] = tn

    try:
        validate_lifecycle_row(payload)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    row = await PostgresDB.fetchrow(
        """
        INSERT INTO public.data_lifecycle_policy (
            policy_label, table_name, pk_column, transfer_mode, time_column, filter_condition,
            destination_type, destination_table, archive_source_table, is_public_on_s3, lifecycle_root_table,
            movement_type, sync_strategy,
            sync_batch_size, sync_interval_minutes, purge_enabled, purge_after_interval_minutes, is_active
        ) VALUES (
            $1, $2, $3, $4::transfer_mode_enum, $5, $6,
            $7::destination_type_enum, $8, $9, $10, $11,
            $12::movement_type_enum, $13::sync_strategy_enum,
            $14, $15, $16, $17, $18
        )
        RETURNING id
        """,
        payload.get("policy_label"),
        tn,
        payload.get("pk_column") or "id",
        payload.get("transfer_mode") or "time_based",
        payload.get("time_column"),
        payload.get("filter_condition"),
        payload["destination_type"],
        dest_table_val,
        None,
        payload.get("is_public_on_s3"),
        root,
        payload["movement_type"],
        payload["sync_strategy"],
        payload.get("sync_batch_size") or 1000,
        payload.get("sync_interval_minutes"),
        bool(payload.get("purge_enabled", False)),
        payload.get("purge_after_interval_minutes"),
        payload.get("is_active", True),
    )
    pid = int(row["id"])
    base = await _fetch_lifecycle_policy(pid)
    uid = user.get("user_id")
    extra = await _try_provision_read_endpoints(pid, int(uid) if uid is not None else None)
    return {**base, **extra}


async def _fetch_lifecycle_policy(policy_id: int) -> Dict:
    row = await PostgresDB.fetchrow(
        """
        SELECT id, policy_label, table_name, pk_column, transfer_mode::text AS transfer_mode,
               time_column, filter_condition, destination_type::text AS destination_type,
               destination_table, archive_source_table, is_public_on_s3, lifecycle_root_table,
               movement_type::text AS movement_type,
               sync_strategy::text AS sync_strategy, sync_batch_size, sync_interval_minutes,
               purge_enabled, purge_after_interval_minutes,
               last_synced_at, last_processed_value, last_archive_completed_at, last_purge_completed_at,
               is_active, created_at, last_updated
        FROM public.data_lifecycle_policy WHERE id = $1
        """,
        policy_id,
    )
    if not row:
        raise HTTPException(status_code=404, detail="Not found")
    return dict(row)


@router.get("/{policy_id}")
async def get_lifecycle_policy(
    policy_id: int,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
    db=Depends(get_db),
):
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    return await _fetch_lifecycle_policy(policy_id)


@router.put("/{policy_id}")
async def update_policy(
    policy_id: int,
    body: DataLifecycleUpdate,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
    db=Depends(get_db),
):
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    existing = await PostgresDB.fetchrow(
        "SELECT * FROM public.data_lifecycle_policy WHERE id = $1",
        policy_id,
    )
    if not existing:
        raise HTTPException(status_code=404, detail="Not found")

    def _enum_str(v):
        if v is None:
            return None
        s = str(v)
        return s.rsplit(".", 1)[-1]

    updates = body.model_dump(exclude_unset=True)
    dest_override = updates.pop("destination_table", None)

    if not updates and dest_override is None:
        return await _fetch_lifecycle_policy(policy_id)

    if not updates and dest_override is not None:
        ex0 = dict(existing)
        tn0 = (ex0.get("table_name") or "").strip()
        dest0 = str(ex0.get("destination_type") or "").rsplit(".", 1)[-1]
        if dest0 != "iceberg":
            raise HTTPException(status_code=400, detail="destination_table is only user-overridable for iceberg")
        computed0 = compute_policy_destination_table(tn0, dest0, dest_override.strip())
        await PostgresDB.execute(
            """
            UPDATE public.data_lifecycle_policy
            SET destination_table = $1, last_updated = CURRENT_TIMESTAMP
            WHERE id = $2
            """,
            computed0,
            int(policy_id),
        )
        base = await _fetch_lifecycle_policy(policy_id)
        uid = user.get("user_id")
        extra = await _try_provision_read_endpoints(int(policy_id), int(uid) if uid is not None else None)
        return {**base, **extra}

    ex = dict(existing)
    for k, v in updates.items():
        if k == "table_name" and v is not None:
            ex[k] = str(v).strip()
        else:
            ex[k] = v

    tn = (ex.get("table_name") or "").strip()
    if not tn:
        raise HTTPException(status_code=400, detail="table_name is required")

    dest = _enum_str(ex.get("destination_type"))
    ok, err = await is_allowed_lifecycle_source(tn, dest or "")
    if not ok:
        raise HTTPException(status_code=400, detail=err)

    root = await resolve_lifecycle_root_for_source(tn)
    eff_purge = updates["purge_enabled"] if "purge_enabled" in updates else existing.get("purge_enabled")
    if eff_purge and dest in ("postgres_archive", "s3") and not root:
        raise HTTPException(
            status_code=400,
            detail="Purge requires a flat materialized source linked to a flattening root.",
        )

    if dest in ("postgres_archive", "s3"):
        computed_dest = lifecycle_destination_table(tn)
    else:
        ovr = None
        if dest_override is not None:
            ovr = (dest_override or "").strip() or None
        if not ovr:
            ovr = (ex.get("destination_table") or "").strip() or None
        computed_dest = compute_policy_destination_table(tn, dest or "iceberg", ovr)
    ex["destination_table"] = computed_dest

    merged = {
        "destination_type": dest,
        "transfer_mode": _enum_str(ex.get("transfer_mode")) or "time_based",
        "movement_type": _enum_str(ex.get("movement_type")),
        "sync_strategy": _enum_str(ex.get("sync_strategy")),
        "time_column": ex.get("time_column"),
        "filter_condition": ex.get("filter_condition"),
        "destination_table": computed_dest,
        "is_public_on_s3": ex.get("is_public_on_s3"),
        "table_name": tn,
        "purge_after_interval_minutes": ex.get("purge_after_interval_minutes"),
    }

    try:
        validate_lifecycle_row(merged)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    fields = []
    args: List[Any] = []
    idx = 1

    def add_field(col: str, val: Any, cast: Optional[str] = None):
        nonlocal idx
        if cast:
            fields.append(f"{col} = ${idx}::{cast}")
        else:
            fields.append(f"{col} = ${idx}")
        args.append(val)
        idx += 1

    if "policy_label" in updates:
        add_field("policy_label", updates["policy_label"])
    if "table_name" in updates:
        add_field("table_name", updates["table_name"].strip())
    if "pk_column" in updates:
        add_field("pk_column", updates["pk_column"])
    if "transfer_mode" in updates:
        add_field("transfer_mode", updates["transfer_mode"], "transfer_mode_enum")
    if "time_column" in updates:
        add_field("time_column", updates["time_column"])
    if "filter_condition" in updates:
        add_field("filter_condition", updates["filter_condition"])
    if "destination_type" in updates:
        add_field("destination_type", updates["destination_type"], "destination_type_enum")
    if "is_public_on_s3" in updates:
        add_field("is_public_on_s3", updates["is_public_on_s3"])
    if "movement_type" in updates:
        add_field("movement_type", updates["movement_type"], "movement_type_enum")
    if "sync_strategy" in updates:
        add_field("sync_strategy", updates["sync_strategy"], "sync_strategy_enum")
    if "sync_batch_size" in updates:
        add_field("sync_batch_size", updates["sync_batch_size"])
    if "sync_interval_minutes" in updates:
        add_field("sync_interval_minutes", updates["sync_interval_minutes"])
    if "last_synced_at" in updates:
        add_field("last_synced_at", updates["last_synced_at"])
    if "last_processed_value" in updates:
        add_field("last_processed_value", updates["last_processed_value"])
    if "is_active" in updates:
        add_field("is_active", updates["is_active"])
    if "purge_enabled" in updates:
        add_field("purge_enabled", bool(updates["purge_enabled"]))
    if "purge_after_interval_minutes" in updates:
        add_field("purge_after_interval_minutes", updates["purge_after_interval_minutes"])

    add_field("lifecycle_root_table", root)
    add_field("destination_table", computed_dest)
    fields.append("last_updated = CURRENT_TIMESTAMP")
    args.append(policy_id)
    await PostgresDB.execute(
        f"UPDATE public.data_lifecycle_policy SET {', '.join(fields)} WHERE id = ${idx}",
        *args,
    )
    base = await _fetch_lifecycle_policy(policy_id)
    uid = user.get("user_id")
    extra = await _try_provision_read_endpoints(int(policy_id), int(uid) if uid is not None else None)
    return {**base, **extra}


@router.delete("/{policy_id}")
async def delete_policy(
    policy_id: int,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
    db=Depends(get_db),
):
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    ex = await PostgresDB.fetchrow(
        "SELECT id FROM public.data_lifecycle_policy WHERE id = $1",
        policy_id,
    )
    if not ex:
        raise HTTPException(status_code=404, detail="Not found")
    await delete_lifecycle_policy_read_endpoints(int(policy_id))
    await delete_lifecycle_generated_model(int(policy_id))
    await PostgresDB.execute("DELETE FROM public.data_lifecycle_policy WHERE id = $1", policy_id)
    return {"ok": True}
