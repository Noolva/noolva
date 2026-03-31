"""
Validation and api_endpoints helpers for flattening_table_policy / flattening_relation_policy.
"""
from __future__ import annotations

import json
import logging
from typing import Any, Dict, List, Optional

logger = logging.getLogger("noolva_api.flattening_policy")

VALID_REFRESH = frozenset({"FULL", "INCREMENTAL", "VERSIONED"})


def validate_table_policy_row(row: Dict[str, Any], partial: bool = False) -> None:
    snap = row.get("is_snapshot")
    if snap is None and not partial:
        snap = True
    strat = row.get("refresh_strategy")
    if strat is not None and strat not in VALID_REFRESH:
        raise ValueError(f"refresh_strategy must be one of {sorted(VALID_REFRESH)} or null")
    if snap is True:
        if row.get("refresh_strategy") not in (None, ""):
            raise ValueError("When is_snapshot is true, refresh_strategy must be null")
        if row.get("refresh_interval_minutes") not in (None, ""):
            raise ValueError("When is_snapshot is true, refresh_interval_minutes should be null")
    else:
        if not row.get("refresh_strategy"):
            raise ValueError("Active policies (is_snapshot false) require refresh_strategy")
        if row.get("refresh_interval_minutes") in (None, ""):
            raise ValueError("Active policies require refresh_interval_minutes")


def validate_relation_row(row: Dict[str, Any], partial: bool = False) -> None:
    if not partial and not (row.get("table_name") or "").strip():
        raise ValueError("table_name is required")
    rt = row.get("relation_type")
    st = row.get("strategy")
    if rt not in ("m2o", "o2m"):
        raise ValueError("relation_type must be m2o or o2m")
    if st not in ("denormalize", "json", "separate"):
        raise ValueError("strategy must be denormalize, json, or separate")
    if rt == "m2o" and st != "denormalize":
        raise ValueError("m2o relations must use denormalize strategy")
    if rt == "o2m" and st not in ("json", "separate"):
        raise ValueError("o2m relations must use json or separate strategy")
    if st == "separate" and not (row.get("target_table") or "").strip():
        raise ValueError("target_table is required when strategy is separate")
    inc = row.get("include_fields")
    if st != "denormalize" and inc not in (None, [], ()):
        raise ValueError("include_fields is only used for denormalize; leave empty for json/separate")


def sql_due_flattening_policies() -> str:
    return """
SELECT id, table_name, refresh_strategy, refresh_interval_minutes, batch_size
FROM public.flattening_table_policy
WHERE COALESCE(is_active, true) = true
  AND is_snapshot = false
  AND refresh_strategy IS NOT NULL
  AND refresh_interval_minutes IS NOT NULL
  AND (
    last_refreshed IS NULL
    OR last_refreshed + (refresh_interval_minutes || ' minutes')::interval <= now()
)
"""


async def delete_flattening_read_endpoints(policy_id: int) -> None:
    from classes.postgres_db import PostgresDB

    await PostgresDB.execute(
        """
        DELETE FROM public.api_endpoints
        WHERE type = 'auto_crud'
          AND (custom_json->>'flattening_read_only') = 'true'
          AND (custom_json->>'flattening_table_policy_id')::int = $1
        """,
        policy_id,
    )


async def ensure_flattening_read_endpoints(policy_id: int, table_name: str, user_id: Optional[int]) -> List[str]:
    """
    Upsert GET-only auto_crud rows for the flattened model. Returns paths created/updated.
    """
    from classes.postgres_db import PostgresDB

    model = await PostgresDB.fetchrow(
        """
        SELECT model_id, model_name, table_name
        FROM public.data_models
        WHERE table_name = $1
        LIMIT 1
        """,
        table_name.strip(),
    )
    if not model:
        raise ValueError(
            f"No data_models row for table_name={table_name!r}. "
            "Create the flattened table as a Data Model in App Studio first."
        )
    model_id = int(model["model_id"])
    model_name = model["model_name"]
    ref_ids = [model_id]
    tag = {"flattening_read_only": True, "flattening_table_policy_id": policy_id}
    tag_json = json.dumps(tag)
    paths_out: List[str] = []
    specs = [
        (f"/data-models/auto/{model_name}/records", "GET"),
        (f"/data-models/auto/{model_name}/records/{{record_id}}", "GET"),
    ]
    for path, method in specs:
        await PostgresDB.execute(
            """
            INSERT INTO public.api_endpoints (
                path, method, type, related_model_id, reference_model_ids,
                custom_json, is_builtin, created_by
            ) VALUES ($1, $2, 'auto_crud', $3, $4, $5::jsonb, false, $6)
            ON CONFLICT (path, method) DO UPDATE SET
                related_model_id = EXCLUDED.related_model_id,
                reference_model_ids = EXCLUDED.reference_model_ids,
                custom_json = EXCLUDED.custom_json,
                last_updated = CURRENT_TIMESTAMP
            """,
            path,
            method,
            model_id,
            ref_ids,
            tag_json,
            user_id,
        )
        paths_out.append(f"{method} {path}")
    return paths_out
