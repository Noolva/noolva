"""
API Endpoints Routes
Provides CRUD operations for api_endpoints (auto_crud, custom_query, flattened_view)
"""

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from middlewares.auth import verify_jwt_token
from utils.db import get_db
from classes.postgres_db import PostgresDB
import json

router = APIRouter()


class ApiEndpointCreate(BaseModel):
    path: str
    method: str = "GET"
    type: str  # 'auto_crud', 'custom_query', 'flattened_view'
    related_model_id: Optional[int] = None
    reference_model_ids: Optional[List[int]] = None
    custom_json: Optional[Dict[str, Any]] = None
    permission_required: Optional[str] = None
    is_builtin: bool = False


class ApiEndpointUpdate(BaseModel):
    path: Optional[str] = None
    method: Optional[str] = None
    type: Optional[str] = None
    related_model_id: Optional[int] = None
    reference_model_ids: Optional[List[int]] = None
    custom_json: Optional[Dict[str, Any]] = None
    permission_required: Optional[str] = None
    is_builtin: Optional[bool] = None


@router.get("/list")
async def get_api_endpoints(
    limit: int = Query(500, ge=1, le=500, description="Max endpoints per call"),
    offset: int = Query(0, ge=0, description="Pagination offset"),
    search: Optional[str] = Query(None, description="Search across path, method, type"),
    type_filter: Optional[str] = Query(None, description="Filter by type: auto_crud, custom_query, flattened_view"),
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"])),
    db=Depends(get_db),
):
    """
    Get all api_endpoints with optional search and type filter.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    try:
        where = []
        params: List[Any] = []

        if search:
            where.append(
                f"""(ae.path ILIKE ${len(params) + 1}
                    OR ae.method ILIKE ${len(params) + 1}
                    OR ae.type ILIKE ${len(params) + 1})"""
            )
            params.append(f"%{search}%")

        if type_filter:
            where.append(f"ae.type = ${len(params) + 1}")
            params.append(type_filter)

        where_sql = (" WHERE " + " AND ".join(where)) if where else ""

        query = f"""
            SELECT
                ae.endpoint_id, ae.endpoint_uuid, ae.path, ae.method, ae.type,
                ae.related_model_id, ae.reference_model_ids, ae.custom_json,
                ae.permission_required, ae.is_builtin,
                ae.created_by, ae.idate, ae.last_updated,
                dm.model_name, dm.display_name as model_display_name, dm.table_alias
            FROM public.api_endpoints ae
            LEFT JOIN public.data_models dm ON ae.related_model_id = dm.model_id
            {where_sql}
            ORDER BY ae.path ASC, ae.method ASC
            LIMIT ${len(params) + 1} OFFSET ${len(params) + 2}
        """

        rows = await PostgresDB.fetch(query, *params, limit, offset)
        data = []
        for r in rows or []:
            row = dict(r)
            if row.get("reference_model_ids") is None:
                row["reference_model_ids"] = []
            data.append(row)

        count_query = f"""
            SELECT COUNT(*)::int as total FROM public.api_endpoints ae {where_sql}
        """
        count_result = await PostgresDB.fetchrow(count_query, *params)
        total = count_result.get("total", 0) if count_result else 0
        has_more = (offset + len(data)) < total

        return {
            "api_endpoints": data,
            "total": total,
            "limit": limit,
            "offset": offset,
            "has_more": has_more,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch api endpoints: {str(e)}")


@router.get("/{endpoint_id}")
async def get_api_endpoint(
    endpoint_id: int,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"])),
    db=Depends(get_db),
):
    """
    Get a specific api_endpoint by ID.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    try:
        row = await PostgresDB.fetchrow(
            """
            SELECT
                ae.endpoint_id, ae.endpoint_uuid, ae.path, ae.method, ae.type,
                ae.related_model_id, ae.reference_model_ids, ae.custom_json,
                ae.permission_required, ae.is_builtin,
                ae.created_by, ae.idate, ae.last_updated,
                dm.model_name, dm.display_name as model_display_name, dm.table_name, dm.table_alias
            FROM public.api_endpoints ae
            LEFT JOIN public.data_models dm ON ae.related_model_id = dm.model_id
            WHERE ae.endpoint_id = $1
            """,
            endpoint_id
        )

        if not row:
            raise HTTPException(status_code=404, detail="API endpoint not found")

        result = dict(row)
        if result.get("reference_model_ids") is None:
            result["reference_model_ids"] = []
        return result
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch api endpoint: {str(e)}")


@router.post("/create")
async def create_api_endpoint(
    payload: ApiEndpointCreate,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
    db=Depends(get_db),
):
    """
    Create a new api_endpoint.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    try:
        ref_ids = payload.reference_model_ids or []
        if payload.related_model_id and payload.related_model_id not in ref_ids:
            ref_ids = [payload.related_model_id] + [x for x in ref_ids if x != payload.related_model_id]

        custom_json = payload.custom_json or {}
        custom_json_str = json.dumps(custom_json) if isinstance(custom_json, dict) else str(custom_json)

        row = await PostgresDB.fetchrow(
            """
            INSERT INTO public.api_endpoints (
                path, method, type, related_model_id, reference_model_ids,
                custom_json, permission_required, is_builtin, created_by
            ) VALUES ($1, $2, $3, $4, $5, $6::jsonb, $7, $8, $9)
            RETURNING endpoint_id, endpoint_uuid, path, method, type,
                related_model_id, reference_model_ids, custom_json,
                permission_required, is_builtin, idate
            """,
            payload.path.strip(),
            payload.method.upper(),
            payload.type,
            payload.related_model_id,
            ref_ids,
            custom_json_str,
            payload.permission_required,
            payload.is_builtin,
            user.get("user_id"),
        )

        return dict(row)
    except Exception as e:
        err_msg = str(e)
        if "api_endpoints_path_method_key" in err_msg or "unique" in err_msg.lower():
            raise HTTPException(status_code=400, detail=f"Endpoint with path '{payload.path}' and method '{payload.method}' already exists")
        raise HTTPException(status_code=500, detail=f"Failed to create api endpoint: {err_msg}")


@router.put("/{endpoint_id}")
async def update_api_endpoint(
    endpoint_id: int,
    payload: ApiEndpointUpdate,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
    db=Depends(get_db),
):
    """
    Update an api_endpoint.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    try:
        existing = await PostgresDB.fetchrow(
            "SELECT endpoint_id FROM public.api_endpoints WHERE endpoint_id = $1",
            endpoint_id
        )
        if not existing:
            raise HTTPException(status_code=404, detail="API endpoint not found")

        updates = []
        params: List[Any] = []
        param_idx = 1

        if payload.path is not None:
            updates.append(f"path = ${param_idx}")
            params.append(payload.path.strip())
            param_idx += 1
        if payload.method is not None:
            updates.append(f"method = ${param_idx}")
            params.append(payload.method.upper())
            param_idx += 1
        if payload.type is not None:
            updates.append(f"type = ${param_idx}")
            params.append(payload.type)
            param_idx += 1
        if payload.related_model_id is not None:
            updates.append(f"related_model_id = ${param_idx}")
            params.append(payload.related_model_id)
            param_idx += 1
        if payload.reference_model_ids is not None:
            updates.append(f"reference_model_ids = ${param_idx}")
            params.append(payload.reference_model_ids)
            param_idx += 1
        if payload.custom_json is not None:
            custom_json = payload.custom_json if isinstance(payload.custom_json, str) else json.dumps(payload.custom_json)
            updates.append(f"custom_json = ${param_idx}::jsonb")
            params.append(custom_json)
            param_idx += 1
        if payload.permission_required is not None:
            updates.append(f"permission_required = ${param_idx}")
            params.append(payload.permission_required)
            param_idx += 1
        if payload.is_builtin is not None:
            updates.append(f"is_builtin = ${param_idx}")
            params.append(payload.is_builtin)
            param_idx += 1

        if not updates:
            return await get_api_endpoint(endpoint_id, user=user, db=db)

        updates.append("last_updated = CURRENT_TIMESTAMP")
        params.append(endpoint_id)
        where_param = len(params)

        await PostgresDB.execute(
            f"""
            UPDATE public.api_endpoints
            SET {", ".join(updates)}
            WHERE endpoint_id = ${where_param}
            """,
            *params
        )

        return await get_api_endpoint(endpoint_id, user=user, db=db)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update api endpoint: {str(e)}")


@router.delete("/{endpoint_id}")
async def delete_api_endpoint(
    endpoint_id: int,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
    db=Depends(get_db),
):
    """
    Delete an api_endpoint.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    try:
        existing = await PostgresDB.fetchrow(
            "SELECT endpoint_id, is_builtin FROM public.api_endpoints WHERE endpoint_id = $1",
            endpoint_id
        )
        if not existing:
            raise HTTPException(status_code=404, detail="API endpoint not found")
        if existing.get("is_builtin"):
            raise HTTPException(status_code=400, detail="Cannot delete built-in endpoint")

        await PostgresDB.execute("DELETE FROM public.api_endpoints WHERE endpoint_id = $1", endpoint_id)
        return {"deleted": True, "endpoint_id": endpoint_id}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete api endpoint: {str(e)}")
