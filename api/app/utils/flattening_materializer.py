import re
from typing import Any, Dict, List, Optional, Tuple

from classes.postgres_db import PostgresDB

_SAFE_IDENTIFIER_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


def _is_safe_identifier(value: str) -> bool:
    return bool(_SAFE_IDENTIFIER_RE.fullmatch(value or ""))


def _aliasize(value: str) -> str:
    v = re.sub(r"[^A-Za-z0-9_]+", "_", value or "").strip("_")
    if not v:
        v = "rel"
    if not re.match(r"^[A-Za-z_]", v):
        v = f"r_{v}"
    return v


async def _get_primary_key_column(table_name: str) -> str:
    row = await PostgresDB.fetchrow(
        """
        SELECT kcu.column_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu
          ON tc.constraint_name = kcu.constraint_name
         AND tc.table_schema = kcu.table_schema
        WHERE tc.table_schema = 'public'
          AND tc.table_name = $1
          AND tc.constraint_type = 'PRIMARY KEY'
        ORDER BY kcu.ordinal_position
        LIMIT 1
        """,
        table_name,
    )
    return (row["column_name"] if row and row.get("column_name") else "id")


async def _get_table_columns(table_name: str) -> List[str]:
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


async def _resolve_fk_target(source_table: str, fk_column: str) -> Tuple[Optional[str], Optional[str]]:
    row = await PostgresDB.fetchrow(
        """
        SELECT
          ccu.table_name AS ref_table,
          ccu.column_name AS ref_column
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
          AND kcu.column_name = $2
        LIMIT 1
        """,
        source_table,
        fk_column,
    )
    if not row:
        return None, None
    return row.get("ref_table"), row.get("ref_column")


async def _field_type_id_for_actual_db_type(actual_db_type: str) -> Optional[int]:
    row = await PostgresDB.fetchrow(
        """
        SELECT field_type_id
        FROM public.field_types
        WHERE actual_db_type = $1 AND is_active = TRUE
        ORDER BY field_type_id
        LIMIT 1
        """,
        actual_db_type,
    )
    return int(row["field_type_id"]) if row and row.get("field_type_id") else None


def _map_column_to_actual_db_type(data_type: str, udt_name: str) -> str:
    dt = (data_type or "").lower()
    udt = (udt_name or "").lower()
    if udt in ("int2", "int4"):
        return "INTEGER"
    if udt in ("int8",):
        return "NUMERIC"
    if udt in ("numeric",):
        return "NUMERIC"
    if udt in ("bool",):
        return "BOOLEAN"
    if udt in ("timestamptz",):
        return "TIMESTAMPTZ"
    if udt in ("timestamp",):
        return "TIMESTAMPTZ"
    if udt in ("date",):
        return "DATE"
    if udt in ("jsonb",):
        return "JSONB"
    if udt in ("uuid",):
        return "UUID"
    if dt in ("character varying", "varchar"):
        return "VARCHAR"
    if dt in ("text",):
        return "TEXT"
    return "VARCHAR"


async def ensure_flattened_table_and_model(
    *,
    policy_id: int,
    source_table: str,
    target_table: str,
    created_by: Optional[int],
) -> Dict[str, Any]:
    """
    Create/adjust the flattened physical table and ensure a Data Model exists for it.
    Called from policy create/update and relation CRUD (not from job execution).
    """
    st = (source_table or "").strip()
    tt = (target_table or "").strip()
    if not _is_safe_identifier(st):
        raise ValueError(f"Unsafe source_table: {st!r}")
    if not _is_safe_identifier(tt):
        raise ValueError(f"Unsafe target_table: {tt!r}")

    pk_col = await _get_primary_key_column(st)
    if not _is_safe_identifier(pk_col):
        raise ValueError(f"Unsafe pk column: {pk_col!r}")

    # Ensure target table exists (base schema)
    await PostgresDB.execute(
        f'CREATE TABLE IF NOT EXISTS public."{tt}" (LIKE public."{st}" INCLUDING DEFAULTS INCLUDING CONSTRAINTS)'
    )

    # Apply relation-driven columns (additive)
    rel_rows = await PostgresDB.fetch(
        """
        SELECT relation_name, relation_type, strategy, include_fields
        FROM public.flattening_relation_policy
        WHERE table_name = $1
        ORDER BY id
        """,
        st,
    )

    for rr in rel_rows or []:
        rel_name = (rr.get("relation_name") or "").strip()
        rtype = (rr.get("relation_type") or "").strip().lower()
        strategy = (rr.get("strategy") or "").strip().lower()
        include_fields = rr.get("include_fields") or []
        if isinstance(include_fields, str):
            include_fields = [x.strip() for x in include_fields.split(",") if x.strip()]
        if not isinstance(include_fields, list):
            include_fields = []

        if rtype == "m2o" and strategy == "denormalize":
            fk_col = rel_name
            if not _is_safe_identifier(fk_col):
                continue
            ref_table, _ref_col = await _resolve_fk_target(st, fk_col)
            if not ref_table or not _is_safe_identifier(ref_table):
                continue
            ref_cols = await _get_table_columns(ref_table)
            for f in include_fields:
                if not _is_safe_identifier(f) or f not in ref_cols:
                    continue
                out_col = _aliasize(f"{fk_col}__{f}")
                await PostgresDB.execute(f'ALTER TABLE public."{tt}" ADD COLUMN IF NOT EXISTS "{out_col}" TEXT')

        if rtype == "o2m" and strategy in ("json", "separate"):
            if "." not in rel_name:
                continue
            child_table, _child_fk = rel_name.split(".", 1)
            child_table = child_table.strip()
            if not _is_safe_identifier(child_table):
                continue
            out_col = _aliasize(f"{child_table}_items")
            await PostgresDB.execute(f'ALTER TABLE public."{tt}" ADD COLUMN IF NOT EXISTS "{out_col}" JSONB')

    # Ensure data_models row exists for target table
    model_name = _aliasize(f"flattened_{st}")
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
            f"Flattened {st}",
            tt,
            f"generated_by_flattening_table_policy_id={int(policy_id)}",
            created_by,
        )
        model_id = int(mrow["model_id"])

    # Ensure data_model_fields exist for all columns present on target table
    cols_meta = await PostgresDB.fetch(
        """
        SELECT column_name, data_type, udt_name, is_nullable
        FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = $1
        ORDER BY ordinal_position
        """,
        tt,
    )
    pk_target = await _get_primary_key_column(tt)
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

    return {"ok": True, "model_id": model_id, "model_name": model_name, "table_name": tt, "pk": pk_col}


async def delete_flattened_table_and_model(*, policy_id: int, target_table: str) -> None:
    tt = (target_table or "").strip()
    if not _is_safe_identifier(tt):
        return

    # Delete model only if it was generated for this policy
    model = await PostgresDB.fetchrow(
        """
        SELECT model_id
        FROM public.data_models
        WHERE is_system_model = TRUE
          AND COALESCE(description,'') LIKE $1
        LIMIT 1
        """,
        f"%generated_by_flattening_table_policy_id={int(policy_id)}%",
    )
    if model and model.get("model_id"):
        await PostgresDB.execute("DELETE FROM public.data_models WHERE model_id = $1", int(model["model_id"]))

    await PostgresDB.execute(f'DROP TABLE IF EXISTS public."{tt}" CASCADE')

