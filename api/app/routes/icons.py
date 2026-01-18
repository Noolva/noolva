"""
Icons Routes
Provides API endpoints for fetching icons from the icons table
"""

from fastapi import APIRouter, Depends, HTTPException, Query
from typing import Optional, List, Dict, Any
from middlewares.auth import verify_jwt_token
from utils.db import get_db
from classes.postgres_db import PostgresDB

router = APIRouter()


@router.get("/list")
async def get_icons(
    search: Optional[str] = Query(None, description="Search by name, code, description, or tags"),
    category: Optional[str] = Query(None, description="Filter by category"),
    icon_type: Optional[str] = Query(None, description="Filter by icon type (fa, antd, smily, custom)"),
    tag: Optional[str] = Query(None, description="Filter by tag"),
    is_popular: Optional[bool] = Query(None, description="Filter by popularity"),
    limit: int = Query(10000, description="Maximum number of icons to return"),
    offset: int = Query(0, description="Offset for pagination"),
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"]))
):
    """
    Get icons from the icons table with optional filtering.
    Requires Bearer Token.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    
    try:
        # Build WHERE conditions
        conditions = ["is_active = TRUE"]
        params = []
        param_count = 0
        
        # Search filter
        if search:
            param_count += 1
            conditions.append(f"""
                (
                    LOWER(icon_name) LIKE LOWER(${param_count})
                    OR LOWER(icon_code) LIKE LOWER(${param_count})
                    OR LOWER(description) LIKE LOWER(${param_count})
                    OR LOWER(category) LIKE LOWER(${param_count})
                    OR EXISTS (
                        SELECT 1 FROM unnest(tags) AS tag
                        WHERE LOWER(tag) LIKE LOWER(${param_count})
                    )
                )
            """)
            params.append(f"%{search}%")
        
        # Category filter
        if category:
            param_count += 1
            conditions.append(f"category = ${param_count}")
            params.append(category)
        
        # Icon type filter
        if icon_type:
            param_count += 1
            conditions.append(f"icon_type = ${param_count}")
            params.append(icon_type)
        
        # Tag filter
        if tag:
            param_count += 1
            conditions.append(f"${param_count} = ANY(tags)")
            params.append(tag)
        
        # Popular filter
        if is_popular is not None:
            param_count += 1
            conditions.append(f"is_popular = ${param_count}")
            params.append(is_popular)
        
        where_clause = " AND ".join(conditions)
        
        # Add LIMIT and OFFSET parameters
        param_count += 1
        limit_param = param_count
        param_count += 1
        offset_param = param_count
        params.extend([limit, offset])
        
        # Build query
        query = f"""
            SELECT 
                icon_id, icon_uuid, icon_code, icon_type, icon_name,
                category, description, tags, icon_data,
                usage_count, is_popular, is_free, is_active,
                created_at, last_updated
            FROM public.icons
            WHERE {where_clause}
            ORDER BY is_popular DESC, icon_name ASC
            LIMIT ${limit_param} OFFSET ${offset_param}
        """
        
        icons = await PostgresDB.fetch(query, *params)
        
        return {
            "icons": [dict(icon) for icon in icons] if icons else [],
            "count": len(icons) if icons else 0
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch icons: {str(e)}")


@router.get("/{icon_id}")
async def get_icon(
    icon_id: int,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"])),
    db=Depends(get_db)
):
    """
    Get a specific icon by ID.
    Requires Bearer Token.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    
    try:
        icon = await PostgresDB.fetchrow(
            """
            SELECT 
                icon_id, icon_uuid, icon_code, icon_type, icon_name,
                category, description, tags, icon_data,
                usage_count, is_popular, is_free, is_active,
                created_at, last_updated
            FROM public.icons
            WHERE icon_id = $1 AND is_active = TRUE
            """,
            icon_id
        )
        
        if not icon:
            raise HTTPException(status_code=404, detail="Icon not found")
        
        return dict(icon)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch icon: {str(e)}")


@router.get("/categories/list")
async def get_categories(
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"])),
    db=Depends(get_db)
):
    """
    Get list of all unique categories from icons.
    Requires Bearer Token.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    
    try:
        categories = await PostgresDB.fetch(
            """
            SELECT DISTINCT category
            FROM public.icons
            WHERE is_active = TRUE AND category IS NOT NULL
            ORDER BY category ASC
            """
        )
        
        return {
            "categories": [cat["category"] for cat in categories] if categories else []
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch categories: {str(e)}")


@router.get("/tags/list")
async def get_tags(
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"])),
    db=Depends(get_db)
):
    """
    Get list of all unique tags from icons.
    Requires Bearer Token.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    
    try:
        tags_result = await PostgresDB.fetch(
            """
            SELECT DISTINCT unnest(tags) AS tag
            FROM public.icons
            WHERE is_active = TRUE AND tags IS NOT NULL AND array_length(tags, 1) > 0
            ORDER BY tag ASC
            """
        )
        
        return {
            "tags": [tag["tag"] for tag in tags_result] if tags_result else []
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch tags: {str(e)}")


@router.get("/types/list")
async def get_types(
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"])),
    db=Depends(get_db)
):
    """
    Get list of all unique icon types from icons.
    Requires Bearer Token.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    
    try:
        types_result = await PostgresDB.fetch(
            """
            SELECT DISTINCT icon_type
            FROM public.icons
            WHERE is_active = TRUE AND icon_type IS NOT NULL
            ORDER BY icon_type ASC
            """
        )
        
        return {
            "types": [t["icon_type"] for t in types_result] if types_result else []
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch types: {str(e)}")
