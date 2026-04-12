"""
Developer Console — data_lifecycle_policy CRUD.
"""
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from middlewares.auth import verify_jwt_token
from utils.db import get_db
from classes.postgres_db import PostgresDB
from utils.data_lifecycle_policy import validate_lifecycle_row

router = APIRouter(prefix="/dev-console/data-lifecycle-policies", tags=["Developer Console - Data Lifecycle"])


class DataLifecycleCreate(BaseModel):
    policy_label: Optional[str] = None
    table_name: str
    pk_column: str = "id"
    transfer_mode: str = "time_based"
    time_column: Optional[str] = None
    filter_condition: Optional[str] = None
    destination_type: str
    destination_table: Optional[str] = None
    is_public_on_s3: Optional[bool] = None
    movement_type: str
    sync_strategy: str
    sync_batch_size: int = 1000
    sync_interval_minutes: Optional[int] = None
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
    is_public_on_s3: Optional[bool] = None
    movement_type: Optional[str] = None
    sync_strategy: Optional[str] = None
    sync_batch_size: Optional[int] = None
    sync_interval_minutes: Optional[int] = None
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
               destination_table, is_public_on_s3, movement_type::text AS movement_type,
               sync_strategy::text AS sync_strategy, sync_batch_size, sync_interval_minutes,
               last_synced_at, last_processed_value, is_active, created_at, last_updated
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
    try:
        validate_lifecycle_row(payload)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    row = await PostgresDB.fetchrow(
        """
        INSERT INTO public.data_lifecycle_policy (
            policy_label, table_name, pk_column, transfer_mode, time_column, filter_condition,
            destination_type, destination_table, is_public_on_s3, movement_type, sync_strategy,
            sync_batch_size, sync_interval_minutes, is_active
        ) VALUES (
            $1, $2, $3, $4::transfer_mode_enum, $5, $6,
            $7::destination_type_enum, $8, $9, $10::movement_type_enum, $11::sync_strategy_enum,
            $12, $13, $14
        )
        RETURNING id
        """,
        payload.get("policy_label"),
        payload["table_name"].strip(),
        payload.get("pk_column") or "id",
        payload.get("transfer_mode") or "time_based",
        payload.get("time_column"),
        payload.get("filter_condition"),
        payload["destination_type"],
        payload.get("destination_table"),
        payload.get("is_public_on_s3"),
        payload["movement_type"],
        payload["sync_strategy"],
        payload.get("sync_batch_size") or 1000,
        payload.get("sync_interval_minutes"),
        payload.get("is_active", True),
    )
    return await _fetch_lifecycle_policy(int(row["id"]))


async def _fetch_lifecycle_policy(policy_id: int) -> Dict:
    row = await PostgresDB.fetchrow(
        """
        SELECT id, policy_label, table_name, pk_column, transfer_mode::text AS transfer_mode,
               time_column, filter_condition, destination_type::text AS destination_type,
               destination_table, is_public_on_s3, movement_type::text AS movement_type,
               sync_strategy::text AS sync_strategy, sync_batch_size, sync_interval_minutes,
               last_synced_at, last_processed_value, is_active, created_at, last_updated
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

    ex = dict(existing)
    for k, v in body.model_dump(exclude_unset=True).items():
        ex[k] = v
    merged = {
        "destination_type": _enum_str(ex.get("destination_type")),
        "transfer_mode": _enum_str(ex.get("transfer_mode")) or "time_based",
        "movement_type": _enum_str(ex.get("movement_type")),
        "sync_strategy": _enum_str(ex.get("sync_strategy")),
        "time_column": ex.get("time_column"),
        "filter_condition": ex.get("filter_condition"),
        "destination_table": ex.get("destination_table"),
        "is_public_on_s3": ex.get("is_public_on_s3"),
        "table_name": (ex.get("table_name") or "").strip(),
    }

    try:
        validate_lifecycle_row(merged)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    updates = body.model_dump(exclude_unset=True)
    if not updates:
        return await _fetch_lifecycle_policy(policy_id)
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
    if "destination_table" in updates:
        add_field("destination_table", updates["destination_table"])
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

    fields.append("last_updated = CURRENT_TIMESTAMP")
    args.append(policy_id)
    await PostgresDB.execute(
        f"UPDATE public.data_lifecycle_policy SET {', '.join(fields)} WHERE id = ${idx}",
        *args,
    )
    return await _fetch_lifecycle_policy(policy_id)


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
    await PostgresDB.execute("DELETE FROM public.data_lifecycle_policy WHERE id = $1", policy_id)
    return {"ok": True}
