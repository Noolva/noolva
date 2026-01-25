"""
Collections Routes
Provides CRUD operations for collections (reusable option sets)
"""

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from middlewares.auth import verify_jwt_token
from utils.db import get_db
from classes.postgres_db import PostgresDB
from datetime import datetime
import json

router = APIRouter()


class CollectionCreate(BaseModel):
    collection_name: str
    collection_code: str
    tenant_id: Optional[int] = None
    field_type_id: Optional[int] = None
    field_config_json: Optional[Dict[str, Any]] = None
    is_system: bool = False


class CollectionUpdate(BaseModel):
    collection_name: Optional[str] = None
    collection_code: Optional[str] = None
    field_type_id: Optional[int] = None
    field_config_json: Optional[Dict[str, Any]] = None
    is_system: Optional[bool] = None


@router.get("/list")
async def get_collections(
    tenant_id: Optional[int] = Query(None, description="Filter by tenant_id (NULL for global)"),
    limit: int = Query(500, ge=1, le=500, description="Max collections per call"),
    offset: int = Query(0, ge=0, description="Pagination offset"),
    search: Optional[str] = Query(None, description="Search across collection_name, collection_code"),
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"])),
    db=Depends(get_db),
):
    """
    Get all collections, optionally filtered by tenant_id.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    try:
        where = []
        params: List[Any] = []

        if tenant_id is not None:
            where.append(f"c.tenant_id = ${len(params) + 1}")
            params.append(tenant_id)
        else:
            # If tenant_id is not specified, show both global (NULL) and user's tenant collections
            user_tenant_id = user.get("tenant_id")
            if user_tenant_id:
                where.append(f"(c.tenant_id IS NULL OR c.tenant_id = ${len(params) + 1})")
                params.append(user_tenant_id)
            else:
                # Show only global collections if user has no tenant
                where.append("c.tenant_id IS NULL")

        if search:
            where.append(
                f"""(
                    c.collection_name ILIKE ${len(params) + 1}
                    OR c.collection_code ILIKE ${len(params) + 1}
                )"""
            )
            params.append(f"%{search}%")

        where_sql = (" WHERE " + " AND ".join(where)) if where else ""

        query = f"""
            SELECT
                c.collection_id, c.collection_uuid, c.collection_name, c.collection_code,
                c.tenant_id, c.field_type_id, c.field_config_json, c.is_system,
                c.created_by, c.created_at, c.last_updated,
                u.username as created_by_username,
                ft.type_name as field_type_name, ft.type_code as field_type_code
            FROM public.collections c
            LEFT JOIN public.users u ON c.created_by = u.user_id
            LEFT JOIN public.field_types ft ON c.field_type_id = ft.field_type_id
            {where_sql}
            ORDER BY c.is_system DESC, c.collection_name ASC
            LIMIT ${len(params) + 1} OFFSET ${len(params) + 2}
        """

        collections = await PostgresDB.fetch(query, *params, limit, offset)

        # Get total count (simplified - just check if there are more)
        count_query = f"""
            SELECT COUNT(*)::int as total
            FROM public.collections c
            {where_sql}
        """
        count_result = await PostgresDB.fetchrow(count_query, *params)
        total = count_result.get("total", 0) if count_result else 0

        data = [dict(c) for c in collections] if collections else []
        has_more = (offset + len(data)) < total

        return {
            "collections": data,
            "total": total,
            "limit": limit,
            "offset": offset,
            "has_more": has_more,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch collections: {str(e)}")


@router.get("/{collection_id}")
async def get_collection(
    collection_id: int,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"])),
    db=Depends(get_db),
):
    """
    Get a specific collection by ID.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    try:
        collection = await PostgresDB.fetchrow(
            """
            SELECT
                c.collection_id, c.collection_uuid, c.collection_name, c.collection_code,
                c.tenant_id, c.field_type_id, c.field_config_json, c.is_system,
                c.created_by, c.created_at, c.last_updated,
                u.username as created_by_username,
                ft.type_name as field_type_name, ft.type_code as field_type_code
            FROM public.collections c
            LEFT JOIN public.users u ON c.created_by = u.user_id
            LEFT JOIN public.field_types ft ON c.field_type_id = ft.field_type_id
            WHERE c.collection_id = $1
            """,
            collection_id
        )

        if not collection:
            raise HTTPException(status_code=404, detail="Collection not found")

        return dict(collection)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch collection: {str(e)}")


@router.post("/create")
async def create_collection(
    payload: CollectionCreate,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
    db=Depends(get_db),
):
    """
    Create a new collection.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    user_id = user.get("user_id")

    try:
        # Check if collection_code already exists for this tenant
        existing = await PostgresDB.fetchrow(
            """
            SELECT collection_id FROM public.collections 
            WHERE collection_code = $1 AND (tenant_id = $2 OR (tenant_id IS NULL AND $2 IS NULL))
            """,
            payload.collection_code, payload.tenant_id
        )

        if existing:
            raise HTTPException(
                status_code=400,
                detail=f"Collection with code '{payload.collection_code}' already exists for this tenant"
            )

        # Validate field_type_id if provided
        if payload.field_type_id is not None:
            ft = await PostgresDB.fetchrow(
                "SELECT field_type_id FROM public.field_types WHERE field_type_id = $1",
                payload.field_type_id,
            )
            if not ft:
                raise HTTPException(status_code=400, detail=f"Invalid field_type_id: {payload.field_type_id}")

        # Insert collection
        result = await PostgresDB.fetchrow(
            """
            INSERT INTO public.collections (
                collection_name, collection_code, tenant_id, field_type_id, field_config_json, is_system, created_by
            ) VALUES ($1, $2, $3, $4, $5::jsonb, $6, $7)
            RETURNING collection_id, collection_uuid
            """,
            payload.collection_name,
            payload.collection_code,
            payload.tenant_id,
            payload.field_type_id,
            json.dumps(payload.field_config_json) if payload.field_config_json is not None else "{}",
            payload.is_system,
            user_id,
        )

        # Return created collection
        return await get_collection(result["collection_id"], user=user, db=db)

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create collection: {str(e)}")


@router.put("/{collection_id}")
async def update_collection(
    collection_id: int,
    payload: CollectionUpdate,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
    db=Depends(get_db),
):
    """
    Update a collection. Cannot update is_system collections.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    try:
        # Get existing collection
        existing = await PostgresDB.fetchrow(
            "SELECT collection_id, is_system, tenant_id, collection_code FROM public.collections WHERE collection_id = $1",
            collection_id
        )

        if not existing:
            raise HTTPException(status_code=404, detail="Collection not found")

        # Prevent updates to system collections
        if existing["is_system"]:
            raise HTTPException(
                status_code=400,
                detail="Cannot update system collection"
            )

        # If collection_code is being changed, check for conflicts
        if payload.collection_code and payload.collection_code != existing["collection_code"]:
            conflict = await PostgresDB.fetchrow(
                """
                SELECT collection_id FROM public.collections 
                WHERE collection_code = $1 
                  AND (tenant_id = $2 OR (tenant_id IS NULL AND $2 IS NULL))
                  AND collection_id != $3
                """,
                payload.collection_code, existing["tenant_id"], collection_id
            )

            if conflict:
                raise HTTPException(
                    status_code=400,
                    detail=f"Collection with code '{payload.collection_code}' already exists for this tenant"
                )

        # Build update query
        updates = []
        params = []
        param_idx = 1

        if payload.collection_name is not None:
            updates.append(f"collection_name = ${param_idx}")
            params.append(payload.collection_name)
            param_idx += 1

        if payload.collection_code is not None:
            updates.append(f"collection_code = ${param_idx}")
            params.append(payload.collection_code)
            param_idx += 1

        dump = payload.model_dump(exclude_unset=True)
        if "field_type_id" in dump:
            v = dump["field_type_id"]
            if v is not None:
                ft = await PostgresDB.fetchrow(
                    "SELECT field_type_id FROM public.field_types WHERE field_type_id = $1",
                    v,
                )
                if not ft:
                    raise HTTPException(status_code=400, detail=f"Invalid field_type_id: {v}")
                updates.append(f"field_type_id = ${param_idx}")
                params.append(v)
                param_idx += 1
            else:
                updates.append("field_type_id = NULL")

        if payload.field_config_json is not None:
            updates.append(f"field_config_json = ${param_idx}::jsonb")
            params.append(json.dumps(payload.field_config_json))
            param_idx += 1

        # Note: is_system cannot be updated via this endpoint
        if payload.is_system is not None and payload.is_system != existing["is_system"]:
            raise HTTPException(
                status_code=400,
                detail="Cannot change is_system flag"
            )

        if not updates:
            raise HTTPException(status_code=400, detail="No fields to update")

        updates.append("last_updated = CURRENT_TIMESTAMP")
        params.append(collection_id)

        query = f"""
            UPDATE public.collections
            SET {', '.join(updates)}
            WHERE collection_id = ${param_idx}
        """

        await PostgresDB.execute(query, *params)

        return await get_collection(collection_id, user=user, db=db)

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update collection: {str(e)}")


@router.delete("/{collection_id}")
async def delete_collection(
    collection_id: int,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
    db=Depends(get_db),
):
    """
    Delete a collection. Cannot delete system collections (is_system = TRUE).
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    try:
        # Get collection info
        collection = await PostgresDB.fetchrow(
            "SELECT collection_id, is_system FROM public.collections WHERE collection_id = $1",
            collection_id
        )

        if not collection:
            raise HTTPException(status_code=404, detail="Collection not found")

        # Prevent deletion of system collections
        if collection["is_system"]:
            raise HTTPException(
                status_code=400,
                detail="Cannot delete system collection"
            )

        # Delete collection
        await PostgresDB.execute("DELETE FROM public.collections WHERE collection_id = $1", collection_id)

        return {"message": "Collection deleted successfully"}

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete collection: {str(e)}")
