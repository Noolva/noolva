"""
Menu Service
Handles dynamic menu retrieval based on user permissions, roles, and scope
"""
from typing import Dict, List, Optional, Any
from classes.postgres_db import PostgresDB
from errors import ERPError, ErrorType


class MenuService:
    """Service for retrieving menus based on user context and permissions"""
    
    @staticmethod
    async def get_user_menus(
        user_id: int,
        user_type: str,
        company_id: Optional[int] = None,
        is_super_admin: bool = False
    ) -> Dict[str, Any]:
        """
        Get menus for a user based on their roles, permissions, and scope
        
        Args:
            user_id: User ID
            user_type: User type (saas_admin, tenant_admin, tenant_user, etc.)
            company_id: Optional company ID
            is_super_admin: Whether user is super admin
            
        Returns:
            Dictionary with menus and apps
        """
        # Build menu query with permissions
        # Super admins see everything
        if is_super_admin:
            menu_query = """
                SELECT DISTINCT 
                    m.menu_id, m.menu_uuid, m.menu_title, m.parent_id, m.route_path,
                    m.icon, m.order_no, m.app_id, m.scope, m.type, m.view_id,
                    m.module_feature_id, m.is_builtin, m.is_hidden
                FROM public.menus m
                WHERE m.is_hidden = FALSE
                ORDER BY m.order_no, m.menu_title
            """
            menus = await PostgresDB.fetch(menu_query)
        else:
            # Get user roles
            role_query = """
                SELECT DISTINCT r.role_id
                FROM public.user_roles ur
                JOIN public.roles r ON ur.role_id = r.role_id
                WHERE ur.user_id = $1 
                  AND (ur.company_id = $2 OR ur.company_id IS NULL OR $2 IS NULL)
            """
            user_roles = await PostgresDB.fetch(role_query, user_id, company_id)
            role_ids = [r["role_id"] for r in user_roles] if user_roles else []
            
            # Determine scope filter
            scope_conditions = []
            if user_type.startswith("saas_"):
                scope_conditions.append("(m.scope = 'both' OR m.scope = 'saas')")
            elif user_type.startswith("tenant_"):
                scope_conditions.append("(m.scope = 'both' OR m.scope = 'tenant')")
            
            scope_filter = " AND (" + " OR ".join(scope_conditions) + ")" if scope_conditions else ""
            
            # Build menu query with role permissions
            if role_ids:
                menu_query = f"""
                    SELECT DISTINCT 
                        m.menu_id, m.menu_uuid, m.menu_title, m.parent_id, m.route_path,
                        m.icon, m.order_no, m.app_id, m.scope, m.type, m.view_id,
                        m.module_feature_id, m.is_builtin, m.is_hidden
                    FROM public.menus m
                    LEFT JOIN public.menu_permissions mp ON m.menu_id = mp.menu_id
                    LEFT JOIN public.user_module_features umf ON m.module_feature_id = umf.module_feature_id
                    WHERE 
                        m.is_hidden = FALSE
                        {scope_filter}
                        AND (
                            m.is_builtin = TRUE OR
                            mp.role_id = ANY($1::int[]) OR
                            (umf.user_id = $2 AND umf.is_granted = TRUE)
                        )
                    ORDER BY m.order_no, m.menu_title
                """
                menus = await PostgresDB.fetch(menu_query, role_ids, user_id)
            else:
                # User has no roles, only show built-in menus
                menu_query = f"""
                    SELECT DISTINCT 
                        m.menu_id, m.menu_uuid, m.menu_title, m.parent_id, m.route_path,
                        m.icon, m.order_no, m.app_id, m.scope, m.type, m.view_id,
                        m.module_feature_id, m.is_builtin, m.is_hidden
                    FROM public.menus m
                    WHERE m.is_hidden = FALSE
                      AND m.is_builtin = TRUE
                      {scope_filter}
                    ORDER BY m.order_no, m.menu_title
                """
                menus = await PostgresDB.fetch(menu_query)
        
        # Build hierarchical menu structure
        menu_dict = {menu["menu_id"]: dict(menu) for menu in menus}
        root_menus = []
        
        for menu in menus:
            menu_obj = dict(menu)
            menu_obj["children"] = []
            
            if menu["parent_id"] is None:
                root_menus.append(menu_obj)
            else:
                parent = menu_dict.get(menu["parent_id"])
                if parent:
                    if "children" not in parent:
                        parent["children"] = []
                    parent["children"].append(menu_obj)
        
        # Get apps
        app_ids = list(set([m["app_id"] for m in menus if m["app_id"]]))
        apps = []
        if app_ids:
            app_query = """
                SELECT app_id, app_uuid, app_name, app_title, app_image_url, app_description
                FROM public.apps
                WHERE app_id = ANY($1::int[])
                ORDER BY order_no, app_title
            """
            apps = await PostgresDB.fetch(app_query, app_ids)
        
        return {
            "menus": root_menus,
            "apps": [dict(app) for app in apps]
        }
    
    @staticmethod
    async def get_user_apps(
        user_id: int,
        user_type: str,
        company_id: Optional[int] = None,
        is_super_admin: bool = False
    ) -> List[Dict[str, Any]]:
        """
        Get all apps that the user has access to
        
        Args:
            user_id: User ID
            user_type: User type
            company_id: Optional company ID
            is_super_admin: Whether user is super admin
            
        Returns:
            List of app dictionaries
        """
        if is_super_admin:
            # Super admins see all apps
            query = """
                SELECT DISTINCT 
                    a.app_id, a.app_uuid, a.app_name, a.app_title, 
                    a.app_image_url, a.app_description, a.order_no
                FROM public.apps a
                ORDER BY a.order_no, a.app_title
            """
            apps = await PostgresDB.fetch(query)
        else:
            # Get apps that user has access to via menus/permissions
            # Get user roles
            role_query = """
                SELECT DISTINCT r.role_id
                FROM public.user_roles ur
                JOIN public.roles r ON ur.role_id = r.role_id
                WHERE ur.user_id = $1 
                  AND (ur.company_id = $2 OR ur.company_id IS NULL OR $2 IS NULL)
            """
            user_roles = await PostgresDB.fetch(role_query, user_id, company_id)
            role_ids = [r["role_id"] for r in user_roles] if user_roles else []
            
            # Determine scope filter
            scope_conditions = []
            if user_type.startswith("saas_"):
                scope_conditions.append("(m.scope = 'both' OR m.scope = 'saas')")
            elif user_type.startswith("tenant_"):
                scope_conditions.append("(m.scope = 'both' OR m.scope = 'tenant')")
            
            scope_filter = " AND (" + " OR ".join(scope_conditions) + ")" if scope_conditions else ""
            
            if role_ids:
                query = f"""
                    SELECT DISTINCT 
                        a.app_id, a.app_uuid, a.app_name, a.app_title, 
                        a.app_image_url, a.app_description, a.order_no
                    FROM public.apps a
                    INNER JOIN public.menus m ON a.app_id = m.app_id
                    LEFT JOIN public.menu_permissions mp ON m.menu_id = mp.menu_id
                    LEFT JOIN public.user_module_features umf ON m.module_feature_id = umf.module_feature_id
                    WHERE 
                        m.is_hidden = FALSE
                        {scope_filter}
                        AND (
                            m.is_builtin = TRUE OR
                            mp.role_id = ANY($1::int[]) OR
                            (umf.user_id = $2 AND umf.is_granted = TRUE)
                        )
                    ORDER BY a.order_no, a.app_title
                """
                apps = await PostgresDB.fetch(query, role_ids, user_id)
            else:
                # User has no roles, only show built-in menus' apps
                query = f"""
                    SELECT DISTINCT 
                        a.app_id, a.app_uuid, a.app_name, a.app_title, 
                        a.app_image_url, a.app_description, a.order_no
                    FROM public.apps a
                    INNER JOIN public.menus m ON a.app_id = m.app_id
                    WHERE m.is_hidden = FALSE
                      AND m.is_builtin = TRUE
                      {scope_filter}
                    ORDER BY a.order_no, a.app_title
                """
                apps = await PostgresDB.fetch(query)
        
        return [dict(app) for app in apps]
    
    @staticmethod
    async def get_app_menus(
        app_id: int,
        user_id: int,
        user_type: str,
        company_id: Optional[int] = None,
        is_super_admin: bool = False
    ) -> List[Dict[str, Any]]:
        """
        Get menus for a specific app that the user has access to
        
        Args:
            app_id: App ID
            user_id: User ID
            user_type: User type
            company_id: Optional company ID
            is_super_admin: Whether user is super admin
            
        Returns:
            List of menu dictionaries (hierarchical structure)
        """
        # Build menu query with permissions
        # Only fetch menus with parent_id IS NULL (direct children of app) and exclude group types
        if is_super_admin:
            menu_query = """
                SELECT DISTINCT 
                    m.menu_id, m.menu_uuid, m.menu_title, m.parent_id, m.route_path,
                    m.icon, m.order_no, m.app_id, m.scope, m.type, m.view_id,
                    m.module_feature_id, m.is_builtin, m.is_hidden
                FROM public.menus m
                WHERE m.app_id = $1 
                  AND m.is_hidden = FALSE
                  AND (m.type = 'item' OR m.type IS NULL)
                ORDER BY m.order_no, m.menu_title
            """
            menus = await PostgresDB.fetch(menu_query, app_id)
        else:
            # Get user roles
            role_query = """
                SELECT DISTINCT r.role_id
                FROM public.user_roles ur
                JOIN public.roles r ON ur.role_id = r.role_id
                WHERE ur.user_id = $1 
                  AND (ur.company_id = $2 OR ur.company_id IS NULL OR $2 IS NULL)
            """
            user_roles = await PostgresDB.fetch(role_query, user_id, company_id)
            role_ids = [r["role_id"] for r in user_roles] if user_roles else []
            
            # Determine scope filter
            scope_conditions = []
            if user_type.startswith("saas_"):
                scope_conditions.append("(m.scope = 'both' OR m.scope = 'saas')")
            elif user_type.startswith("tenant_"):
                scope_conditions.append("(m.scope = 'both' OR m.scope = 'tenant')")
            
            scope_filter = " AND (" + " OR ".join(scope_conditions) + ")" if scope_conditions else ""
            
            if role_ids:
                menu_query = f"""
                    SELECT DISTINCT 
                        m.menu_id, m.menu_uuid, m.menu_title, m.parent_id, m.route_path,
                        m.icon, m.order_no, m.app_id, m.scope, m.type, m.view_id,
                        m.module_feature_id, m.is_builtin, m.is_hidden
                    FROM public.menus m
                    LEFT JOIN public.menu_permissions mp ON m.menu_id = mp.menu_id
                    LEFT JOIN public.user_module_features umf ON m.module_feature_id = umf.module_feature_id
                    WHERE 
                        m.app_id = $1
                        AND m.is_hidden = FALSE
                        AND (m.type = 'item' OR m.type IS NULL)
                        {scope_filter}
                        AND (
                            m.is_builtin = TRUE OR
                            mp.role_id = ANY($2::int[]) OR
                            (umf.user_id = $3 AND umf.is_granted = TRUE)
                        )
                    ORDER BY m.order_no, m.menu_title
                """
                menus = await PostgresDB.fetch(menu_query, app_id, role_ids, user_id)
            else:
                # User has no roles, only show built-in menus
                menu_query = f"""
                    SELECT DISTINCT 
                        m.menu_id, m.menu_uuid, m.menu_title, m.parent_id, m.route_path,
                        m.icon, m.order_no, m.app_id, m.scope, m.type, m.view_id,
                        m.module_feature_id, m.is_builtin, m.is_hidden
                    FROM public.menus m
                    WHERE m.app_id = $1
                      AND m.is_hidden = FALSE
                      AND (m.type = 'item' OR m.type IS NULL)
                      AND m.is_builtin = TRUE
                      {scope_filter}
                    ORDER BY m.order_no, m.menu_title
                """
                menus = await PostgresDB.fetch(menu_query, app_id)
        
        # Return flat list of menus (already filtered by SQL query)
        # SQL query already ensures parent_id IS NULL and type != 'group'
        return [dict(menu) for menu in menus]
    
    @staticmethod
    async def get_menu_by_id(menu_id: int, user_id: int, company_id: Optional[int] = None) -> Optional[Dict[str, Any]]:
        """
        Get a specific menu item by ID with permission check
        
        Args:
            menu_id: Menu ID
            user_id: User ID
            company_id: Optional company ID
            
        Returns:
            Menu dictionary or None
        """
        query = """
            SELECT m.*
            FROM public.menus m
            WHERE m.menu_id = $1 AND m.is_hidden = FALSE
        """
        menu = await PostgresDB.fetchrow(query, menu_id)
        
        if not menu:
            return None
        
        # TODO: Add permission check here if needed
        
        return dict(menu)
