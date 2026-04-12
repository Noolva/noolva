"""
Provision GET api_endpoints for lifecycle Postgres archive reads and Iceberg read stub rows.

Mirrors flattening read endpoint pattern (auto_crud GET only + custom_json tags).
"""
from __future__ import annotations

import json
import logging
from typing import Any, Dict, List, Optional

from classes.postgres_db import PostgresDB
from utils.data_lifecycle_sync import ensure_archive_table_like_source, lifecycle_destination_table
from utils.flattening_materializer import (
    _field_type_id_for_actual_db_type,
    _get_primary_key_column,
    _is_safe_identifier,
    _map_column_to_actual_db_type,
)

logger = logging.getLogger("noolva_api.lifecycle_read_endpoints")


async def delete_lifecycle_policy_read_endpoints(policy_id: int) -> None:
    await PostgresDB.execute(
        """
        DELETE FROM public.api_endpoints
        WHERE (custom_json->>'data_lifecycle_policy_id')::int = $1
          AND (
            (custom_json->>'lifecycle_archive_read_only') = 'true'
            OR (custom_json->>'lifecycle_iceberg_read_stub') = 'true'
          )
        """,
        int(policy_id),
    )


async def delete_lifecycle_generated_model(policy_id: int) -> None:
    await PostgresDB.execute(
        """
        DELETE FROM public.data_models
        WHERE is_system_model = TRUE
          AND model_name = $1
          AND COALESCE(description, '') LIKE $2
        """,
        f"lifecycle_archived_{int(policy_id)}",
        f"%generated_by_data_lifecycle_policy_id={int(policy_id)}%",
    )


async def _sync_fields_for_physical_table(model_id: int, physical_table: str) -> None:
    cols_meta = await PostgresDB.fetch(
        """
        SELECT column_name, data_type, udt_name, is_nullable
        FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = $1
        ORDER BY ordinal_position
        """,
        physical_table,
    )
    pk_target = await _get_primary_key_column(physical_table)
    order_row = await PostgresDB.fetchrow(
        "SELECT COALESCE(MAX(order_no), 0) AS max_order FROM public.data_model_fields WHERE model_id = $1",
        model_id,
    )
    next_order = int(order_row["max_order"] or 0) + 1

    for c in cols_meta or []:
        cn = c.get("column_name")
        if not cn or not _is_safe_identifier(cn):
            continue
        exists = await PostgresDB.fetchrow(
            "SELECT field_id FROM public.data_model_fields WHERE model_id = $1 AND field_name = $2",
            model_id,
            cn,
        )
        if exists:
            continue
        actual_db_type = _map_column_to_actual_db_type(c.get("data_type"), c.get("udt_name"))
        ft_id = await _field_type_id_for_actual_db_type(actual_db_type)
        if ft_id is None:
            ft_id = await _field_type_id_for_actual_db_type("VARCHAR")
        if ft_id is None:
            continue
        await PostgresDB.execute(
            """
            INSERT INTO public.data_model_fields (
                model_id, field_name, display_name, field_type_id, field_config_json,
                is_required, is_unique, is_primary_key, default_value, encryption_method,
                ui_component, order_no
            ) VALUES (
                $1, $2, $3, $4, '{}'::jsonb,
                $5, FALSE, $6, NULL, 'none',
                NULL, $7
            )
            """,
            model_id,
            cn,
            cn,
            int(ft_id),
            (c.get("is_nullable") == "NO" and cn != pk_target),
            (cn == pk_target),
            next_order,
        )
        next_order += 1


async def _ensure_lifecycle_archive_model(
    policy_id: int,
    physical_table: str,
    user_id: Optional[int],
) -> Dict[str, Any]:
    if not _is_safe_identifier(physical_table):
        raise ValueError(f"Invalid physical_table: {physical_table!r}")
    model_name = f"lifecycle_archived_{int(policy_id)}"
    desc = f"generated_by_data_lifecycle_policy_id={int(policy_id)}"
    model = await PostgresDB.fetchrow(
        """
        SELECT model_id, model_name, table_name
        FROM public.data_models
        WHERE model_name = $1
        LIMIT 1
        """,
        model_name,
    )
    if model:
        model_id = int(model["model_id"])
        cur_tbl = (model.get("table_name") or "").strip()
        if cur_tbl != physical_table:
            await PostgresDB.execute(
                """
                UPDATE public.data_models
                SET table_name = $1, last_updated = CURRENT_TIMESTAMP
                WHERE model_id = $2
                """,
                physical_table,
                model_id,
            )
    else:
        mrow = await PostgresDB.fetchrow(
            """
            INSERT INTO public.data_models (
                app_id, model_name, display_name, table_name, table_alias, model_scope,
                is_public, is_system_model, is_active, description, created_by
            ) VALUES (
                NULL, $1, $2, $3, NULL, 'saas',
                FALSE, TRUE, TRUE, $4, $5
            )
            RETURNING model_id
            """,
            model_name,
            f"Lifecycle archive (policy {policy_id})",
            physical_table,
            desc,
            user_id,
        )
        model_id = int(mrow["model_id"])
    await _sync_fields_for_physical_table(model_id, physical_table)
    return {"model_id": model_id, "model_name": model_name, "table_name": physical_table}


async def ensure_lifecycle_archive_read_endpoints(
    policy_id: int,
    physical_table: str,
    user_id: Optional[int],
) -> List[str]:
    m = await _ensure_lifecycle_archive_model(policy_id, physical_table, user_id)
    model_id = m["model_id"]
    model_name = m["model_name"]
    ref_ids = [model_id]
    tag = {"lifecycle_archive_read_only": True, "data_lifecycle_policy_id": int(policy_id)}
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


async def ensure_lifecycle_iceberg_stub_endpoint(
    policy_id: int,
    user_id: Optional[int],
) -> Dict[str, Any]:
    path = f"/lifecycle-policy/{int(policy_id)}/iceberg-read-stub"
    custom = {
        "lifecycle_iceberg_read_stub": True,
        "data_lifecycle_policy_id": int(policy_id),
        "query": "",
    }
    custom_json = json.dumps(custom)
    row = await PostgresDB.fetchrow(
        """
        INSERT INTO public.api_endpoints (
            path, method, type, related_model_id, reference_model_ids,
            custom_json, is_builtin, created_by
        ) VALUES ($1, 'GET', 'custom_query', NULL, $2::int[], $3::jsonb, false, $4)
        ON CONFLICT (path, method) DO UPDATE SET
            type = EXCLUDED.type,
            custom_json = EXCLUDED.custom_json,
            last_updated = CURRENT_TIMESTAMP
        RETURNING endpoint_id
        """,
        path,
        [],
        custom_json,
        user_id,
    )
    eid = int(row["endpoint_id"]) if row and row.get("endpoint_id") else None
    return {
        "endpoint_id": eid,
        "path": path,
        "method": "GET",
        "invoke_url": f"/api/data-models/custom-endpoint/{eid}" if eid else None,
        "note": "Returns 501 until Iceberg read is implemented.",
    }


async def provision_lifecycle_policy_read_endpoints(
    policy_id: int,
    policy: Dict[str, Any],
    user_id: Optional[int],
) -> Dict[str, Any]:
    """
    Replace prior lifecycle read endpoints for this policy, then create archive GET + optional Iceberg stub.
    """
    dest = str(policy.get("destination_type") or "").rsplit(".", 1)[-1]
    src = (policy.get("table_name") or "").strip()
    dest_table_str = (policy.get("destination_table") or "").strip()

    await delete_lifecycle_policy_read_endpoints(policy_id)

    archive_paths: List[str] = []
    iceberg_stub: Optional[Dict[str, Any]] = None

    if dest in ("postgres_archive", "s3"):
        archived = dest_table_str or lifecycle_destination_table(src)
        if not _is_safe_identifier(archived) or not _is_safe_identifier(src):
            raise ValueError("Invalid table_name for archive provisioning")
        await ensure_archive_table_like_source(archived, src)
        archive_paths = await ensure_lifecycle_archive_read_endpoints(policy_id, archived, user_id)
    elif dest == "iceberg":
        if not _is_safe_identifier(src):
            raise ValueError("Invalid archived source table")
        archive_paths = await ensure_lifecycle_archive_read_endpoints(policy_id, src, user_id)
        iceberg_stub = await ensure_lifecycle_iceberg_stub_endpoint(policy_id, user_id)
    else:
        raise ValueError(f"Unknown destination_type: {dest}")

    return {
        "lifecycle_archive_read_endpoints": archive_paths,
        "lifecycle_iceberg_read_stub": iceberg_stub,
    }
