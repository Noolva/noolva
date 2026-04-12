"""
Export lifecycle batches to Parquet files under ICEBERG_WAREHOUSE or LIFECYCLE_PARQUET_DIR.
Iceberg catalog registration / external table DDL is deployment-specific; read-back is future work.
Optional: append to an existing PyIceberg table if ICEBERG_SQL_CATALOG_URI and ICEBERG_APPEND_TABLE are set.
"""
from __future__ import annotations

import logging
import os
import uuid
from decimal import Decimal
from typing import Any, Dict, List, Optional, Tuple

from classes.postgres_db import PostgresDB

from utils.data_lifecycle_sync import (
    pick_eligible_pk_batch,
    quote_ident,
    validate_sql_identifier,
    _enum_tail,
)

logger = logging.getLogger("noolva_api.utils.data_lifecycle_iceberg")


def _records_for_arrow(rows: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    out: List[Dict[str, Any]] = []
    for row in rows:
        d: Dict[str, Any] = {}
        for k, v in dict(row).items():
            if isinstance(v, Decimal):
                d[k] = float(v)
            else:
                d[k] = v
        out.append(d)
    return out


async def export_archived_batch_to_parquet(
    policy: Dict[str, Any],
    src_archived_table: str,
    iceberg_table_identifier: str,
    policy_id: int,
) -> Tuple[int, Optional[Any], List[Any], str]:
    """
    Pick eligible rows from archived_* table, write Parquet slice, return count, new_lp, pk_values, file_path.
    """
    batch = max(1, int(policy.get("sync_batch_size") or 1000))
    pk_vals, pk, _qsrc = await pick_eligible_pk_batch(policy, src_archived_table, None, batch)
    if not pk_vals:
        return 0, None, [], ""

    str_vals = [str(v) for v in pk_vals]
    qtbl = quote_ident(validate_sql_identifier(src_archived_table, "source_table"))
    all_rows = await PostgresDB.fetch(
        f"""
        SELECT * FROM public.{qtbl} s
        WHERE s.{pk}::text = ANY($1::text[])
        ORDER BY s.{pk}
        """,
        str_vals,
    )
    if not all_rows:
        return 0, None, [], ""

    try:
        import pyarrow as pa
        import pyarrow.parquet as pq
    except ImportError as e:
        raise RuntimeError("pyarrow is required for Parquet export: pip install pyarrow") from e

    rec = _records_for_arrow([dict(r) for r in all_rows])
    table = pa.Table.from_pylist(rec)

    base = (os.environ.get("ICEBERG_WAREHOUSE") or os.environ.get("LIFECYCLE_PARQUET_DIR") or "").strip()
    if not base:
        base = os.path.join(os.getcwd(), "var", "iceberg_warehouse")
    safe_ns = "".join(c if c.isalnum() or c in "._-" else "_" for c in iceberg_table_identifier)
    out_dir = os.path.join(base, "data_lifecycle", f"policy_{policy_id}", safe_ns.replace(".", "_"))
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, f"export-{uuid.uuid4().hex}.parquet")
    pq.write_table(table, out_path, compression="snappy")

    mode = _enum_tail(policy.get("transfer_mode")) or "time_based"
    sync_strat = _enum_tail(policy.get("sync_strategy")) or "FULL"
    new_lp = None
    if mode in ("time_based", "time_and_condition") and sync_strat == "INCREMENTAL":
        time_col = quote_ident(validate_sql_identifier(policy.get("time_column") or "idate", "time_column"))
        mx = await PostgresDB.fetchrow(
            f"""
            SELECT MAX(s.{time_col}) AS m
            FROM public.{qtbl} s
            WHERE s.{pk}::text = ANY($1::text[])
            """,
            str_vals,
        )
        if mx and mx.get("m") is not None:
            new_lp = mx["m"]

    append_ident = (os.environ.get("ICEBERG_APPEND_TABLE") or "").strip()
    if append_ident:
        _optional_pyiceberg_append(table, append_ident, out_path)

    return len(pk_vals), new_lp, pk_vals, out_path


def _optional_pyiceberg_append(pa_table, append_ident: str, parquet_path: str) -> None:
    uri = (os.environ.get("ICEBERG_SQL_CATALOG_URI") or "").strip()
    if not uri:
        return
    try:
        from pyiceberg.catalog.sql import SqlCatalog  # type: ignore
    except ImportError:
        logger.warning("pyiceberg not installed; Parquet only at %s", parquet_path)
        return
    try:
        warehouse = os.environ.get("ICEBERG_WAREHOUSE", os.path.join(os.getcwd(), "var", "iceberg_warehouse"))
        catalog = SqlCatalog("noolva_lifecycle", **{"uri": uri, "warehouse": f"file://{warehouse}"})
        parts = append_ident.split(".")
        if len(parts) == 2:
            ns, name = parts[0], parts[1]
        else:
            ns, name = "lifecycle", parts[0]
        tbl = catalog.load_table((ns, name))
        tbl.append(pa_table)
        logger.info("PyIceberg append ok %s.%s rows=%s", ns, name, pa_table.num_rows)
    except Exception:
        logger.exception("PyIceberg append failed (table must exist); Parquet at %s", parquet_path)
