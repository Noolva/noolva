"""
Client instance offline sync: manifest/schema helpers and validation.
Sensitive: misconfiguration can expose data or allow unintended offline writes — validate strictly.
"""
from __future__ import annotations

import json
import logging
from typing import Any, Dict, List, Optional, Tuple

from classes.postgres_db import PostgresDB

logger = logging.getLogger("noolva_api.instance_offline")

VALID_SOURCE_KINDS = frozenset({"hot_auto_crud_get", "flattened_api_get", "flattened_s3"})
WRITE_METHODS = frozenset({"POST", "PUT", "PATCH", "DELETE"})


def _safe_json(obj: Any) -> Dict[str, Any]:
    if obj is None:
        return {}
    if isinstance(obj, dict):
        return obj
    if isinstance(obj, str):
        try:
            return json.loads(obj) if obj.strip() else {}
        except Exception:
            return {}
    return {}


async def resolve_instance_by_ref(instance_ref: str) -> Optional[Dict[str, Any]]:
    ref = (instance_ref or "").strip()
    if not ref:
        return None
    if ref.isdigit():
        row = await PostgresDB.fetchrow(
            """
            SELECT i.*, s.enable_offline_data, s.schema_pack_version, s.operator_notes
            FROM public.instances i
            LEFT JOIN public.instance_offline_settings s ON s.instance_id = i.instance_id
            WHERE i.instance_id = $1
            """,
            int(ref),
        )
    else:
        row = await PostgresDB.fetchrow(
            """
            SELECT i.*, s.enable_offline_data, s.schema_pack_version, s.operator_notes
            FROM public.instances i
            LEFT JOIN public.instance_offline_settings s ON s.instance_id = i.instance_id
            WHERE i.instance_uuid::text = $1 OR LOWER(i.instance_uuid::text) = LOWER($1)
            """,
            ref,
        )
    return dict(row) if row else None


def user_can_access_instance(user: Dict[str, Any], instance_row: Dict[str, Any]) -> bool:
    if not user or not instance_row:
        return False
    if user.get("is_super_admin"):
        return True
    inst_cid = instance_row.get("company_id")
    if inst_cid is None:
        return True
    uid_cid = user.get("company_id")
    if uid_cid is None:
        return False
    try:
        return int(uid_cid) == int(inst_cid)
    except (TypeError, ValueError):
        return False


async def ensure_instance_offline_settings_row(instance_id: int) -> None:
    await PostgresDB.execute(
        """
        INSERT INTO public.instance_offline_settings (instance_id)
        VALUES ($1)
        ON CONFLICT (instance_id) DO NOTHING
        """,
        instance_id,
    )


async def fetch_endpoint_row(endpoint_id: int) -> Optional[Dict[str, Any]]:
    row = await PostgresDB.fetchrow(
        """
        SELECT endpoint_id, path, method, type, related_model_id, custom_json
        FROM public.api_endpoints
        WHERE endpoint_id = $1
        """,
        endpoint_id,
    )
    return dict(row) if row else None


async def validate_write_endpoint_for_instance(endpoint_id: int) -> Tuple[bool, str]:
    row = await fetch_endpoint_row(endpoint_id)
    if not row:
        return False, "endpoint not found"
    if (row.get("type") or "").strip().lower() != "auto_crud":
        return False, "only type=auto_crud may be allowlisted for offline replay"
    method = (row.get("method") or "GET").strip().upper()
    if method not in WRITE_METHODS:
        return False, f"method must be one of {sorted(WRITE_METHODS)} for offline write allowlist"
    if row.get("related_model_id") is None:
        return False, "endpoint must have related_model_id (HOT Auto CRUD)"
    return True, ""


async def validate_dataset_row(
    source_kind: str,
    model_id: Optional[int],
    flattening_policy_id: Optional[int],
    read_endpoint_id: Optional[int],
) -> Tuple[bool, str]:
    sk = (source_kind or "").strip()
    if sk not in VALID_SOURCE_KINDS:
        return False, f"source_kind must be one of {sorted(VALID_SOURCE_KINDS)}"

    if sk == "hot_auto_crud_get":
        if not model_id:
            return False, "hot_auto_crud_get requires model_id"
        m = await PostgresDB.fetchrow(
            "SELECT model_id FROM public.data_models WHERE model_id = $1",
            int(model_id),
        )
        if not m:
            return False, "model_id not found"

    if sk == "flattened_api_get":
        if read_endpoint_id:
            er = await fetch_endpoint_row(int(read_endpoint_id))
            if not er:
                return False, "read_endpoint_id not found"
            if (er.get("method") or "").upper() != "GET":
                return False, "flattened read endpoint must be GET"
            cj = _safe_json(er.get("custom_json"))
            if not cj.get("flattening_read_only"):
                return False, "flattened_api_get read_endpoint must be a flattening read-only Auto CRUD GET route"
        elif flattening_policy_id:
            pol = await PostgresDB.fetchrow(
                """
                SELECT id, destination, table_name FROM public.flattening_table_policy
                WHERE id = $1 AND is_active IS NOT FALSE
                """,
                int(flattening_policy_id),
            )
            if not pol:
                return False, "flattening_policy_id not found"
            if (pol.get("destination") or "").lower() != "postgres":
                return False, "flattened_api_get flattening policy must have destination=postgres"
            if not model_id:
                return False, "flattened_api_get requires model_id aligned with the flattening policy table"
            dm = await PostgresDB.fetchrow(
                """
                SELECT model_id, table_name FROM public.data_models
                WHERE model_id = $1 AND is_active IS NOT FALSE
                """,
                int(model_id),
            )
            pol_tn = (pol.get("table_name") or "").strip()
            dm_tn = (dm.get("table_name") or "").strip() if dm else ""
            if not dm or pol_tn != dm_tn:
                return False, "model_id must match flattening_table_policy.table_name"
            found = await PostgresDB.fetchrow(
                """
                SELECT 1 FROM public.api_endpoints ae
                WHERE ae.type = 'auto_crud' AND UPPER(TRIM(ae.method)) = 'GET' AND ae.related_model_id = $1
                  AND (
                    ae.custom_json @> '{"flattening_read_only": true}'::jsonb
                    OR LOWER(TRIM(COALESCE(ae.custom_json->>'flattening_read_only', ''))) IN ('true', '1', 'yes')
                  )
                LIMIT 1
                """,
                int(model_id),
            )
            if not found:
                return False, "no flattening read-only GET route for this model"
        elif model_id:
            found = await PostgresDB.fetchrow(
                """
                SELECT 1 FROM public.api_endpoints ae
                WHERE ae.type = 'auto_crud' AND UPPER(TRIM(ae.method)) = 'GET' AND ae.related_model_id = $1
                  AND (
                    ae.custom_json @> '{"flattening_read_only": true}'::jsonb
                    OR LOWER(TRIM(COALESCE(ae.custom_json->>'flattening_read_only', ''))) IN ('true', '1', 'yes')
                  )
                LIMIT 1
                """,
                int(model_id),
            )
            if not found:
                return False, "flattened_api_get: no flattening GET auto_crud found for model_id; set read_endpoint_id explicitly"
        else:
            return False, "flattened_api_get requires a postgres flattening policy, model_id, or read_endpoint_id"

    if sk == "flattened_s3":
        if not flattening_policy_id:
            return False, "flattened_s3 requires flattening_policy_id"
        pol = await PostgresDB.fetchrow(
            """
            SELECT id, destination, table_name, is_public_on_s3, last_refreshed, last_processed_value, is_active
            FROM public.flattening_table_policy
            WHERE id = $1
            """,
            int(flattening_policy_id),
        )
        if not pol:
            return False, "flattening_policy_id not found"
        if (pol.get("destination") or "").lower() != "s3":
            return False, "flattened_s3 requires flattening_table_policy.destination = s3"
        if pol.get("is_public_on_s3") is None:
            return False, "flattening policy must set is_public_on_s3 for S3 export"

    return True, ""


async def _auto_crud_get_routes_for_model(model_id: int) -> List[Dict[str, Any]]:
    rows = await PostgresDB.fetch(
        """
        SELECT endpoint_id, path, method, custom_json
        FROM public.api_endpoints
        WHERE type = 'auto_crud' AND related_model_id = $1 AND method = 'GET'
        ORDER BY path
        """,
        model_id,
    )
    out = []
    for r in rows or []:
        cj = _safe_json(r.get("custom_json"))
        out.append(
            {
                "endpoint_id": r["endpoint_id"],
                "path": r["path"],
                "method": r["method"],
                "flattening_read_only": bool(cj.get("flattening_read_only")),
            }
        )
    return out


async def build_dataset_manifest_entries(
    instance_id: int,
    s3_company_id: Optional[int] = None,
) -> Tuple[List[Dict[str, Any]], List[str]]:
    """Returns (dataset_payloads, warnings).

    s3_company_id: pass the same value used for ``GET .../offline/snapshot-url`` (caller's
    company for the default S3 integration, or ``None``), so manifest ``s3_snapshot.s3_key``
    matches ``meta.s3_key`` from snapshot-url, including integrations ``bucket_prefix``.
    """
    rows = await PostgresDB.fetch(
        """
        SELECT *
        FROM public.client_offline_dataset
        WHERE instance_id = $1 AND is_active = TRUE
        ORDER BY dataset_key
        """,
        instance_id,
    )
    payloads: List[Dict[str, Any]] = []
    warnings: List[str] = []
    for row in rows or []:
        r = dict(row)
        sk = r.get("source_kind")
        entry: Dict[str, Any] = {
            "dataset_key": r["dataset_key"],
            "label": r.get("label"),
            "source_kind": sk,
            "incremental_field": r.get("incremental_field"),
            "batch_size": r.get("batch_size"),
            "local_lifecycle": _safe_json(r.get("local_lifecycle_jsonb")),
            "read": {},
            "s3_snapshot": None,
        }
        if sk == "hot_auto_crud_get" and r.get("model_id"):
            mid = int(r["model_id"])
            model = await PostgresDB.fetchrow(
                "SELECT model_id, model_name, table_name, display_name FROM public.data_models WHERE model_id = $1",
                mid,
            )
            if not model:
                warnings.append(f"dataset {r['dataset_key']}: model_id {mid} missing")
                continue
            entry["model"] = {
                "model_id": model["model_id"],
                "model_name": model["model_name"],
                "table_name": model["table_name"],
                "display_name": model.get("display_name"),
            }
            entry["read"]["get_routes"] = await _auto_crud_get_routes_for_model(mid)
        elif sk == "flattened_api_get":
            if r.get("read_endpoint_id"):
                er = await fetch_endpoint_row(int(r["read_endpoint_id"]))
                if er:
                    entry["read"]["get_routes"] = [
                        {
                            "endpoint_id": er["endpoint_id"],
                            "path": er["path"],
                            "method": er["method"],
                            "flattening_read_only": True,
                        }
                    ]
            elif r.get("model_id"):
                mid = int(r["model_id"])
                gr = await _auto_crud_get_routes_for_model(mid)
                flat = [x for x in gr if x.get("flattening_read_only")]
                entry["read"]["get_routes"] = flat
        elif sk == "flattened_s3" and r.get("flattening_policy_id"):
            pol = await PostgresDB.fetchrow(
                """
                SELECT id, table_name, destination, is_public_on_s3, last_refreshed, last_processed_value, is_active
                FROM public.flattening_table_policy
                WHERE id = $1
                """,
                int(r["flattening_policy_id"]),
            )
            if pol and (pol.get("destination") or "").lower() == "s3":
                tn = (pol.get("table_name") or "").strip()
                is_pub = bool(pol.get("is_public_on_s3"))
                prefix = "public" if is_pub else "private"
                logical_key = f"{prefix}/flattened/{tn}.json"
                full_s3_key = logical_key
                try:
                    from routes.upload import _get_default_s3_service

                    s3_svc = await _get_default_s3_service(s3_company_id)
                    full_s3_key = s3_svc._build_s3_key(logical_key)
                except Exception as ex:
                    logger.warning(
                        "build_dataset_manifest_entries: full s3_key for dataset %s instance_id=%s: %s",
                        r.get("dataset_key"),
                        instance_id,
                        ex,
                    )
                    warnings.append(
                        f"dataset {r['dataset_key']}: manifest s3_key is logical path only "
                        f"(could not apply bucket prefix: {ex!s})"
                    )
                entry["s3_snapshot"] = {
                    "flattening_policy_id": pol["id"],
                    "table_name": tn,
                    "s3_key": full_s3_key,
                    "is_public_on_s3": is_pub,
                    "watermark": {
                        "last_refreshed": pol["last_refreshed"].isoformat() if pol.get("last_refreshed") else None,
                        "last_processed_value": pol["last_processed_value"].isoformat()
                        if pol.get("last_processed_value")
                        else None,
                    },
                }
        payloads.append(entry)
    return payloads, warnings


async def build_offline_write_endpoints_manifest(instance_id: int) -> List[Dict[str, Any]]:
    rows = await PostgresDB.fetch(
        """
        SELECT w.id, w.endpoint_id, w.notes, w.is_active,
               ae.path, ae.method, ae.related_model_id,
               dm.model_name, dm.table_name
        FROM public.client_offline_write_endpoint w
        JOIN public.api_endpoints ae ON ae.endpoint_id = w.endpoint_id
        LEFT JOIN public.data_models dm ON dm.model_id = ae.related_model_id
        WHERE w.instance_id = $1 AND w.is_active = TRUE
        ORDER BY ae.path, ae.method
        """,
        instance_id,
    )
    out = []
    for r in rows or []:
        out.append(
            {
                "allowlist_row_id": r["id"],
                "endpoint_id": r["endpoint_id"],
                "path": r["path"],
                "method": (r.get("method") or "").upper(),
                "related_model_id": r.get("related_model_id"),
                "model_name": r.get("model_name"),
                "table_name": r.get("table_name"),
                "notes": r.get("notes"),
                "offline_write_allowed": True,
            }
        )
    return out


async def build_schema_pack_for_instance(instance_id: int) -> Dict[str, Any]:
    """Collect models referenced by datasets and write endpoints; return field metadata for SQLite DDL hints."""
    model_ids: set = set()
    drows = await PostgresDB.fetch(
        "SELECT model_id, source_kind FROM public.client_offline_dataset WHERE instance_id = $1 AND is_active = TRUE",
        instance_id,
    )
    for dr in drows or []:
        if dr.get("model_id"):
            model_ids.add(int(dr["model_id"]))
    wrows = await PostgresDB.fetch(
        """
        SELECT ae.related_model_id
        FROM public.client_offline_write_endpoint w
        JOIN public.api_endpoints ae ON ae.endpoint_id = w.endpoint_id
        WHERE w.instance_id = $1 AND w.is_active = TRUE AND ae.related_model_id IS NOT NULL
        """,
        instance_id,
    )
    for wr in wrows or []:
        model_ids.add(int(wr["related_model_id"]))

    tables: List[Dict[str, Any]] = []
    for mid in sorted(model_ids):
        model = await PostgresDB.fetchrow(
            """
            SELECT model_id, model_name, table_name, display_name
            FROM public.data_models WHERE model_id = $1
            """,
            mid,
        )
        if not model:
            continue
        fields = await PostgresDB.fetch(
            """
            SELECT dmf.field_name, dmf.display_name, dmf.is_required, dmf.order_no,
                   ft.type_code, ft.actual_db_type
            FROM public.data_model_fields dmf
            JOIN public.field_types ft ON ft.field_type_id = dmf.field_type_id
            WHERE dmf.model_id = $1
            ORDER BY dmf.order_no NULLS LAST, dmf.field_name
            """,
            mid,
        )
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
            model["table_name"],
        )
        pk = pk_row["column_name"] if pk_row else "id"
        tables.append(
            {
                "model_id": model["model_id"],
                "model_name": model["model_name"],
                "physical_table": model["table_name"],
                "display_name": model.get("display_name"),
                "primary_key_column": pk,
                "fields": [
                    {
                        "field_name": f["field_name"],
                        "display_name": f.get("display_name"),
                        "type_code": f.get("type_code"),
                        "actual_db_type": f.get("actual_db_type"),
                        "is_required": bool(f.get("is_required")),
                    }
                    for f in (fields or [])
                ],
            }
        )
    return {"models": tables}


async def snapshot_url_for_dataset(
    instance_id: int, dataset_key: str, user_company_id: Optional[int]
) -> Tuple[Optional[str], Optional[str], Optional[Dict[str, Any]], str]:
    """
    Returns (public_url, presigned_url_or_none, meta_dict, error_message).
    For private S3, returns presigned URL string in second position; public_url may still be set from config.
    """
    row = await PostgresDB.fetchrow(
        """
        SELECT d.* FROM public.client_offline_dataset d
        WHERE d.instance_id = $1 AND d.dataset_key = $2 AND d.is_active = TRUE
        """,
        instance_id,
        dataset_key.strip(),
    )
    if not row:
        return None, None, None, "dataset not found"
    if row.get("source_kind") != "flattened_s3":
        return None, None, None, "dataset is not flattened_s3"
    pol = await PostgresDB.fetchrow(
        """
        SELECT table_name, destination, is_public_on_s3, last_refreshed, last_processed_value
        FROM public.flattening_table_policy
        WHERE id = $1
        """,
        int(row["flattening_policy_id"]),
    )
    if not pol or (pol.get("destination") or "").lower() != "s3":
        return None, None, None, "invalid flattening policy for S3"

    from urllib.parse import urljoin

    from routes.upload import _get_default_s3_service

    s3 = await _get_default_s3_service(user_company_id)
    tn = (pol.get("table_name") or "").strip()
    is_pub = bool(pol.get("is_public_on_s3"))
    prefix = "public" if is_pub else "private"
    logical_key = f"{prefix}/flattened/{tn}.json"
    full_s3_key = s3._build_s3_key(logical_key) if hasattr(s3, "_build_s3_key") else logical_key
    meta = {
        "s3_key": full_s3_key,
        "is_public_on_s3": is_pub,
        "watermark": {
            "last_refreshed": pol["last_refreshed"].isoformat() if pol.get("last_refreshed") else None,
            "last_processed_value": pol["last_processed_value"].isoformat()
            if pol.get("last_processed_value")
            else None,
        },
    }
    if is_pub:
        if s3.cdn_url:
            pub = urljoin(s3.cdn_url.rstrip("/") + "/", full_s3_key)
        elif s3.endpoint_url:
            pub = urljoin(s3.endpoint_url.rstrip("/") + "/", f"{s3.bucket_name}/{full_s3_key}")
        else:
            pub = f"https://{s3.bucket_name}.s3.{s3.region}.amazonaws.com/{full_s3_key}"
        return pub, None, meta, ""

    presigned = s3.generate_presigned_url(logical_key)
    return None, presigned, meta, "" if presigned else "could not generate presigned URL"
