"""
Data Models Routes
Provides CRUD operations for data_models and data_model_fields
"""

from fastapi import APIRouter, Depends, HTTPException, Query, Header, Request
from pydantic import BaseModel
from typing import Any, Dict, List, Optional, Tuple
from middlewares.auth import verify_jwt_token, resolve_bearer_to_user
from utils.db import get_db
from classes.postgres_db import PostgresDB
from datetime import datetime, date
import json
import re
import uuid
import time
import logging

from utils import field_encryption

router = APIRouter()
logger = logging.getLogger("noolva_api")

# Action mask bits (shared convention)
ACTION_READ = 1
ACTION_WRITE = 2
ACTION_UPDATE = 4
ACTION_DELETE = 8


def _is_safe_identifier(value: str) -> bool:
    return bool(re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", value or ""))


async def _get_user_role_ids(user_id: int, company_id: Optional[int]) -> List[int]:
    """
    Match the same role resolution logic used by MenuService.
    """
    role_rows = await PostgresDB.fetch(
        """
        SELECT DISTINCT r.role_id
        FROM public.user_roles ur
        JOIN public.roles r ON ur.role_id = r.role_id
        WHERE ur.user_id = $1
          AND (ur.company_id = $2 OR ur.company_id IS NULL OR $2 IS NULL)
        """,
        user_id,
        company_id,
    )
    return [r["role_id"] for r in role_rows] if role_rows else []


async def _get_model_by_name(model_name: str) -> Optional[Dict[str, Any]]:
    if not _is_safe_identifier(model_name):
        return None
    return await PostgresDB.fetchrow(
        """
        SELECT model_id, model_name, table_name, table_alias, model_scope,
               is_public, is_system_model, is_active
        FROM public.data_models
        WHERE model_name = $1 AND is_active = TRUE
        """,
        model_name,
    )


async def _get_model_fields_meta(model_id: int) -> List[Dict[str, Any]]:
    return await PostgresDB.fetch(
        """
        SELECT dmf.field_name, dmf.encryption_method, dmf.order_no,
               ft.type_code, ft.actual_db_type
        FROM public.data_model_fields dmf
        LEFT JOIN public.field_types ft ON dmf.field_type_id = ft.field_type_id
        WHERE dmf.model_id = $1
        ORDER BY dmf.order_no, dmf.field_name
        """,
        model_id,
    )


async def _get_field_permission_masks(model_id: int, role_ids: List[int]) -> Dict[str, int]:
    """
    Returns field_name -> OR-ed action_mask across the user's roles.
    """
    if not role_ids:
        return {}
    rows = await PostgresDB.fetch(
        """
        SELECT field_name, action_mask
        FROM public.field_permissions
        WHERE model_id = $1 AND role_id = ANY($2::int[])
        """,
        model_id,
        role_ids,
    )
    masks: Dict[str, int] = {}
    for r in rows or []:
        name = r["field_name"]
        masks[name] = (masks.get(name, 0) | (r.get("action_mask") or 0))
    return masks


async def _get_row_access_policies(model_id: int, action_bit: int) -> List[Dict[str, Any]]:
    return await PostgresDB.fetch(
        """
        SELECT id, action_mask, scope_field, scope_source, required, user_override
        FROM public.model_row_access_policies
        WHERE model_id = $1 AND (action_mask & $2) <> 0
        ORDER BY id
        """,
        model_id,
        action_bit,
    )


def _resolve_auth_scope_values(user: Dict[str, Any], scope_field: str) -> List[Any]:
    """
    Try several common auth-context key patterns:
    - scope_field (company_id)
    - user_{scope_field} (user_company_id)
    - user_allowed_{scope_field}s (user_allowed_company_ids)
    - {scope_field}s (company_ids)
    """
    if not user:
        return []
    candidates = [
        scope_field,
        f"user_{scope_field}",
        f"user_allowed_{scope_field}s",
        f"{scope_field}s",
    ]
    for key in candidates:
        if key in user and user[key] is not None:
            val = user[key]
            if isinstance(val, list):
                return val
            return [val]
    return []


def _coerce_value_for_db(type_code: Optional[str], actual_db_type: Optional[str], value: Any) -> Any:
    """
    Coerce string values to date/datetime/time for asyncpg (expects Python types for DATE/TIMESTAMPTZ/TIME).
    For file/image fields, accept list of paths (multiple) and store as JSON array string.
    When type_code/actual_db_type are missing (e.g. field not in data_model_fields), still try
    to parse ISO date strings so DATE columns don't get raw strings (asyncpg: 'str' has no 'toordinal').
    """
    if value is None:
        return value
    type_code = (type_code or "").strip().lower()
    if type_code in ("file", "image") and isinstance(value, list):
        return json.dumps([str(x).strip() for x in value if x is not None and str(x).strip()])
    if not isinstance(value, str):
        return value
    actual_db_type = (actual_db_type or "").upper()
    try:
        s = value.strip()
        if type_code == "date" or actual_db_type == "DATE":
            return datetime.strptime(s[:10], "%Y-%m-%d").date()
        if type_code == "datetime" or "TIMESTAMP" in actual_db_type or actual_db_type == "TIMESTAMPTZ":
            if len(s) <= 10:
                return datetime.strptime(s, "%Y-%m-%d").date()
            dt = datetime.fromisoformat(s.replace("Z", "+00:00"))
            return dt
        if type_code == "time" or actual_db_type == "TIME":
            # asyncpg expects datetime.time for TIME columns (not str; 'str' has no 'hour')
            if re.match(r"^\d{1,2}:\d{1,2}(:\d{1,2})?$", s):
                if s.count(":") == 2:
                    return datetime.strptime(s, "%H:%M:%S").time()
                return datetime.strptime(s, "%H:%M").time()
        # Fallback: no type meta (e.g. LEFT JOIN null) but value looks like ISO date -> coerce for DATE columns
        if len(s) >= 10 and s[4] == "-" and s[7] == "-" and re.match(r"^\d{4}-\d{2}-\d{2}", s):
            return datetime.strptime(s[:10], "%Y-%m-%d").date()
    except (ValueError, TypeError):
        pass
    return value


def _coerce_filter_value(
    field_name: str,
    raw_value: Any,
    field_type_map: Dict[str, Tuple[Optional[str], Optional[str]]],
) -> Any:
    """
    Coerce a filter value (e.g. from query param or POST body) for use in WHERE clause.
    Handles integer, UUID, date/datetime, and leaves the rest to the DB.
    """
    if raw_value is None or (isinstance(raw_value, str) and raw_value.strip() == ""):
        return None
    tc, db_type = field_type_map.get(field_name, (None, None))
    type_code = (tc or "").strip().lower()
    actual_db_type = (db_type or "").upper()
    if actual_db_type in ("INTEGER", "BIGINT", "SMALLINT", "SERIAL", "BIGSERIAL"):
        try:
            return int(raw_value)
        except (ValueError, TypeError):
            return raw_value
    if actual_db_type == "UUID" or type_code == "auto_uuid":
        try:
            s = str(raw_value).strip()
            return uuid.UUID(s) if s else None
        except (ValueError, TypeError, AttributeError):
            return raw_value
    return _coerce_value_for_db(tc, db_type, raw_value)


def _normalize_user_values(raw: Any) -> List[str]:
    if raw is None:
        return []
    if isinstance(raw, list):
        vals = raw
    else:
        vals = str(raw).split(",")
    return [str(v).strip() for v in vals if str(v).strip() != ""]


def _infer_array_type(values: List[str]) -> Tuple[str, List[Any]]:
    """
    Returns ("int" or "text", coerced_values)
    """
    if not values:
        return ("text", [])
    all_int = True
    coerced: List[Any] = []
    for v in values:
        if re.fullmatch(r"-?\d+", v):
            coerced.append(int(v))
        else:
            all_int = False
            coerced.append(v)
    return ("int" if all_int else "text", coerced)


async def _get_primary_key_column(table_name: str) -> Optional[str]:
    if not _is_safe_identifier(table_name):
        return None
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
    return (row or {}).get("column_name")


def _looks_like_uuid(value: str) -> bool:
    """Return True if value looks like a UUID string."""
    if not value or not isinstance(value, str):
        return False
    return bool(re.fullmatch(r"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}", value.strip()))


async def _resolve_record_id_column_and_value(table_name: str, record_id: str) -> Tuple[Optional[str], Any]:
    """
    Resolve (column_name, value) for WHERE clause when looking up by record_id.
    Supports both integer PK and UUID: if record_id looks like UUID and table has a uuid column, use it; else use PK.
    """
    if not _is_safe_identifier(table_name) or not record_id:
        return (None, None)
    pk_col = await _get_primary_key_column(table_name)
    if not pk_col:
        return (None, None)
    record_id = record_id.strip()
    if _looks_like_uuid(record_id):
        uuid_cols = await PostgresDB.fetch(
            """
            SELECT column_name FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = $1 AND data_type = 'uuid'
            ORDER BY column_name
            """,
            table_name,
        )
        if uuid_cols:
            col = (uuid_cols[0] or {}).get("column_name")
            if col:
                return (col, record_id)
    pk_type_row = await PostgresDB.fetchrow(
        """
        SELECT data_type FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = $1 AND column_name = $2
        """,
        table_name,
        pk_col,
    )
    data_type = (pk_type_row or {}).get("data_type", "")
    if data_type in ("integer", "bigint", "smallint", "serial", "bigserial"):
        try:
            return (pk_col, int(record_id))
        except ValueError:
            return (pk_col, record_id)
    return (pk_col, record_id)


class DataModelFieldCreate(BaseModel):
    field_name: str
    display_name: Optional[str] = None
    field_type_id: int
    field_config_json: Optional[Dict[str, Any]] = {}
    is_required: bool = False
    is_unique: bool = False
    is_primary_key: bool = False
    default_value: Optional[str] = None
    encryption_method: str = "none"
    ui_component: Optional[str] = None
    order_no: int = 0


class DataModelFieldUpdate(BaseModel):
    display_name: Optional[str] = None
    field_type_id: Optional[int] = None
    field_config_json: Optional[Dict[str, Any]] = None
    is_required: Optional[bool] = None
    is_unique: Optional[bool] = None
    is_primary_key: Optional[bool] = None
    default_value: Optional[str] = None
    encryption_method: Optional[str] = None
    ui_component: Optional[str] = None
    order_no: Optional[int] = None


class DataModelCreate(BaseModel):
    app_id: Optional[int] = None
    model_name: str
    display_name: Optional[str] = None
    table_name: str
    table_alias: Optional[str] = None
    model_scope: str = "saas"
    is_public: bool = False
    is_system_model: bool = False
    is_active: bool = True
    description: Optional[str] = None
    id_field_name: Optional[str] = "id"  # ID field name for the primary key
    id_field_type_code: Optional[str] = "auto_number"  # 'auto_number' (SERIAL) or 'auto_uuid' (UUID)
    fields: Optional[List[DataModelFieldCreate]] = []


class DataModelUpdate(BaseModel):
    display_name: Optional[str] = None
    model_name: Optional[str] = None
    table_name: Optional[str] = None
    table_alias: Optional[str] = None
    model_scope: Optional[str] = None
    is_public: Optional[bool] = None
    is_system_model: Optional[bool] = None
    is_active: Optional[bool] = None
    description: Optional[str] = None


class TableModificationRequest(BaseModel):
    confirm: bool = False
    changes: List[Dict[str, Any]]  # List of ALTER TABLE changes


@router.get("/field-types/list")
async def get_field_types(
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"])),
    db=Depends(get_db),
):
    """
    Get list of available field types.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    try:
        field_types = await PostgresDB.fetch(
            """
            SELECT 
                field_type_id, type_name, type_code, category,
                actual_db_type, default_component_type_id, default_props_json,
                icon, input_type_image, is_active, order_no
            FROM public.field_types
            WHERE is_active = TRUE
            ORDER BY order_no ASC NULLS LAST, category, type_name
            """
        )
        
        return {"field_types": [dict(ft) for ft in field_types] if field_types else []}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch field types: {str(e)}")


@router.get("/list")
async def get_data_models(
    app_id: Optional[int] = Query(None, description="Filter by app_id"),
    limit: int = Query(500, ge=1, le=500, description="Max models per call (max 500)"),
    offset: int = Query(0, ge=0, description="Pagination offset"),
    search: Optional[str] = Query(None, description="Search across model_name, display_name, table_name"),
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"])),
    db=Depends(get_db),
):
    """
    Get all data models, optionally filtered by app_id.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    try:
        t0 = time.perf_counter()
        logger.info(
            "data-models.list start user=%s app_id=%s limit=%s offset=%s search=%s",
            user.get("username"),
            app_id,
            limit,
            offset,
            bool(search),
        )

        where = []
        params: List[Any] = []

        if app_id is not None:
            where.append(f"dm.app_id = ${len(params) + 1}")
            params.append(app_id)

        if search:
            where.append(
                f"""(
                    dm.model_name ILIKE ${len(params) + 1}
                    OR COALESCE(dm.display_name, '') ILIKE ${len(params) + 1}
                    OR dm.table_name ILIKE ${len(params) + 1}
                )"""
            )
            params.append(f"%{search}%")

        where_sql = (" WHERE " + " AND ".join(where)) if where else ""

        # IMPORTANT: Avoid COUNT(*) on large tables (can hang).
        # Use limit+1 technique to determine has_more, and compute field_count only for returned model_ids.
        page_limit = min(limit + 1, 501)

        # NOTE: ordering by model_name can be very slow without a supporting index.
        # We order by model_id (PK) for reliability; the admin UI can sort client-side by name.
        query = f"""
            SELECT
                dm.model_id, dm.model_uuid, dm.app_id, dm.model_name, dm.display_name,
                dm.table_name, dm.table_alias, dm.model_scope, dm.is_public, dm.is_system_model,
                dm.is_active, dm.description,
                dm.created_by, dm.idate, dm.last_updated
            FROM public.data_models dm
            {where_sql}
            ORDER BY dm.model_id
            LIMIT ${len(params) + 1} OFFSET ${len(params) + 2}
        """

        t1 = time.perf_counter()
        logger.info(
            "data-models.list page query start page_limit=%s offset=%s",
            page_limit,
            offset,
        )
        models = await PostgresDB.fetch(query, *params, page_limit, offset)
        t2 = time.perf_counter()

        data = [dict(m) for m in models] if models else []
        has_more = len(data) > limit
        if has_more:
            data = data[:limit]

        # Field counts for just this page
        model_ids = [m["model_id"] for m in data]
        field_count_map: Dict[int, int] = {}
        if model_ids:
            rows = await PostgresDB.fetch(
                """
                SELECT model_id, COUNT(*)::int AS field_count
                FROM public.data_model_fields
                WHERE model_id = ANY($1::int[])
                GROUP BY model_id
                """,
                model_ids,
            )
            for r in rows or []:
                field_count_map[r["model_id"]] = r.get("field_count") or 0

        for m in data:
            m["field_count"] = field_count_map.get(m["model_id"], 0)

        t3 = time.perf_counter()
        logger.info(
            "data-models.list done models=%s has_more=%s timings page=%.3fs counts=%.3fs total=%.3fs",
            len(data),
            has_more,
            (t2 - t1),
            (t3 - t2),
            (t3 - t0),
        )
        return {
            "data_models": data,
            "total": None,
            "limit": limit,
            "offset": offset,
            "has_more": has_more,
        }
    except Exception as e:
        logger.exception("data-models.list failed: %s", e)
        raise HTTPException(status_code=500, detail=f"Failed to fetch data models: {str(e)}")


@router.get("/model/{model_id}")
async def get_data_model(
    model_id: int,
    include_fields: bool = Query(True, description="Include fields in response"),
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"])),
    db=Depends(get_db),
):
    """
    Get a specific data model by ID with optional fields.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    try:
        # Get model
        model = await PostgresDB.fetchrow(
            """
            SELECT 
                dm.model_id, dm.model_uuid, dm.app_id, dm.model_name, dm.display_name,
                dm.table_name, dm.table_alias, dm.model_scope, dm.is_public, dm.is_system_model,
                dm.is_active, dm.description,
                dm.created_by, dm.idate, dm.last_updated
            FROM public.data_models dm
            WHERE dm.model_id = $1
            """,
            model_id
        )
        
        if not model:
            raise HTTPException(status_code=404, detail="Data model not found")
        
        result = dict(model)
        
        if include_fields:
            # Get fields
            fields = await PostgresDB.fetch(
                """
                SELECT 
                    dmf.field_id, dmf.field_name, dmf.display_name, dmf.field_type_id,
                    dmf.field_config_json, dmf.is_required, dmf.is_unique, dmf.is_primary_key,
                    dmf.default_value, dmf.encryption_method, dmf.ui_component, dmf.order_no,
                    dmf.idate,
                    ft.type_name, ft.type_code, ft.actual_db_type, ft.input_type_image
                FROM public.data_model_fields dmf
                LEFT JOIN public.field_types ft ON dmf.field_type_id = ft.field_type_id
                WHERE dmf.model_id = $1
                ORDER BY dmf.order_no, dmf.field_name
                """,
                model_id
            )
            result["fields"] = [dict(f) for f in fields] if fields else []
        else:
            result["fields"] = []
        
        return result
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch data model: {str(e)}")


@router.post("/create")
async def create_data_model(
    payload: DataModelCreate,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
    db=Depends(get_db),
):
    """
    Create a new data model with optional fields.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    user_id = user.get("user_id")
    
    try:
        # Enforce that model_name and table_name must be the same
        if payload.model_name != payload.table_name:
            raise HTTPException(
                status_code=400,
                detail="model_name and table_name must be the same"
            )
        
        # Check if model_name already exists for this app_id
        existing_model = await PostgresDB.fetchrow(
            """
            SELECT model_id, model_name, table_name FROM public.data_models 
            WHERE model_name = $1 AND (app_id = $2 OR (app_id IS NULL AND $2 IS NULL))
            """,
            payload.model_name, payload.app_id
        )
        
        if existing_model:
            raise HTTPException(
                status_code=400,
                detail=f"Data model with name '{payload.model_name}' already exists for this app"
            )
        
        # Check if table_name already exists in data_models
        existing_table = await PostgresDB.fetchrow(
            """
            SELECT model_id, model_name, table_name FROM public.data_models 
            WHERE table_name = $1
            """,
            payload.table_name
        )
        
        if existing_table:
            raise HTTPException(
                status_code=400,
                detail=f"Table name '{payload.table_name}' is already used by model '{existing_table['model_name']}'"
            )
        
        # Check if table_name already exists in the database
        table_check = await PostgresDB.fetchrow(
            """
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'public' AND table_name = $1
            """,
            payload.table_name
        )
        
        if table_check:
            raise HTTPException(
                status_code=400,
                detail=f"Table '{payload.table_name}' already exists in the database"
            )
        
        # Check if table_alias already exists (if provided)
        if payload.table_alias:
            existing_alias = await PostgresDB.fetchrow(
                """
                SELECT model_id, model_name, table_alias FROM public.data_models 
                WHERE table_alias = $1
                """,
                payload.table_alias
            )
            
            if existing_alias:
                raise HTTPException(
                    status_code=400,
                    detail=f"Table alias '{payload.table_alias}' is already used by model '{existing_alias['model_name']}'"
                )
        
        # Insert data model
        model_result = await PostgresDB.fetchrow(
            """
            INSERT INTO public.data_models (
                app_id, model_name, display_name, table_name, table_alias, model_scope,
                is_public, is_system_model, is_active, description, created_by
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
            RETURNING model_id, model_uuid
            """,
            payload.app_id,
            payload.model_name,
            payload.display_name or payload.model_name,
            payload.table_name,
            payload.table_alias,
            payload.model_scope,
            payload.is_public,
            payload.is_system_model,
            payload.is_active,
            payload.description,
            user_id
        )
        
        model_id = model_result["model_id"]
        
        # Get ID field type (auto_number or auto_uuid)
        id_field_type_code = (payload.id_field_type_code or "auto_number").strip().lower()
        if id_field_type_code not in ("auto_number", "auto_uuid"):
            await PostgresDB.execute("DELETE FROM public.data_models WHERE model_id = $1", model_id)
            raise HTTPException(status_code=400, detail="id_field_type_code must be 'auto_number' or 'auto_uuid'")
        
        id_field_type = await PostgresDB.fetchrow(
            f"SELECT field_type_id FROM public.field_types WHERE type_code = $1 LIMIT 1",
            id_field_type_code,
        )
        if not id_field_type:
            await PostgresDB.execute("DELETE FROM public.data_models WHERE model_id = $1", model_id)
            raise HTTPException(status_code=500, detail=f"Field type '{id_field_type_code}' not found")
        
        pk_field_type_id = id_field_type["field_type_id"]
        # Use id_field_name from payload, default to "id" if not provided
        id_field_name = (payload.id_field_name or "id").strip()
        if not _is_safe_identifier(id_field_name):
            await PostgresDB.execute("DELETE FROM public.data_models WHERE model_id = $1", model_id)
            raise HTTPException(status_code=400, detail=f"Invalid ID field name: {id_field_name}")
        
        # Create the actual table
        try:
            # Build CREATE TABLE statement
            # Start with the ID field (primary key)
            if id_field_type_code == "auto_uuid":
                pk_col_def = f'"{id_field_name}" UUID DEFAULT gen_random_uuid() PRIMARY KEY'
            else:
                pk_col_def = f'"{id_field_name}" SERIAL PRIMARY KEY'
            columns = [pk_col_def]
            
            # Add fields from payload
            for field in payload.fields:
                col_def = f'"{field.field_name}"'
                
                # Get field type info
                field_type = await PostgresDB.fetchrow(
                    "SELECT actual_db_type FROM public.field_types WHERE field_type_id = $1",
                    field.field_type_id
                )
                
                if not field_type:
                    raise HTTPException(status_code=400, detail=f"Invalid field_type_id: {field.field_type_id}")
                
                db_type = field_type["actual_db_type"]
                
                # Handle VARCHAR with max_length
                if db_type == "VARCHAR":
                    max_length = field.field_config_json.get("max_length", 255) if field.field_config_json else 255
                    col_def += f" VARCHAR({max_length})"
                else:
                    col_def += f" {db_type}"
                
                if field.is_required and not field.is_primary_key:
                    col_def += " NOT NULL"
                
                if field.default_value:
                    col_def += f" DEFAULT '{field.default_value}'"
                
                columns.append(col_def)
            
            # Add standard audit columns (these are always present)
            columns.append("created_by INTEGER REFERENCES public.users(user_id)")
            columns.append("idate TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL")
            columns.append("last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL")
            columns.append("deleted_at TIMESTAMPTZ")
            # Row exposure: link to row_exposure_modes for user-mode filtering in auto CRUD
            columns.append("row_exposure_mode_id INTEGER REFERENCES public.row_exposure_modes(exposure_mode_id)")
            
            create_table_sql = f'CREATE TABLE public."{payload.table_name}" ({", ".join(columns)})'
            
            await PostgresDB.execute(create_table_sql)
            
        except Exception as e:
            # Rollback model creation if table creation fails
            await PostgresDB.execute("DELETE FROM public.data_models WHERE model_id = $1", model_id)
            raise HTTPException(
                status_code=500,
                detail=f"Failed to create table '{payload.table_name}': {str(e)}"
            )
        
        # Insert ID field first (order_no = 1)
        await PostgresDB.execute(
            """
            INSERT INTO public.data_model_fields (
                model_id, field_name, display_name, field_type_id,
                field_config_json, is_required, is_unique, is_primary_key,
                default_value, encryption_method, ui_component, order_no
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
            """,
            model_id,
            id_field_name,
            "ID",
            pk_field_type_id,
            "{}",
            False,
            False,
            True,  # is_primary_key
            None,
            "none",
            None,
            1  # order_no = 1 for ID field
        )
        
        # Insert user-defined fields (starting from order_no = 2)
        if payload.fields:
            for idx, field in enumerate(payload.fields):
                await PostgresDB.execute(
                    """
                    INSERT INTO public.data_model_fields (
                        model_id, field_name, display_name, field_type_id,
                        field_config_json, is_required, is_unique, is_primary_key,
                        default_value, encryption_method, ui_component, order_no
                    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
                    """,
                    model_id,
                    field.field_name,
                    field.display_name or field.field_name,
                    field.field_type_id,
                    json.dumps(field.field_config_json) if field.field_config_json else "{}",
                    field.is_required,
                    field.is_unique,
                    field.is_primary_key,
                    field.default_value,
                    field.encryption_method,
                    field.ui_component,
                    field.order_no or (idx + 2)  # Start from 2 (after ID field)
                )
        
        # Insert essential system fields (idate, created_by, last_updated)
        # Get field_type_id for timestamp and integer types
        timestamp_type = await PostgresDB.fetchrow(
            "SELECT field_type_id FROM public.field_types WHERE type_code = 'datetime' LIMIT 1"
        )
        integer_type = await PostgresDB.fetchrow(
            "SELECT field_type_id FROM public.field_types WHERE type_code = 'number' LIMIT 1"
        )
        
        timestamp_field_type_id = timestamp_type["field_type_id"] if timestamp_type else None
        integer_field_type_id = integer_type["field_type_id"] if integer_type else None
        
        # Calculate starting order_no for system fields (after user fields)
        system_fields_start_order = 2 + len(payload.fields) if payload.fields else 2
        
        # Insert created_by field
        if integer_field_type_id:
            await PostgresDB.execute(
                """
                INSERT INTO public.data_model_fields (
                    model_id, field_name, display_name, field_type_id,
                    field_config_json, is_required, is_unique, is_primary_key,
                    default_value, encryption_method, ui_component, order_no
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
                """,
                model_id,
                "created_by",
                "Created By",
                integer_field_type_id,
                "{}",
                False,
                False,
                False,
                None,
                "none",
                None,
                system_fields_start_order
            )
        
        # Insert idate field
        if timestamp_field_type_id:
            await PostgresDB.execute(
                """
                INSERT INTO public.data_model_fields (
                    model_id, field_name, display_name, field_type_id,
                    field_config_json, is_required, is_unique, is_primary_key,
                    default_value, encryption_method, ui_component, order_no
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
                """,
                model_id,
                "idate",
                "Created Date",
                timestamp_field_type_id,
                "{}",
                True,
                False,
                False,
                None,
                "none",
                None,
                system_fields_start_order + 1
            )
        
        # Insert last_updated field
        if timestamp_field_type_id:
            await PostgresDB.execute(
                """
                INSERT INTO public.data_model_fields (
                    model_id, field_name, display_name, field_type_id,
                    field_config_json, is_required, is_unique, is_primary_key,
                    default_value, encryption_method, ui_component, order_no
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
                """,
                model_id,
                "last_updated",
                "Last Updated",
                timestamp_field_type_id,
                "{}",
                True,
                False,
                False,
                None,
                "none",
                None,
                system_fields_start_order + 2
            )

        # Soft delete timestamp (optional; hidden in lists via Auto CRUD when NULL filter applies)
        if timestamp_field_type_id:
            await PostgresDB.execute(
                """
                INSERT INTO public.data_model_fields (
                    model_id, field_name, display_name, field_type_id,
                    field_config_json, is_required, is_unique, is_primary_key,
                    default_value, encryption_method, ui_component, order_no
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
                """,
                model_id,
                "deleted_at",
                "Deleted At",
                timestamp_field_type_id,
                "{}",
                False,
                False,
                False,
                None,
                "none",
                None,
                system_fields_start_order + 3
            )
        
        # Insert row_exposure_mode_id field (hidden in UI like idate/last_updated)
        if integer_field_type_id:
            await PostgresDB.execute(
                """
                INSERT INTO public.data_model_fields (
                    model_id, field_name, display_name, field_type_id,
                    field_config_json, is_required, is_unique, is_primary_key,
                    default_value, encryption_method, ui_component, order_no
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
                """,
                model_id,
                "row_exposure_mode_id",
                "Row Exposure Mode",
                integer_field_type_id,
                "{}",
                False,
                False,
                False,
                None,
                "none",
                None,
                system_fields_start_order + 4
            )
        
        # Insert api_endpoints for auto_crud (GET, POST, PUT, DELETE)
        base_path = f"/data-models/auto/{payload.model_name}/records"
        ref_ids = [model_id]
        for path_suffix, method in [
            ("", "GET"),
            ("", "POST"),
            ("/{record_id}", "PUT"),
            ("/{record_id}", "DELETE"),
        ]:
            path = base_path + path_suffix
            await PostgresDB.execute(
                """
                INSERT INTO public.api_endpoints (
                    path, method, type, related_model_id, reference_model_ids,
                    permission_required, is_builtin, created_by
                ) VALUES ($1, $2, 'auto_crud', $3, $4, NULL, FALSE, $5)
                ON CONFLICT (path, method) DO NOTHING
                """,
                path,
                method,
                model_id,
                ref_ids,
                user_id,
            )

        # Return created model
        return await get_data_model(model_id, include_fields=True, user=user, db=db)
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create data model: {str(e)}")


@router.put("/model/{model_id}")
async def update_data_model(
    model_id: int,
    payload: DataModelUpdate,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
    db=Depends(get_db),
):
    """
    Update a data model. If table_name is changed, it will modify the actual table.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    try:
        # Get existing model
        existing = await PostgresDB.fetchrow(
            "SELECT model_id, table_name, table_alias FROM public.data_models WHERE model_id = $1",
            model_id
        )
        
        if not existing:
            raise HTTPException(status_code=404, detail="Data model not found")
        
        old_table_name = existing["table_name"]
        old_table_alias = existing.get("table_alias")
        
        # Enforce that model_name and table_name must be the same if either is being updated
        if payload.model_name is not None and payload.table_name is not None:
            if payload.model_name != payload.table_name:
                raise HTTPException(
                    status_code=400,
                    detail="model_name and table_name must be the same"
                )
        elif payload.model_name is not None:
            # If only model_name is provided, set table_name to match
            payload.table_name = payload.model_name
        elif payload.table_name is not None:
            # If only table_name is provided, set model_name to match
            payload.model_name = payload.table_name
        
        # Check if new model_name already exists (if being changed)
        if payload.model_name is not None and payload.model_name != existing.get("model_name"):
            existing_model = await PostgresDB.fetchrow(
                """
                SELECT model_id, model_name FROM public.data_models 
                WHERE model_name = $1 AND model_id != $2
                """,
                payload.model_name, model_id
            )
            if existing_model:
                raise HTTPException(
                    status_code=400,
                    detail=f"Data model with name '{payload.model_name}' already exists"
                )
        
        # Check if new table_name already exists (if being changed)
        if payload.table_name is not None and payload.table_name != old_table_name:
            existing_table = await PostgresDB.fetchrow(
                """
                SELECT model_id, table_name FROM public.data_models 
                WHERE table_name = $1 AND model_id != $2
                """,
                payload.table_name, model_id
            )
            if existing_table:
                raise HTTPException(
                    status_code=400,
                    detail=f"Table name '{payload.table_name}' is already used by another model"
                )
        
        # Build update query
        updates = []
        params = []
        param_idx = 1
        
        if payload.display_name is not None:
            updates.append(f"display_name = ${param_idx}")
            params.append(payload.display_name)
            param_idx += 1
        
        if payload.table_alias is not None:
            # Check if new table_alias already exists (if being changed)
            if payload.table_alias != old_table_alias:
                existing_alias = await PostgresDB.fetchrow(
                    """
                    SELECT model_id, model_name, table_alias FROM public.data_models 
                    WHERE table_alias = $1 AND model_id != $2
                    """,
                    payload.table_alias, model_id
                )
                
                if existing_alias:
                    raise HTTPException(
                        status_code=400,
                        detail=f"Table alias '{payload.table_alias}' is already used by model '{existing_alias['model_name']}'"
                    )
            
            updates.append(f"table_alias = ${param_idx}")
            params.append(payload.table_alias)
            param_idx += 1

        if payload.model_scope is not None:
            updates.append(f"model_scope = ${param_idx}")
            params.append(payload.model_scope)
            param_idx += 1
        
        if payload.is_public is not None:
            updates.append(f"is_public = ${param_idx}")
            params.append(payload.is_public)
            param_idx += 1
        
        if payload.is_system_model is not None:
            updates.append(f"is_system_model = ${param_idx}")
            params.append(payload.is_system_model)
            param_idx += 1
        
        if payload.is_active is not None:
            updates.append(f"is_active = ${param_idx}")
            params.append(payload.is_active)
            param_idx += 1
        
        if payload.description is not None:
            updates.append(f"description = ${param_idx}")
            params.append(payload.description)
            param_idx += 1
        
        # Handle table name change (requires ALTER TABLE)
        # Since model_name and table_name must be the same, determine the new name
        new_name = None
        if payload.model_name is not None:
            new_name = payload.model_name
        elif payload.table_name is not None:
            new_name = payload.table_name
        
        if new_name and new_name != old_table_name:
            # Check if new table name exists in database
            table_check = await PostgresDB.fetchrow(
                """
                SELECT table_name
                FROM information_schema.tables
                WHERE table_schema = 'public' AND table_name = $1
                """,
                new_name
            )
            
            if table_check:
                raise HTTPException(
                    status_code=400,
                    detail=f"Table '{new_name}' already exists in the database"
                )
            
            # Rename the table
            await PostgresDB.execute(
                f'ALTER TABLE public."{old_table_name}" RENAME TO "{new_name}"'
            )
            
            # Update both model_name and table_name to keep them in sync
            updates.append(f"model_name = ${param_idx}")
            params.append(new_name)
            param_idx += 1
            
            updates.append(f"table_name = ${param_idx}")
            params.append(new_name)
            param_idx += 1
        
        if not updates:
            raise HTTPException(status_code=400, detail="No fields to update")
        
        updates.append(f"last_updated = CURRENT_TIMESTAMP")
        params.append(model_id)
        
        query = f"""
            UPDATE public.data_models
            SET {', '.join(updates)}
            WHERE model_id = ${param_idx}
        """
        
        await PostgresDB.execute(query, *params)
        
        return await get_data_model(model_id, include_fields=True, user=user, db=db)
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update data model: {str(e)}")


@router.get("/model/{model_id}/delete-check")
async def check_model_deletion(
    model_id: int,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
    db=Depends(get_db),
):
    """
    Check if a model can be safely deleted. Returns row count and relation usages.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    try:
        # Get model info
        model = await PostgresDB.fetchrow(
            """
            SELECT model_id, model_name, display_name, table_name, is_system_model 
            FROM public.data_models 
            WHERE model_id = $1
            """,
            model_id
        )
        
        if not model:
            raise HTTPException(status_code=404, detail="Data model not found")
        
        if model["is_system_model"]:
            return {
                "can_delete": False,
                "reason": "Cannot delete system data model",
                "row_count": 0,
                "relations": []
            }
        
        table_name = model["table_name"]
        model_name = model["model_name"]
        
        # Check row count in the actual table
        row_count = 0
        try:
            table_check = await PostgresDB.fetchrow(
                """
                SELECT table_name
                FROM information_schema.tables
                WHERE table_schema = 'public' AND table_name = $1
                """,
                table_name
            )
            
            if table_check:
                count_result = await PostgresDB.fetchrow(
                    f'SELECT COUNT(*) as count FROM public."{table_name}"'
                )
                row_count = count_result["count"] if count_result else 0
        except Exception as e:
            # Table might not exist, that's okay
            logger.warning(f"Could not count rows in table {table_name}: {str(e)}")
        
        # Check for relation field usages (fields in other models that reference this model)
        # Get all relation fields and check their target_model
        all_relation_fields = await PostgresDB.fetch(
            """
            SELECT 
                dm.model_id,
                dm.model_name,
                dm.display_name,
                dmf.field_id,
                dmf.field_name,
                dmf.display_name as field_display_name,
                dmf.field_config_json,
                ft.type_code
            FROM public.data_model_fields dmf
            JOIN public.data_models dm ON dmf.model_id = dm.model_id
            JOIN public.field_types ft ON dmf.field_type_id = ft.field_type_id
            WHERE ft.type_code = 'relation'
              AND dmf.model_id != $1
            """,
            model_id
        )
        
        relation_list = []
        if all_relation_fields:
            for rel in all_relation_fields:
                # Parse field_config_json to get target_model
                try:
                    config = rel.get("field_config_json")
                    if isinstance(config, str):
                        config = json.loads(config)
                    elif config is None:
                        config = {}
                    target_model = config.get("target_model") if config else None
                    if target_model == model_name:
                        relation_list.append({
                            "model_id": rel["model_id"],
                            "model_name": rel["model_name"],
                            "display_name": rel["display_name"],
                            "field_id": rel["field_id"],
                            "field_name": rel["field_name"],
                            "field_display_name": rel["field_display_name"]
                        })
                except Exception as e:
                    logger.warning(f"Error parsing field_config_json for field {rel.get('field_id')}: {str(e)}")
        
        # Check for other references (app_views, flattening / lifecycle policies by table_name, api_endpoints)
        other_references = []
        
        # Check app_views
        app_views = await PostgresDB.fetch(
            "SELECT app_view_id, view_name FROM public.app_views WHERE model_id = $1",
            model_id
        )
        if app_views:
            other_references.append({
                "type": "app_views",
                "count": len(app_views),
                "reason": "App views that use this model. Remove or reassign them in Studio before deleting the model.",
                "items": [{"id": v["app_view_id"], "name": v["view_name"]} for v in app_views]
            })
        
        physical_table = table_name
        try:
            flattening_policies = await PostgresDB.fetch(
                """
                SELECT id, table_name FROM public.flattening_table_policy
                WHERE table_name = $1
                """,
                physical_table,
            )
            if flattening_policies:
                other_references.append({
                    "type": "flattening_table_policy",
                    "count": len(flattening_policies),
                    "reason": "Flattening table policy targets this physical table. Remove it in Developer Console → Flattened Datas first.",
                    "items": [{"id": p["id"], "name": p["table_name"]} for p in flattening_policies]
                })
            flattening_rels = await PostgresDB.fetch(
                """
                SELECT id, relation_name FROM public.flattening_relation_policy
                WHERE table_name = $1
                """,
                physical_table,
            )
            if flattening_rels:
                other_references.append({
                    "type": "flattening_relation_policy",
                    "count": len(flattening_rels),
                    "reason": "Flattening relation policies reference this table_name. Remove them before deleting the model.",
                    "items": [{"id": r["id"], "name": r["relation_name"]} for r in flattening_rels]
                })
        except Exception as e:
            if "flattening_table_policy" not in str(e) and "does not exist" not in str(e).lower():
                raise
            logger.warning("flattening policy tables missing (run db migrations): %s", e)

        try:
            lifecycle_policies = await PostgresDB.fetch(
                """
                SELECT id, policy_label FROM public.data_lifecycle_policy
                WHERE table_name = $1
                """,
                physical_table,
            )
            if lifecycle_policies:
                other_references.append({
                    "type": "data_lifecycle_policy",
                    "count": len(lifecycle_policies),
                    "reason": "Data lifecycle policies reference this table. Remove them in Developer Console → Data Life Cycles first.",
                    "items": [{"id": p["id"], "name": (p.get("policy_label") or str(p["id"]))} for p in lifecycle_policies]
                })
        except Exception as e:
            if "data_lifecycle_policy" not in str(e) and "does not exist" not in str(e).lower():
                raise
            logger.warning("data_lifecycle_policy missing (run db migrations): %s", e)
        
        # Check api_endpoints (related_model_id or model_id in reference_model_ids)
        api_endpoints = await PostgresDB.fetch(
            """
            SELECT endpoint_id, path, type FROM public.api_endpoints
            WHERE related_model_id = $1 OR $1 = ANY(reference_model_ids)
            """,
            model_id
        )
        if api_endpoints:
            auto_crud_count = sum(1 for e in api_endpoints if e.get("type") == "auto_crud")
            if auto_crud_count == len(api_endpoints):
                reason = (
                    f"{len(api_endpoints)} auto CRUD endpoint(s) (GET/POST/PUT/DELETE) are linked to this model. "
                    "They will be removed automatically when you delete the model."
                )
            else:
                reason = (
                    f"{len(api_endpoints)} API endpoint(s) reference this model. "
                    "Auto CRUD endpoints will be removed when you delete the model; others may need to be updated or removed in API Endpoints."
                )
            other_references.append({
                "type": "api_endpoints",
                "count": len(api_endpoints),
                "reason": reason,
                "items": [{"id": e["endpoint_id"], "name": e["path"]} for e in api_endpoints]
            })
        
        # Allow delete when: no data, no relation fields, and either no other refs or only api_endpoints (those are removed on delete)
        only_api_endpoints = all(ref["type"] == "api_endpoints" for ref in other_references) if other_references else True
        can_delete = (
            row_count == 0
            and len(relation_list) == 0
            and (len(other_references) == 0 or only_api_endpoints)
        )

        return {
            "can_delete": can_delete,
            "row_count": row_count,
            "relations": relation_list,
            "other_references": other_references,
            "model_name": model_name,
            "display_name": model.get("display_name"),
            "table_name": table_name
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to check model deletion: {str(e)}")


@router.delete("/model/{model_id}")
async def delete_data_model(
    model_id: int,
    delete_table: bool = Query(False, description="Also delete the actual database table"),
    confirm_delete_data: bool = Query(False, description="Confirm deletion of data records"),
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
    db=Depends(get_db),
):
    """
    Delete a data model. Optionally delete the actual table.
    Requires confirmation if model has data or relations.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    try:
        # Get model info
        model = await PostgresDB.fetchrow(
            "SELECT model_id, table_name, is_system_model FROM public.data_models WHERE model_id = $1",
            model_id
        )
        
        if not model:
            raise HTTPException(status_code=404, detail="Data model not found")
        
        if model["is_system_model"]:
            raise HTTPException(
                status_code=400,
                detail="Cannot delete system data model"
            )
        
        table_name = model["table_name"]
        
        # Check row count
        row_count = 0
        try:
            table_check = await PostgresDB.fetchrow(
                """
                SELECT table_name
                FROM information_schema.tables
                WHERE table_schema = 'public' AND table_name = $1
                """,
                table_name
            )
            
            if table_check:
                count_result = await PostgresDB.fetchrow(
                    f'SELECT COUNT(*) as count FROM public."{table_name}"'
                )
                row_count = count_result["count"] if count_result else 0
        except Exception:
            pass
        
        # Check for relations
        model_name_result = await PostgresDB.fetchrow(
            "SELECT model_name FROM public.data_models WHERE model_id = $1",
            model_id
        )
        model_name = model_name_result["model_name"] if model_name_result else None
        
        relations = []
        if model_name:
            # Get all relation fields and check their target_model
            all_relation_fields = await PostgresDB.fetch(
                """
                SELECT 
                    dm.model_id,
                    dm.model_name,
                    dm.display_name,
                    dmf.field_id,
                    dmf.field_name,
                    dmf.field_config_json,
                    ft.type_code
                FROM public.data_model_fields dmf
                JOIN public.data_models dm ON dmf.model_id = dm.model_id
                JOIN public.field_types ft ON dmf.field_type_id = ft.field_type_id
                WHERE ft.type_code = 'relation'
                  AND dmf.model_id != $1
                """,
                model_id
            )
            
            for rel in all_relation_fields:
                try:
                    config = rel.get("field_config_json")
                    if isinstance(config, str):
                        config = json.loads(config)
                    elif config is None:
                        config = {}
                    target_model = config.get("target_model") if config else None
                    if target_model == model_name:
                        relations.append(rel)
                except Exception:
                    pass
        
        # Validate deletion conditions
        if row_count > 0 and not confirm_delete_data:
            raise HTTPException(
                status_code=400,
                detail=f"Cannot delete model: Table contains {row_count} record(s). Set confirm_delete_data=true to proceed."
            )
        
        if relations and len(relations) > 0:
            relation_names = [f"{r['model_name']}.{r['field_name']}" for r in relations]
            raise HTTPException(
                status_code=400,
                detail=f"Cannot delete model: It is referenced by relation fields in other models: {', '.join(relation_names)}. Please unlink these relations first."
            )
        
        # Delete the table if requested (or if it has data and user confirmed)
        if delete_table or (row_count > 0 and confirm_delete_data):
            # Check if table exists
            table_check = await PostgresDB.fetchrow(
                """
                SELECT table_name
                FROM information_schema.tables
                WHERE table_schema = 'public' AND table_name = $1
                """,
                table_name
            )
            
            if table_check:
                await PostgresDB.execute(f'DROP TABLE IF EXISTS public."{table_name}" CASCADE')
        
        # Delete auto CRUD api_endpoints for this model (they reference related_model_id)
        await PostgresDB.execute(
            """
            DELETE FROM public.api_endpoints
            WHERE type = 'auto_crud' AND related_model_id = $1
            """,
            model_id,
        )
        
        # Delete model (fields, permissions, policies, views will be deleted via CASCADE)
        # The following tables have ON DELETE CASCADE:
        # - data_model_fields
        # - field_permissions
        # - model_row_access_policies
        # - app_views
        # - flattening_table_policy / data_lifecycle_policy (if table_name matches; remove in Dev Console first)
        await PostgresDB.execute("DELETE FROM public.data_models WHERE model_id = $1", model_id)
        
        return {
            "message": "Data model deleted successfully",
            "table_deleted": delete_table or (row_count > 0 and confirm_delete_data),
            "records_deleted": row_count if row_count > 0 and confirm_delete_data else 0
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete data model: {str(e)}")


@router.post("/model/{model_id}/fields")
async def add_field(
    model_id: int,
    field: DataModelFieldCreate,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
    db=Depends(get_db),
):
    """
    Add a field to an existing data model and optionally modify the table.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    try:
        # Get model
        model = await PostgresDB.fetchrow(
            "SELECT model_id, table_name FROM public.data_models WHERE model_id = $1",
            model_id
        )
        
        if not model:
            raise HTTPException(status_code=404, detail="Data model not found")
        
        # Check if field already exists
        existing = await PostgresDB.fetchrow(
            "SELECT field_id FROM public.data_model_fields WHERE model_id = $1 AND field_name = $2",
            model_id, field.field_name
        )
        
        if existing:
            raise HTTPException(
                status_code=400,
                detail=f"Field '{field.field_name}' already exists in this model"
            )
        
        # Get field type (actual_db_type and type_code for special handling)
        field_type = await PostgresDB.fetchrow(
            "SELECT actual_db_type, type_code FROM public.field_types WHERE field_type_id = $1",
            field.field_type_id
        )
        
        if not field_type:
            raise HTTPException(status_code=400, detail=f"Invalid field_type_id: {field.field_type_id}")

        # Determine order_no (append by default)
        if field.order_no and field.order_no > 0:
            order_no = field.order_no
        else:
            max_row = await PostgresDB.fetchrow(
                "SELECT COALESCE(MAX(order_no), 0) AS max_order FROM public.data_model_fields WHERE model_id = $1",
                model_id,
            )
            order_no = ((max_row or {}).get("max_order", 0) or 0) + 1
        
        # Insert field record
        await PostgresDB.execute(
            """
            INSERT INTO public.data_model_fields (
                model_id, field_name, display_name, field_type_id,
                field_config_json, is_required, is_unique, is_primary_key,
                default_value, encryption_method, ui_component, order_no
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
            """,
            model_id,
            field.field_name,
            field.display_name or field.field_name,
            field.field_type_id,
            json.dumps(field.field_config_json) if field.field_config_json else "{}",
            field.is_required,
            field.is_unique,
            field.is_primary_key,
            field.default_value,
            field.encryption_method,
            field.ui_component,
            order_no
        )
        
        # Add column to actual table
        table_name = model["table_name"]
        db_type = field_type["actual_db_type"]
        type_code = (field_type.get("type_code") or "").lower()
        
        col_def = f'"{field.field_name}"'
        
        if db_type == "VARCHAR":
            max_length = field.field_config_json.get("max_length", 255) if field.field_config_json else 255
            col_def += f" VARCHAR({max_length})"
        else:
            col_def += f" {db_type}"
        
        # Auto UUID: add DEFAULT gen_random_uuid()
        if type_code == "auto_uuid":
            col_def += " DEFAULT gen_random_uuid()"
        
        if field.is_required and not field.is_primary_key:
            col_def += " NOT NULL"
        
        if field.default_value and type_code != "auto_uuid":
            col_def += f" DEFAULT '{field.default_value}'"
        
        alter_sql = f'ALTER TABLE public."{table_name}" ADD COLUMN {col_def}'
        
        try:
            await PostgresDB.execute(alter_sql)
        except Exception as e:
            # Rollback field insertion
            await PostgresDB.execute(
                "DELETE FROM public.data_model_fields WHERE model_id = $1 AND field_name = $2",
                model_id, field.field_name
            )
            raise HTTPException(
                status_code=500,
                detail=f"Failed to add column to table: {str(e)}"
            )
        
        # Return updated model
        return await get_data_model(model_id, include_fields=True, user=user, db=db)
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to add field: {str(e)}")


class ReorderFieldsRequest(BaseModel):
    field_ids: List[int]


@router.put("/model/{model_id}/fields/reorder")
async def reorder_fields(
    model_id: int,
    payload: ReorderFieldsRequest,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
    db=Depends(get_db),
):
    """
    Reorder fields in a model by updating order_no.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    if not payload.field_ids:
        raise HTTPException(status_code=400, detail="field_ids cannot be empty")

    try:
        # Ensure all fields belong to this model
        rows = await PostgresDB.fetch(
            """
            SELECT field_id
            FROM public.data_model_fields
            WHERE model_id = $1 AND field_id = ANY($2::int[])
            """,
            model_id,
            payload.field_ids,
        )
        found_ids = {r["field_id"] for r in rows} if rows else set()
        requested_ids = set(payload.field_ids)
        if found_ids != requested_ids:
            missing = sorted(list(requested_ids - found_ids))
            raise HTTPException(status_code=400, detail=f"Invalid field_ids for this model: {missing}")

        # Apply new order sequentially (1..n) based on payload order
        for idx, field_id in enumerate(payload.field_ids, start=1):
            await PostgresDB.execute(
                "UPDATE public.data_model_fields SET order_no = $1 WHERE field_id = $2",
                idx,
                field_id,
            )

        return {"message": "Fields reordered successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to reorder fields: {str(e)}")


@router.put("/model/{model_id}/fields/{field_id}")
async def update_field(
    model_id: int,
    field_id: int,
    payload: DataModelFieldUpdate,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
    db=Depends(get_db),
):
    """
    Update a field in a data model.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    try:
        # Get field
        field = await PostgresDB.fetchrow(
            "SELECT field_id, field_name, model_id FROM public.data_model_fields WHERE field_id = $1 AND model_id = $2",
            field_id, model_id
        )
        
        if not field:
            raise HTTPException(status_code=404, detail="Field not found")
        
        # Build update query
        updates = []
        params = []
        param_idx = 1
        
        if payload.display_name is not None:
            updates.append(f"display_name = ${param_idx}")
            params.append(payload.display_name)
            param_idx += 1
        
        if payload.field_type_id is not None:
            updates.append(f"field_type_id = ${param_idx}")
            params.append(payload.field_type_id)
            param_idx += 1
        
        if payload.field_config_json is not None:
            updates.append(f"field_config_json = ${param_idx}::jsonb")
            params.append(json.dumps(payload.field_config_json))
            param_idx += 1
        
        if payload.is_required is not None:
            updates.append(f"is_required = ${param_idx}")
            params.append(payload.is_required)
            param_idx += 1
        
        if payload.is_unique is not None:
            updates.append(f"is_unique = ${param_idx}")
            params.append(payload.is_unique)
            param_idx += 1
        
        if payload.default_value is not None:
            updates.append(f"default_value = ${param_idx}")
            params.append(payload.default_value)
            param_idx += 1
        
        if payload.encryption_method is not None:
            updates.append(f"encryption_method = ${param_idx}")
            params.append(payload.encryption_method)
            param_idx += 1
        
        if payload.ui_component is not None:
            updates.append(f"ui_component = ${param_idx}")
            params.append(payload.ui_component)
            param_idx += 1
        
        if payload.order_no is not None:
            updates.append(f"order_no = ${param_idx}")
            params.append(payload.order_no)
            param_idx += 1
        
        if not updates:
            raise HTTPException(status_code=400, detail="No fields to update")
        
        params.append(field_id)
        
        query = f"""
            UPDATE public.data_model_fields
            SET {', '.join(updates)}
            WHERE field_id = ${param_idx}
        """
        
        await PostgresDB.execute(query, *params)
        
        return await get_data_model(model_id, include_fields=True, user=user, db=db)
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update field: {str(e)}")


@router.delete("/model/{model_id}/fields/{field_id}")
async def delete_field(
    model_id: int,
    field_id: int,
    delete_column: bool = Query(False, description="Also delete the column from the actual table"),
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
    db=Depends(get_db),
):
    """
    Delete a field from a data model. Optionally delete the column from the table.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    try:
        # Get field and model info
        field = await PostgresDB.fetchrow(
            """
            SELECT dmf.field_id, dmf.field_name, dmf.is_primary_key, dm.table_name
            FROM public.data_model_fields dmf
            JOIN public.data_models dm ON dmf.model_id = dm.model_id
            WHERE dmf.field_id = $1 AND dmf.model_id = $2
            """,
            field_id, model_id
        )
        
        if not field:
            raise HTTPException(status_code=404, detail="Field not found")
        
        if field["is_primary_key"]:
            raise HTTPException(
                status_code=400,
                detail="Cannot delete primary key field"
            )
        
        table_name = field["table_name"]
        field_name = field["field_name"]
        
        # Delete column from table if requested
        if delete_column:
            try:
                await PostgresDB.execute(
                    f'ALTER TABLE public."{table_name}" DROP COLUMN IF EXISTS "{field_name}"'
                )
            except Exception as e:
                raise HTTPException(
                    status_code=500,
                    detail=f"Failed to delete column from table: {str(e)}"
                )
        
        # Delete field record
        await PostgresDB.execute(
            "DELETE FROM public.data_model_fields WHERE field_id = $1",
            field_id
        )
        
        return {"message": "Field deleted successfully", "column_deleted": delete_column}
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete field: {str(e)}")


class AutoRecordPayload(BaseModel):
    data: Dict[str, Any]


def _assert_user_type_allowed(user: Dict[str, Any]) -> None:
    allowed = {"saas_admin", "saas_employee", "tenant_admin", "tenant_user"}
    if not user or user.get("user_type") not in allowed:
        raise HTTPException(status_code=403, detail="Access denied")


def _user_bypasses_row_and_field_policies(user: Optional[Dict[str, Any]]) -> bool:
    """
    saas_admin and tenant_admin have no row_policy or field_permissions restrictions.
    Other users (tenant_user, saas_employee, etc.) are subject to those restrictions.
    """
    if not user:
        return False
    ut = user.get("user_type")
    return ut in ("saas_admin", "tenant_admin")


async def _get_current_user_mode_id(user: Optional[Dict[str, Any]]) -> Optional[int]:
    """Return the current user's 'current_user_mode' setting (exposure_mode_id) or None."""
    if not user:
        return None
    user_uuid = user.get("user_uuid")
    if not user_uuid:
        return None
    row = await PostgresDB.fetchrow(
        """
        SELECT value FROM public.settings
        WHERE setting_key = 'current_user_mode'
          AND (user_uuid = $1 OR user_uuid IS NULL)
        ORDER BY user_uuid DESC NULLS LAST
        LIMIT 1
        """,
        user_uuid,
    )
    if not row or row.get("value") is None:
        return None
    try:
        v = row["value"]
        if isinstance(v, (int, float)):
            return int(v)
        if isinstance(v, str):
            return int(v.strip()) if v.strip() else None
        return None
    except (TypeError, ValueError):
        return None


async def _build_row_policy_where(
    model_id: int,
    action_bit: int,
    user: Optional[Dict[str, Any]],
    request: Request,
) -> Tuple[str, List[Any]]:
    if _user_bypasses_row_and_field_policies(user):
        return ("", [])
    policies = await _get_row_access_policies(model_id, action_bit)
    if not policies:
        return ("", [])

    clauses: List[str] = []
    args: List[Any] = []
    for p in policies:
        scope_field = p.get("scope_field")
        scope_source = p.get("scope_source")
        required = bool(p.get("required"))

        if not scope_field or not _is_safe_identifier(scope_field):
            raise HTTPException(status_code=500, detail="Invalid row access policy configuration")

        if scope_source == "AUTH_CONTEXT":
            scope_vals = _resolve_auth_scope_values(user or {}, scope_field)
            scope_vals = [str(v) for v in scope_vals if v is not None]
        elif scope_source == "USER":
            scope_vals = _normalize_user_values(request.query_params.get(scope_field))
        else:
            raise HTTPException(status_code=500, detail="Invalid row access policy configuration")

        if required and not scope_vals:
            raise HTTPException(status_code=403, detail=f"Missing required scope: {scope_field}")

        if not scope_vals:
            # Not required and not present -> skip
            continue

        array_type, coerced = _infer_array_type(scope_vals)
        args.append(coerced)
        param_idx = len(args)

        if array_type == "int":
            clauses.append(f'"{scope_field}" = ANY(${param_idx}::int[])')
        else:
            clauses.append(f'"{scope_field}"::text = ANY(${param_idx}::text[])')

    if not clauses:
        return ("", [])

    return (" WHERE " + " AND ".join(clauses), args)


def _apply_field_masking(
    rows: List[Dict[str, Any]],
    requested_fields: List[str],
    readable_fields: set,
    encryption_by_field: Dict[str, str],
    file_image_encryption_fields: Optional[set] = None,
) -> List[Dict[str, Any]]:
    """
    Ensures every requested field exists in each row; unauthorized fields become "AuthFailed".
    Decrypts values for readable encrypted fields when possible (same key as credentials).
    For file/image fields with encryption, the DB stores the path only; file content is encrypted in S3.
    So we do not decrypt the path (leave as-is) when field is in file_image_encryption_fields.
    """
    file_image_encryption_fields = file_image_encryption_fields or set()
    out: List[Dict[str, Any]] = []
    for r in rows or []:
        item: Dict[str, Any] = {}
        for f in requested_fields:
            if f not in readable_fields:
                item[f] = "AuthFailed"
                continue

            val = r.get(f)
            # File/image encrypted fields: path is stored plain; only file content in S3 is encrypted
            if f in file_image_encryption_fields:
                item[f] = val
                continue
            method = encryption_by_field.get(f) or "none"
            decrypted = field_encryption.decrypt_field_value(method, str(val) if val is not None else None)
            item[f] = decrypted if decrypted is not None else val
        out.append(item)
    return out


async def _auto_list_records_impl(
    model: Dict[str, Any],
    fields_meta: List[Dict[str, Any]],
    request: Request,
    user: Optional[Dict[str, Any]],
    limit: int,
    offset: int,
    requested_fields: List[str],
    filter_dict: Dict[str, Any],
) -> Dict[str, Any]:
    """
    Shared list logic for GET (query params) and POST (body.filter) list-with-filter.
    """
    model_name = model["model_name"]
    table_name = model.get("table_name")
    model_id = model["model_id"]
    all_fields = [f["field_name"] for f in fields_meta] if fields_meta else []
    encryption_by_field = {f["field_name"]: f.get("encryption_method") for f in fields_meta or []}
    field_type_map = {f["field_name"]: (f.get("type_code"), f.get("actual_db_type")) for f in fields_meta or []}

    # Coerce filter values (POST may send raw types; ensure DB-compatible)
    coerced_filter: Dict[str, Any] = {}
    for k, v in filter_dict.items():
        if k not in all_fields or not _is_safe_identifier(k):
            raise HTTPException(status_code=400, detail=f"Invalid filter field: {k}")
        coerced_filter[k] = _coerce_filter_value(k, v, field_type_map)

    where_sql, where_args = await _build_row_policy_where(model_id, ACTION_READ, user, request)
    for k, v in coerced_filter.items():
        clause = f'"{k}" = ${len(where_args) + 1}'
        where_sql = where_sql + (" AND " + clause if where_sql else " WHERE " + clause)
        where_args.append(v)

    use_exposure_join = False
    user_mode_id = await _get_current_user_mode_id(user) if user else None
    if user_mode_id is not None and "row_exposure_mode_id" in all_fields:
        use_exposure_join = True

    readable_fields = set(requested_fields)
    if user and not _user_bypasses_row_and_field_policies(user):
        role_ids = await _get_user_role_ids(user["user_id"], user.get("company_id"))
        masks = await _get_field_permission_masks(model_id, role_ids)
        readable_fields = {f for f in requested_fields if (masks.get(f, 0) & ACTION_READ) != 0}

    pk_col = await _get_primary_key_column(table_name)
    select_fields = [f for f in requested_fields if f in readable_fields]
    if pk_col and pk_col not in select_fields:
        select_fields = [pk_col] + select_fields
    if not select_fields:
        fallback = pk_col or (all_fields[0] if all_fields else None)
        if not fallback:
            raise HTTPException(status_code=500, detail="Model has no fields")
        select_fields = [fallback]

    if use_exposure_join:
        cols_sql = ", ".join([f't."{c}"' for c in select_fields])
        from_clause = f'public."{table_name}" t'
        exposure_condition = "(t.row_exposure_mode_id IS NULL OR t.row_exposure_mode_id = 0 OR t.row_exposure_mode_id = $%d)" % (len(where_args) + 1)
        exposure_where = (" WHERE " + exposure_condition) if not where_sql else (" AND " + exposure_condition)
        args = list(where_args) + [user_mode_id]
    else:
        cols_sql = ", ".join([f'"{c}"' for c in select_fields])
        from_clause = f'public."{table_name}"'
        exposure_where = ""
        args = list(where_args)
    dead_sql = ""
    if "deleted_at" in all_fields:
        colref = 't."deleted_at"' if use_exposure_join else '"deleted_at"'
        if where_sql or exposure_where:
            dead_sql = f" AND ({colref} IS NULL)"
        else:
            dead_sql = f" WHERE ({colref} IS NULL)"
    args.append(limit)
    args.append(offset)
    limit_idx = len(args) - 1
    offset_idx = len(args)
    sql = f'SELECT {cols_sql} FROM {from_clause}{where_sql}{exposure_where}{dead_sql} LIMIT ${limit_idx} OFFSET ${offset_idx}'
    raw_rows = await PostgresDB.fetch(sql, *args)

    file_image_encryption_fields = {
        f["field_name"] for f in (fields_meta or [])
        if (f.get("type_code") or "").strip().lower() in ("file", "image")
        and (f.get("encryption_method") or "").strip().lower() in ("xor_cipher", "aes")
    }
    masked = _apply_field_masking(raw_rows, requested_fields, readable_fields, encryption_by_field, file_image_encryption_fields)
    return {"model_name": model_name, "records": masked, "limit": limit, "offset": offset}


@router.get("/auto/{model_name}/records")
async def auto_list_records(
    model_name: str,
    request: Request,
    limit: int = Query(100, ge=1, le=1000),
    offset: int = Query(0, ge=0),
    fields: Optional[str] = Query(None, description="Comma-separated fields; default = model fields"),
    authorization: Optional[str] = Header(None),
):
    """
    Automatic READ (list) endpoint for models registered in public.data_models.
    Supports limit, offset, fields, and optional filter query params (field name = value).
    Enforces model_row_access_policies + field_permissions masking.
    """
    model = await _get_model_by_name(model_name)
    if not model:
        raise HTTPException(status_code=404, detail="Model not found")

    user = await resolve_bearer_to_user(authorization)
    if not model.get("is_public") and not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    if user:
        _assert_user_type_allowed(user)

    table_name = model.get("table_name")
    if not table_name or not _is_safe_identifier(table_name):
        raise HTTPException(status_code=500, detail="Invalid model configuration")

    model_id = model["model_id"]
    fields_meta = await _get_model_fields_meta(model_id)
    all_fields = [f["field_name"] for f in fields_meta] if fields_meta else []

    if fields:
        requested_fields = [x.strip() for x in fields.split(",") if x.strip()]
    else:
        requested_fields = all_fields

    for f in requested_fields:
        if not _is_safe_identifier(f) or f not in all_fields:
            raise HTTPException(status_code=400, detail=f"Invalid field requested: {f}")

    # GET filters: any query param that is a model field (not limit/offset/fields) = equality filter
    field_type_map = {f["field_name"]: (f.get("type_code"), f.get("actual_db_type")) for f in fields_meta or []}
    reserved = {"limit", "offset", "fields"}
    filter_dict = {}
    for key in request.query_params.keys():
        if key in all_fields and key not in reserved and _is_safe_identifier(key):
            filter_dict[key] = _coerce_filter_value(key, request.query_params.get(key), field_type_map)

    return await _auto_list_records_impl(model, fields_meta, request, user, limit, offset, requested_fields, filter_dict)


@router.get("/auto/{model_name}/records/{record_id}")
async def auto_get_one_record(
    model_name: str,
    record_id: str,
    request: Request,
    fields: Optional[str] = Query(None, description="Comma-separated fields; default = model fields"),
    authorization: Optional[str] = Header(None),
):
    """
    Get one record by record_id (supports both integer ID and UUID, e.g. person_uuid for persons).
    """
    model = await _get_model_by_name(model_name)
    if not model:
        raise HTTPException(status_code=404, detail="Model not found")

    user = await resolve_bearer_to_user(authorization)
    if not model.get("is_public") and not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    if user:
        _assert_user_type_allowed(user)

    table_name = model.get("table_name")
    if not table_name or not _is_safe_identifier(table_name):
        raise HTTPException(status_code=500, detail="Invalid model configuration")

    id_col, id_val = await _resolve_record_id_column_and_value(table_name, record_id)
    if not id_col or id_val is None:
        raise HTTPException(status_code=400, detail="Target table has no primary key or invalid record_id")

    model_id = model["model_id"]
    fields_meta = await _get_model_fields_meta(model_id)
    all_fields = [f["field_name"] for f in fields_meta] if fields_meta else []
    encryption_by_field = {f["field_name"]: f.get("encryption_method") for f in fields_meta or []}

    if fields:
        requested_fields = [x.strip() for x in fields.split(",") if x.strip()]
    else:
        requested_fields = all_fields
    for f in requested_fields:
        if not _is_safe_identifier(f) or f not in all_fields:
            raise HTTPException(status_code=400, detail=f"Invalid field requested: {f}")

    where_sql, where_args = await _build_row_policy_where(model_id, ACTION_READ, user, request)
    user_mode_id = await _get_current_user_mode_id(user) if user else None
    use_exposure_filter = user_mode_id is not None and "row_exposure_mode_id" in all_fields

    readable_fields = set(requested_fields)
    if user and not _user_bypasses_row_and_field_policies(user):
        role_ids = await _get_user_role_ids(user["user_id"], user.get("company_id"))
        masks = await _get_field_permission_masks(model_id, role_ids)
        readable_fields = {f for f in requested_fields if (masks.get(f, 0) & ACTION_READ) != 0}

    select_fields = [f for f in requested_fields if f in readable_fields]
    pk_col = await _get_primary_key_column(table_name)
    if pk_col and pk_col not in select_fields:
        select_fields = [pk_col] + select_fields
    if not select_fields:
        select_fields = all_fields[:1] if all_fields else [id_col]

    cols_sql = ", ".join([f'"{c}"' for c in select_fields])
    args: List[Any] = [id_val] + list(where_args)
    where = f'WHERE "{id_col}" = $1'
    if where_sql:
        where += " AND " + where_sql.replace(" WHERE ", "", 1)
    if use_exposure_filter:
        param_idx = len(args) + 1
        # NULL or 0 = always expose; else show row if row_exposure_mode_id matches user's current_user_mode (e.g. private mode shows private rows)
        where += f" AND (\"row_exposure_mode_id\" IS NULL OR \"row_exposure_mode_id\" = 0 OR \"row_exposure_mode_id\" = ${param_idx})"
        args.append(user_mode_id)
    if "deleted_at" in all_fields:
        where += ' AND ("deleted_at" IS NULL)'
    sql = f'SELECT {cols_sql} FROM public."{table_name}" {where} LIMIT 1'
    row = await PostgresDB.fetchrow(sql, *args)
    if not row:
        raise HTTPException(status_code=404, detail="Record not found (or not permitted)")
    file_image_encryption_fields = {
        f["field_name"] for f in (fields_meta or [])
        if (f.get("type_code") or "").strip().lower() in ("file", "image")
        and (f.get("encryption_method") or "").strip().lower() in ("xor_cipher", "aes")
    }
    masked = _apply_field_masking([row], requested_fields, readable_fields, encryption_by_field, file_image_encryption_fields)
    return {"model_name": model_name, "record": masked[0] if masked else {}}


@router.post("/auto/{model_name}/records")
async def auto_create_record(
    model_name: str,
    request: Request,
    authorization: Optional[str] = Header(None),
):
    """
    Automatic CREATE (body with "data") or list-with-filter (body with "filter", no "data").
    Create: body must be { "data": { ... } }. List-with-filter: body { "filter": { "<field>": <value>, ... }, optional "limit", "offset", "fields" }.
    """
    try:
        body = await request.json()
    except Exception:
        body = {}
    if not isinstance(body, dict):
        body = {}

    # List-with-filter: POST with "filter" and no "data" → run filtered list (same as GET with filter params)
    has_filter = isinstance(body.get("filter"), dict) and len(body.get("filter", {})) > 0
    has_data = isinstance(body.get("data"), dict) and len(body.get("data", {})) > 0
    if has_filter and not has_data:
        model = await _get_model_by_name(model_name)
        if not model:
            raise HTTPException(status_code=404, detail="Model not found")
        user = await resolve_bearer_to_user(authorization)
        if not model.get("is_public") and not user:
            raise HTTPException(status_code=401, detail="Authentication required")
        if user:
            _assert_user_type_allowed(user)
        if not model.get("table_name") or not _is_safe_identifier(model.get("table_name")):
            raise HTTPException(status_code=500, detail="Invalid model configuration")
        fields_meta = await _get_model_fields_meta(model["model_id"])
        all_fields = [f["field_name"] for f in fields_meta] if fields_meta else []
        limit = body.get("limit", 100)
        offset = body.get("offset", 0)
        if not isinstance(limit, int) or limit < 1 or limit > 1000:
            limit = 100
        if not isinstance(offset, int) or offset < 0:
            offset = 0
        fields_param = body.get("fields")
        requested_fields = [x.strip() for x in fields_param.split(",") if x.strip()] if isinstance(fields_param, str) and fields_param.strip() else all_fields
        for f in requested_fields:
            if not _is_safe_identifier(f) or f not in all_fields:
                raise HTTPException(status_code=400, detail=f"Invalid field requested: {f}")
        filter_dict = body.get("filter", {})
        return await _auto_list_records_impl(model, fields_meta, request, user, limit, offset, requested_fields, filter_dict)

    # Create: require "data"
    data = body.get("data") or {}
    if not isinstance(data, dict) or not data:
        raise HTTPException(status_code=400, detail="data must be a non-empty object (use filter for list-with-filter)")

    model = await _get_model_by_name(model_name)
    if not model:
        raise HTTPException(status_code=404, detail="Model not found")

    user = await resolve_bearer_to_user(authorization)
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    _assert_user_type_allowed(user)

    table_name = model.get("table_name")
    if not table_name or not _is_safe_identifier(table_name):
        raise HTTPException(status_code=500, detail="Invalid model configuration")

    model_id = model["model_id"]
    fields_meta = await _get_model_fields_meta(model_id)
    all_fields = [f["field_name"] for f in fields_meta] if fields_meta else []
    encryption_by_field = {f["field_name"]: f.get("encryption_method") for f in fields_meta or []}
    if not isinstance(data, dict) or not data:
        raise HTTPException(status_code=400, detail="data must be a non-empty object")

    # Validate fields are part of model
    for k in data.keys():
        if not _is_safe_identifier(k) or k not in all_fields:
            raise HTTPException(status_code=400, detail=f"Invalid field: {k}")

    # Enforce row policies for WRITE (scope fields on insert); saas_admin/tenant_admin bypass
    if not _user_bypasses_row_and_field_policies(user):
        policies = await _get_row_access_policies(model_id, ACTION_WRITE)
        for p in policies or []:
            scope_field = p.get("scope_field")
            scope_source = p.get("scope_source")
            required = bool(p.get("required"))

            if not scope_field or not _is_safe_identifier(scope_field):
                raise HTTPException(status_code=500, detail="Invalid row access policy configuration")

            if scope_source == "AUTH_CONTEXT":
                allowed_vals = _resolve_auth_scope_values(user, scope_field)
                if required and not allowed_vals:
                    raise HTTPException(status_code=403, detail=f"Missing required scope: {scope_field}")

                if len(allowed_vals) == 1:
                    # Server-enforced scope
                    data[scope_field] = allowed_vals[0]
                elif len(allowed_vals) > 1:
                    # Must pick one within allowed set
                    if scope_field not in data:
                        raise HTTPException(status_code=403, detail=f"Scope required in request: {scope_field}")
                    if data[scope_field] not in allowed_vals:
                        raise HTTPException(status_code=403, detail=f"Invalid scope value for {scope_field}")
                else:
                    # not required and no auth scope -> leave as is
                    pass
            elif scope_source == "USER":
                if required and scope_field not in data:
                    raise HTTPException(status_code=403, detail=f"Scope required in request: {scope_field}")
            else:
                raise HTTPException(status_code=500, detail="Invalid row access policy configuration")

        # Field-level permissions (WRITE)
        role_ids = await _get_user_role_ids(user["user_id"], user.get("company_id"))
        masks = await _get_field_permission_masks(model_id, role_ids)
        for k in data.keys():
            if (masks.get(k, 0) & ACTION_WRITE) == 0:
                raise HTTPException(status_code=403, detail=f"Write not allowed for field: {k}")
    else:
        masks = None  # User bypasses; all fields readable in response

    # Coerce date/datetime strings to Python types for asyncpg
    field_type_map = {f["field_name"]: (f.get("type_code"), f.get("actual_db_type")) for f in fields_meta or []}
    for k, v in list(data.items()):
        tc, db_type = field_type_map.get(k, (None, None))
        data[k] = _coerce_value_for_db(tc, db_type, v)

    # Apply encryption (same key as credentials / EncryptionService).
    # Exception: file/image fields with encryption store the path in DB as plain text; only file content in S3 is encrypted.
    file_image_encryption_fields = {
        f["field_name"] for f in (fields_meta or [])
        if (f.get("type_code") or "").strip().lower() in ("file", "image")
        and (f.get("encryption_method") or "").strip().lower() in ("xor_cipher", "aes")
    }
    for k, v in list(data.items()):
        if k in file_image_encryption_fields:
            continue  # Do not encrypt path for file/image; content is encrypted on upload
        method = (encryption_by_field.get(k) or "none").strip().lower()
        if method in ("none", "") or v is None:
            continue
        encrypted = field_encryption.encrypt_field_value(method, str(v))
        if encrypted is not None:
            data[k] = encrypted

    cols = list(data.keys())
    placeholders = ", ".join([f"${i+1}" for i in range(len(cols))])
    cols_sql = ", ".join([f'"{c}"' for c in cols])
    values = [data[c] for c in cols]

    sql = f'INSERT INTO public."{table_name}" ({cols_sql}) VALUES ({placeholders}) RETURNING *'
    inserted = await PostgresDB.fetchrow(sql, *values)

    # Mask response using READ rules
    fields_param = ",".join(all_fields)
    requested_fields = [x.strip() for x in fields_param.split(",") if x.strip()]
    readable_fields = set(requested_fields) if masks is None else {f for f in requested_fields if (masks.get(f, 0) & ACTION_READ) != 0}
    masked = _apply_field_masking([inserted or {}], requested_fields, readable_fields, encryption_by_field, file_image_encryption_fields)
    return {"model_name": model_name, "record": masked[0] if masked else {}}


@router.put("/auto/{model_name}/records/{record_id}")
async def auto_update_record(
    model_name: str,
    record_id: str,
    request: Request,
    payload: AutoRecordPayload,
    authorization: Optional[str] = Header(None),
):
    """
    Automatic UPDATE endpoint for models registered in public.data_models.
    Enforces model_row_access_policies + field_permissions.
    """
    model = await _get_model_by_name(model_name)
    if not model:
        raise HTTPException(status_code=404, detail="Model not found")

    user = await resolve_bearer_to_user(authorization)
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    _assert_user_type_allowed(user)

    table_name = model.get("table_name")
    if not table_name or not _is_safe_identifier(table_name):
        raise HTTPException(status_code=500, detail="Invalid model configuration")

    pk_col = await _get_primary_key_column(table_name)
    if not pk_col:
        raise HTTPException(status_code=400, detail="Target table has no primary key")

    id_col, id_val = await _resolve_record_id_column_and_value(table_name, record_id)
    if not id_col or id_val is None:
        raise HTTPException(status_code=400, detail="Invalid record_id (use integer ID or UUID)")

    model_id = model["model_id"]
    fields_meta = await _get_model_fields_meta(model_id)
    all_fields = [f["field_name"] for f in fields_meta] if fields_meta else []
    encryption_by_field = {f["field_name"]: f.get("encryption_method") for f in fields_meta or []}

    updates = payload.data or {}
    if not isinstance(updates, dict) or not updates:
        raise HTTPException(status_code=400, detail="data must be a non-empty object")

    for k in updates.keys():
        if not _is_safe_identifier(k) or k not in all_fields:
            raise HTTPException(status_code=400, detail=f"Invalid field: {k}")

    if not _user_bypasses_row_and_field_policies(user):
        role_ids = await _get_user_role_ids(user["user_id"], user.get("company_id"))
        masks = await _get_field_permission_masks(model_id, role_ids)
        for k in updates.keys():
            if (masks.get(k, 0) & ACTION_UPDATE) == 0:
                raise HTTPException(status_code=403, detail=f"Update not allowed for field: {k}")

    # Enforce row policies for UPDATE (saas_admin/tenant_admin bypass)
    policy_where, policy_args = await _build_row_policy_where(model_id, ACTION_UPDATE, user, request)
    where = f'WHERE "{id_col}" = $1'
    if policy_where:
        where += " AND " + policy_where.replace(" WHERE ", "", 1)

    # Coerce date/datetime strings to Python types for asyncpg
    field_type_map = {f["field_name"]: (f.get("type_code"), f.get("actual_db_type")) for f in fields_meta or []}
    for k, v in list(updates.items()):
        tc, db_type = field_type_map.get(k, (None, None))
        updates[k] = _coerce_value_for_db(tc, db_type, v)

    # Apply encryption (same key as credentials / EncryptionService).
    # Exception: file/image fields with encryption: do not encrypt path; only file content in S3 is encrypted.
    file_image_encryption_fields = {
        f["field_name"] for f in (fields_meta or [])
        if (f.get("type_code") or "").strip().lower() in ("file", "image")
        and (f.get("encryption_method") or "").strip().lower() in ("xor_cipher", "aes")
    }
    for k, v in list(updates.items()):
        if k in file_image_encryption_fields:
            continue
        method = (encryption_by_field.get(k) or "none").strip().lower()
        if method in ("none", "") or v is None:
            continue
        encrypted = field_encryption.encrypt_field_value(method, str(v))
        if encrypted is not None:
            updates[k] = encrypted

    # Delete old S3 objects for file/image attachment fields when value is being replaced (supports single path or JSON array for multiple)
    def _attachment_paths_from_value(val: Any) -> List[str]:
        if val is None:
            return []
        s = (val.strip() if isinstance(val, str) else str(val or "")).strip()
        if not s or s.startswith(("http://", "https://")):
            return []
        if s.startswith("["):
            try:
                arr = json.loads(s)
                return [str(x).strip() for x in arr if isinstance(x, str) and x.strip() and not x.strip().startswith(("http://", "https://"))] if isinstance(arr, list) else [s]
            except (json.JSONDecodeError, TypeError):
                return [s]
        return [s]

    attachment_fields = [
        f["field_name"] for f in (fields_meta or [])
        if (f.get("type_code") or "").strip().lower() in ("file", "image") and f["field_name"] in updates
    ]
    if attachment_fields:
        cols_sql = ", ".join(f'"{c}"' for c in attachment_fields)
        select_args: List[Any] = [id_val] + list(policy_args)
        current_row = await PostgresDB.fetchrow(
            f'SELECT {cols_sql} FROM public."{table_name}" {where}',
            *select_args,
        )
        if current_row:
            from routes.upload import _get_company_id_for_s3, _get_default_s3_service
            try:
                company_id = _get_company_id_for_s3(user)
                s3 = await _get_default_s3_service(company_id)
                for fn in attachment_fields:
                    old_val = current_row.get(fn)
                    new_val = updates.get(fn)
                    new_paths = _attachment_paths_from_value(new_val)
                    old_paths = _attachment_paths_from_value(old_val)
                    if not old_paths or set(old_paths) == set(new_paths):
                        continue
                    for path in old_paths:
                        try:
                            s3.delete_object(path)
                        except Exception:
                            pass
            except Exception as e:
                logger.warning("Delete old attachment on update failed: %s", e)

    # Build SQL with correct placeholder indices
    args: List[Any] = [id_val] + list(policy_args)
    param_idx = len(args) + 1
    set_parts = []
    for k in updates.keys():
        set_parts.append(f'"{k}" = ${param_idx}')
        args.append(updates[k])
        param_idx += 1
    set_sql = ", ".join(set_parts)

    sql = f'UPDATE public."{table_name}" SET {set_sql} {where} RETURNING *'
    updated = await PostgresDB.fetchrow(sql, *args)
    if not updated:
        raise HTTPException(status_code=404, detail="Record not found (or not permitted)")

    requested_fields = all_fields
    if _user_bypasses_row_and_field_policies(user):
        readable_fields = set(requested_fields)
    else:
        role_ids = await _get_user_role_ids(user["user_id"], user.get("company_id"))
        masks = await _get_field_permission_masks(model_id, role_ids)
        readable_fields = {f for f in requested_fields if (masks.get(f, 0) & ACTION_READ) != 0}
    masked = _apply_field_masking([updated], requested_fields, readable_fields, encryption_by_field, file_image_encryption_fields)
    return {"model_name": model_name, "record": masked[0] if masked else {}}


@router.delete("/auto/{model_name}/records/{record_id}")
async def auto_delete_record(
    model_name: str,
    record_id: str,
    request: Request,
    authorization: Optional[str] = Header(None),
):
    """
    Automatic DELETE endpoint for models registered in public.data_models.
    Enforces model_row_access_policies.
    """
    model = await _get_model_by_name(model_name)
    if not model:
        raise HTTPException(status_code=404, detail="Model not found")

    user = await resolve_bearer_to_user(authorization)
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    _assert_user_type_allowed(user)

    table_name = model.get("table_name")
    if not table_name or not _is_safe_identifier(table_name):
        raise HTTPException(status_code=500, detail="Invalid model configuration")

    pk_col = await _get_primary_key_column(table_name)
    if not pk_col:
        raise HTTPException(status_code=400, detail="Target table has no primary key")

    id_col, id_val = await _resolve_record_id_column_and_value(table_name, record_id)
    if not id_col or id_val is None:
        raise HTTPException(status_code=400, detail="Invalid record_id (use integer ID or UUID)")

    model_id = model["model_id"]
    fields_meta = await _get_model_fields_meta(model_id)
    attachment_fields = [
        f["field_name"] for f in (fields_meta or [])
        if (f.get("type_code") or "").strip().lower() in ("file", "image")
    ]

    policy_where, policy_args = await _build_row_policy_where(model_id, ACTION_DELETE, user, request)
    where = f'WHERE "{id_col}" = $1'
    if policy_where:
        where += " AND " + policy_where.replace(" WHERE ", "", 1)

    # Before delete: remove S3 objects for file/image fields (single path or JSON array of paths)
    if attachment_fields:
        cols_sql = ", ".join(f'"{c}"' for c in attachment_fields)
        select_args = [id_val] + list(policy_args)
        row = await PostgresDB.fetchrow(
            f'SELECT {cols_sql} FROM public."{table_name}" {where}',
            *select_args,
        )
        if row:
            from routes.upload import _get_company_id_for_s3, _get_default_s3_service
            try:
                company_id = _get_company_id_for_s3(user)
                s3 = await _get_default_s3_service(company_id)
                for fn in attachment_fields:
                    val = row.get(fn)
                    if val is None:
                        continue
                    s = (val.strip() if isinstance(val, str) else str(val or "")).strip()
                    if not s or s.startswith(("http://", "https://")):
                        continue
                    paths = [s]
                    if s.startswith("["):
                        try:
                            arr = json.loads(s)
                            paths = [str(x).strip() for x in arr if isinstance(x, str) and x.strip() and not x.strip().startswith(("http://", "https://"))] if isinstance(arr, list) else []
                        except (json.JSONDecodeError, TypeError):
                            pass
                    for path in paths:
                        try:
                            s3.delete_object(path)
                        except Exception:
                            pass
            except Exception as e:
                logger.warning("Delete S3 attachments on record delete failed: %s", e)

    args: List[Any] = [id_val] + list(policy_args)
    sql = f'DELETE FROM public."{table_name}" {where} RETURNING "{pk_col}"'
    deleted = await PostgresDB.fetchrow(sql, *args)
    if not deleted:
        raise HTTPException(status_code=404, detail="Record not found (or not permitted)")

    return {"model_name": model_name, "deleted": True, "record_id": deleted.get(pk_col)}


# --- Custom Endpoint (custom_query with model_row_access_policies) ---


async def execute_custom_endpoint_direct(
    endpoint_id: int,
    limit: int = 100,
    offset: int = 0,
    user: Optional[Dict[str, Any]] = None,
    request: Optional[Request] = None,
) -> Dict[str, Any]:
    """
    Execute a custom_query endpoint directly (no HTTP). Used by jobs running in the API process.
    When user is None (job context), row policies are skipped.
    Returns same shape as HTTP response: { endpoint_id, columns, records, limit, offset, row_count }.
    """
    row = await PostgresDB.fetchrow(
        """
        SELECT ae.endpoint_id, ae.path, ae.method, ae.type, ae.related_model_id,
               ae.reference_model_ids, ae.custom_json
        FROM public.api_endpoints ae
        WHERE ae.endpoint_id = $1
        """,
        endpoint_id,
    )
    if not row:
        raise ValueError(f"API endpoint not found: endpoint_id={endpoint_id}")
    if row.get("type") != "custom_query":
        raise ValueError(f"Endpoint is not custom_query type: endpoint_id={endpoint_id}")

    custom_json = row.get("custom_json") or {}
    if isinstance(custom_json, str):
        try:
            custom_json = json.loads(custom_json)
        except Exception:
            custom_json = {}
    query_sql = (custom_json.get("query") or "").strip()
    if not query_sql:
        raise ValueError("Custom endpoint has no query configured")
    if not query_sql.upper().startswith("SELECT"):
        raise ValueError("Only SELECT queries are allowed")

    ref_ids = row.get("reference_model_ids") or []
    if not isinstance(ref_ids, list):
        ref_ids = []

    policy_clauses: List[Tuple[str, List[Any]]] = []
    if ref_ids and user and request and not _user_bypasses_row_and_field_policies(user):
        models = await PostgresDB.fetch(
            """
            SELECT model_id, table_name, table_alias
            FROM public.data_models
            WHERE model_id = ANY($1::int[])
            """,
            ref_ids,
        )
        model_by_id = {m["model_id"]: dict(m) for m in (models or [])}
        for mid in ref_ids:
            if mid not in model_by_id:
                continue
            m = model_by_id[mid]
            qualifier = (m.get("table_alias") or m.get("table_name") or "").strip()
            if not qualifier or not _is_safe_identifier(qualifier):
                continue
            clause, args = await _build_row_policy_clauses_with_qualifier(
                mid, ACTION_READ, user, request, qualifier
            )
            if clause:
                policy_clauses.append((clause, args))

    if policy_clauses:
        query_sql, policy_args = _inject_row_policies_into_sql(query_sql, policy_clauses)
    else:
        policy_args = []

    query_sql = re.sub(r"\s+LIMIT\s+\d+", "", query_sql, flags=re.IGNORECASE)
    query_sql = re.sub(r"\s+OFFSET\s+\d+", "", query_sql, flags=re.IGNORECASE)
    query_sql = query_sql.rstrip()
    query_sql += f" LIMIT {min(limit, 1000)} OFFSET {offset}"

    args = list(policy_args)
    rows = await PostgresDB.fetch(query_sql, *args)
    results = [dict(r) for r in (rows or [])]
    columns = list(results[0].keys()) if results else []

    return {
        "endpoint_id": endpoint_id,
        "columns": columns,
        "records": results,
        "limit": limit,
        "offset": offset,
        "row_count": len(results),
    }


async def _build_row_policy_clauses_with_qualifier(
    model_id: int,
    action_bit: int,
    user: Optional[Dict[str, Any]],
    request: Request,
    table_qualifier: str,
) -> Tuple[str, List[Any]]:
    """
    Build row policy clauses qualified by table_qualifier (alias or table name).
    Returns (clause_sql_without_where, args).
    """
    policies = await _get_row_access_policies(model_id, action_bit)
    if not policies:
        return ("", [])

    clauses: List[str] = []
    args: List[Any] = []
    qual = f'"{table_qualifier}"' if _is_safe_identifier(table_qualifier) else table_qualifier

    for p in policies:
        scope_field = p.get("scope_field")
        scope_source = p.get("scope_source")
        required = bool(p.get("required"))

        if not scope_field or not _is_safe_identifier(scope_field):
            raise HTTPException(status_code=500, detail="Invalid row access policy configuration")

        if scope_source == "AUTH_CONTEXT":
            scope_vals = _resolve_auth_scope_values(user or {}, scope_field)
            scope_vals = [str(v) for v in scope_vals if v is not None]
        elif scope_source == "USER":
            scope_vals = _normalize_user_values(request.query_params.get(scope_field))
        else:
            raise HTTPException(status_code=500, detail="Invalid row access policy configuration")

        if required and not scope_vals:
            raise HTTPException(status_code=403, detail=f"Missing required scope: {scope_field}")

        if not scope_vals:
            continue

        array_type, coerced = _infer_array_type(scope_vals)
        args.append(coerced)
        param_idx = len(args)

        col_ref = f'{qual}."{scope_field}"'
        if array_type == "int":
            clauses.append(f"{col_ref} = ANY(${param_idx}::int[])")
        else:
            clauses.append(f"{col_ref}::text = ANY(${param_idx}::text[])")

    if not clauses:
        return ("", [])
    return ("(" + " AND ".join(clauses) + ")", args)


def _inject_row_policies_into_sql(
    sql: str,
    policy_clauses: List[Tuple[str, List[Any]]],
) -> Tuple[str, List[Any]]:
    """
    Inject row policy clauses into custom SQL.
    policy_clauses: list of (clause_sql, args) - clause_sql is e.g. "(alias.\"col\" = ANY($1::int[]))"
    Returns (modified_sql, combined_args).
    """
    if not policy_clauses:
        return (sql, [])

    combined_args: List[Any] = []
    all_clauses: List[str] = []
    param_offset = 0

    for clause_sql, args in policy_clauses:
        if not clause_sql:
            continue
        # Re-number placeholders: $1 -> $(param_offset+1), $2 -> $(param_offset+2), etc.
        def repl(m):
            n = int(m.group(1))
            return f"${param_offset + n}"

        shifted = re.sub(r"\$(\d+)\b", repl, clause_sql)
        combined_args.extend(args)
        param_offset += len(args)
        all_clauses.append(shifted)

    policy_sql = " AND ".join(all_clauses)

    sql_upper = sql.upper()
    # Find insertion point: before ORDER BY, GROUP BY, HAVING, LIMIT, or OFFSET
    pattern = re.compile(
        r"\b(ORDER\s+BY|GROUP\s+BY|HAVING|LIMIT|OFFSET)\b",
        re.IGNORECASE | re.DOTALL,
    )
    match = pattern.search(sql)
    insert_before = match.start() if match else len(sql)

    before_part = sql[:insert_before].rstrip()
    after_part = sql[insert_before:].lstrip() if insert_before < len(sql) else ""

    if " WHERE " in before_part.upper():
        # Append AND (policy) before the next keyword
        modified = before_part + " AND " + policy_sql
    else:
        modified = before_part + " WHERE " + policy_sql

    if after_part:
        modified += " " + after_part

    return (modified, combined_args)


@router.get("/custom-endpoint/{endpoint_id}")
async def custom_endpoint_get(
    endpoint_id: int,
    request: Request,
    limit: int = Query(10, ge=1, le=1000, description="Page size"),
    offset: int = Query(0, ge=0, description="Offset for pagination"),
    authorization: Optional[str] = Header(None),
):
    """
    Execute a custom_query type API endpoint by ID.
    Applies model_row_access_policies for reference_model_ids.
    Pagination is compulsory (limit, offset).
    """
    user = await resolve_bearer_to_user(authorization)
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    _assert_user_type_allowed(user)

    row = await PostgresDB.fetchrow(
        """
        SELECT ae.endpoint_id, ae.path, ae.method, ae.type, ae.related_model_id,
               ae.reference_model_ids, ae.custom_json
        FROM public.api_endpoints ae
        WHERE ae.endpoint_id = $1
        """,
        endpoint_id,
    )
    if not row:
        raise HTTPException(status_code=404, detail="API endpoint not found")

    if row.get("type") != "custom_query":
        raise HTTPException(status_code=400, detail="Endpoint is not a custom_query type")

    custom_json = row.get("custom_json") or {}
    if isinstance(custom_json, str):
        try:
            custom_json = json.loads(custom_json)
        except Exception:
            custom_json = {}
    query_sql = (custom_json.get("query") or "").strip()
    if not query_sql:
        raise HTTPException(status_code=400, detail="Custom endpoint has no query configured")

    query_upper = query_sql.upper()
    if not query_upper.startswith("SELECT"):
        raise HTTPException(status_code=400, detail="Only SELECT queries are allowed")

    ref_ids = row.get("reference_model_ids") or []
    if not isinstance(ref_ids, list):
        ref_ids = []

    policy_clauses: List[Tuple[str, List[Any]]] = []
    if ref_ids and not _user_bypasses_row_and_field_policies(user):
        models = await PostgresDB.fetch(
            """
            SELECT model_id, table_name, table_alias
            FROM public.data_models
            WHERE model_id = ANY($1::int[])
            """,
            ref_ids,
        )
        model_by_id = {m["model_id"]: dict(m) for m in (models or [])}

        for mid in ref_ids:
            if mid not in model_by_id:
                continue
            m = model_by_id[mid]
            qualifier = (m.get("table_alias") or m.get("table_name") or "").strip()
            if not qualifier or not _is_safe_identifier(qualifier):
                continue
            clause, args = await _build_row_policy_clauses_with_qualifier(
                mid, ACTION_READ, user, request, qualifier
            )
            if clause:
                policy_clauses.append((clause, args))

    if policy_clauses:
        query_sql, policy_args = _inject_row_policies_into_sql(query_sql, policy_clauses)
    else:
        policy_args = []

    # Enforce pagination: strip existing LIMIT/OFFSET and add our own
    query_sql = re.sub(r"\s+LIMIT\s+\d+", "", query_sql, flags=re.IGNORECASE)
    query_sql = re.sub(r"\s+OFFSET\s+\d+", "", query_sql, flags=re.IGNORECASE)
    query_sql = query_sql.rstrip()
    query_sql += f" LIMIT {min(limit, 1000)} OFFSET {offset}"

    args = list(policy_args)
    try:
        rows = await PostgresDB.fetch(query_sql, *args)
    except Exception as e:
        logger.exception("Custom endpoint query failed")
        raise HTTPException(status_code=400, detail=f"Query execution error: {str(e)}")

    results = [dict(r) for r in (rows or [])]
    columns = list(results[0].keys()) if results else []

    return {
        "endpoint_id": endpoint_id,
        "columns": columns,
        "records": results,
        "limit": limit,
        "offset": offset,
        "row_count": len(results),
    }

