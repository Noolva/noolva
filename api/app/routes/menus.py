from fastapi import APIRouter, Depends, Request, HTTPException, Query
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from middlewares.auth import verify_jwt_token
from utils.db import get_db
from models.menus.menu_service import MenuService
from classes.postgres_db import PostgresDB

router = APIRouter()


@router.get("/")
async def get_menus(
    app_id: Optional[int] = Query(None, description="Filter by app_id"),
    request: Request = None,
    db=Depends(get_db),
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"]))
):
    """
    Get all menus, optionally filtered by app_id.
    Requires Bearer Token.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    
    user_id = user.get("user_id")
    user_type = user.get("user_type")
    company_id = user.get("company_id")
    is_super_admin = user.get("is_super_admin", False)
    
    try:
        if app_id:
            # Use existing get_app_menus for app-specific menus
            menus = await MenuService.get_app_menus(
                app_id=app_id,
                user_id=user_id,
                user_type=user_type,
                company_id=company_id,
                is_super_admin=is_super_admin
            )
        else:
            # Get all menus user has access to
            query = """
                SELECT DISTINCT 
                    m.menu_id, m.menu_uuid, m.menu_title, m.parent_id, m.route_path,
                    m.icon, m.order_no, m.app_id, m.scope, m.type, m.view_id,
                    m.module_feature_id, m.is_builtin, m.is_hidden
                FROM public.menus m
                WHERE m.is_hidden = FALSE
                  AND (m.type = 'item' OR m.type IS NULL)
            """
            
            if not is_super_admin:
                # Add permission filters for non-admin users
                role_query = """
                    SELECT DISTINCT r.role_id
                    FROM public.user_roles ur
                    JOIN public.roles r ON ur.role_id = r.role_id
                    WHERE ur.user_id = $1 
                      AND (ur.company_id = $2 OR ur.company_id IS NULL OR $2 IS NULL)
                """
                user_roles = await PostgresDB.fetch(role_query, user_id, company_id)
                role_ids = [r["role_id"] for r in user_roles] if user_roles else []
                
                scope_conditions = []
                if user_type.startswith("saas_"):
                    scope_conditions.append("(m.scope = 'both' OR m.scope = 'saas')")
                elif user_type.startswith("tenant_"):
                    scope_conditions.append("(m.scope = 'both' OR m.scope = 'tenant')")
                
                scope_filter = " AND (" + " OR ".join(scope_conditions) + ")" if scope_conditions else ""
                
                if role_ids:
                    query = f"""
                        SELECT DISTINCT 
                            m.menu_id, m.menu_uuid, m.menu_title, m.parent_id, m.route_path,
                            m.icon, m.order_no, m.app_id, m.scope, m.type, m.view_id,
                            m.module_feature_id, m.is_builtin, m.is_hidden
                        FROM public.menus m
                        LEFT JOIN public.menu_permissions mp ON m.menu_id = mp.menu_id
                        LEFT JOIN public.user_module_features umf ON m.module_feature_id = umf.module_feature_id
                        WHERE 
                            m.is_hidden = FALSE
                            AND (m.type = 'item' OR m.type IS NULL)
                            {scope_filter}
                            AND (
                                m.is_builtin = TRUE OR
                                mp.role_id = ANY($1::int[]) OR
                                (umf.user_id = $2 AND umf.is_granted = TRUE)
                            )
                        ORDER BY m.order_no, m.menu_title
                    """
                    menus = await PostgresDB.fetch(query, role_ids, user_id)
                else:
                    query = f"""
                        SELECT DISTINCT 
                            m.menu_id, m.menu_uuid, m.menu_title, m.parent_id, m.route_path,
                            m.icon, m.order_no, m.app_id, m.scope, m.type, m.view_id,
                            m.module_feature_id, m.is_builtin, m.is_hidden
                        FROM public.menus m
                        WHERE m.is_hidden = FALSE
                          AND (m.type = 'item' OR m.type IS NULL)
                          AND m.is_builtin = TRUE
                          {scope_filter}
                        ORDER BY m.order_no, m.menu_title
                    """
                    menus = await PostgresDB.fetch(query)
            else:
                query += " ORDER BY m.order_no, m.menu_title"
                menus = await PostgresDB.fetch(query)
        
        return {"menus": [dict(m) for m in menus] if menus else []}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch menus: {str(e)}")

@router.get("/{menu_id}")
async def get_menu(
    menu_id: int,
    request: Request = None,
    db=Depends(get_db),
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"]))
):
    """
    Get a specific menu by ID.
    Requires Bearer Token.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    
    user_id = user.get("user_id")
    company_id = user.get("company_id")
    
    try:
        menu = await MenuService.get_menu_by_id(menu_id, user_id, company_id)
        if not menu:
            raise HTTPException(status_code=404, detail="Menu not found")
        return menu
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch menu: {str(e)}")

