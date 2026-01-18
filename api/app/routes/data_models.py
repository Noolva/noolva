"""
Data Models Routes
Provides CRUD operations for data_models and data_model_fields
"""

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from typing import Any, Dict, List, Optional
from middlewares.auth import verify_jwt_token
from utils.db import get_db
from classes.postgres_db import PostgresDB
from datetime import datetime
import json

router = APIRouter()


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
    use_case: str = "system"
    is_public: bool = False
    is_system_model: bool = False
    is_active: bool = True
    description: Optional[str] = None
    icon: Optional[str] = None
    fields: Optional[List[DataModelFieldCreate]] = []


class DataModelUpdate(BaseModel):
    display_name: Optional[str] = None
    table_name: Optional[str] = None
    use_case: Optional[str] = None
    is_public: Optional[bool] = None
    is_system_model: Optional[bool] = None
    is_active: Optional[bool] = None
    description: Optional[str] = None
    icon: Optional[str] = None


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
                icon, is_active
            FROM public.field_types
            WHERE is_active = TRUE
            ORDER BY category, type_name
            """
        )
        
        return {"field_types": [dict(ft) for ft in field_types] if field_types else []}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch field types: {str(e)}")


@router.get("/list")
async def get_data_models(
    app_id: Optional[int] = Query(None, description="Filter by app_id"),
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"])),
    db=Depends(get_db),
):
    """
    Get all data models, optionally filtered by app_id.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    try:
        query = """
            SELECT DISTINCT
                dm.model_id, dm.model_uuid, dm.app_id, dm.model_name, dm.display_name,
                dm.table_name, dm.use_case, dm.is_public, dm.is_system_model,
                dm.is_active, dm.description, dm.icon,
                dm.created_by, dm.idate, dm.last_updated,
                COUNT(DISTINCT dmf.field_id) as field_count
            FROM public.data_models dm
            LEFT JOIN public.data_model_fields dmf ON dm.model_id = dmf.model_id
        """
        
        params = []
        conditions = []
        
        if app_id is not None:
            conditions.append("dm.app_id = $" + str(len(params) + 1))
            params.append(app_id)
        
        if conditions:
            query += " WHERE " + " AND ".join(conditions)
        
        query += " GROUP BY dm.model_id, dm.model_uuid, dm.app_id, dm.model_name, dm.display_name, "
        query += "dm.table_name, dm.use_case, dm.is_public, dm.is_system_model, "
        query += "dm.is_active, dm.description, dm.icon, dm.created_by, dm.idate, dm.last_updated "
        query += "ORDER BY dm.model_name"
        
        models = await PostgresDB.fetch(query, *params)
        return {"data_models": [dict(m) for m in models] if models else []}
    except Exception as e:
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
                dm.table_name, dm.use_case, dm.is_public, dm.is_system_model,
                dm.is_active, dm.description, dm.icon,
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
                    ft.type_name, ft.type_code, ft.actual_db_type
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
        # Check if model_name already exists for this app_id
        existing = await PostgresDB.fetchrow(
            """
            SELECT DISTINCT model_id FROM public.data_models 
            WHERE model_name = $1 AND (app_id = $2 OR (app_id IS NULL AND $2 IS NULL))
            """,
            payload.model_name, payload.app_id
        )
        
        if existing:
            raise HTTPException(
                status_code=400,
                detail=f"Data model with name '{payload.model_name}' already exists for this app"
            )
        
        # Check if table_name already exists
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
        
        # Insert data model
        model_result = await PostgresDB.fetchrow(
            """
            INSERT INTO public.data_models (
                app_id, model_name, display_name, table_name, use_case,
                is_public, is_system_model, is_active, description, icon, created_by
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
            RETURNING model_id, model_uuid
            """,
            payload.app_id,
            payload.model_name,
            payload.display_name or payload.model_name,
            payload.table_name,
            payload.use_case,
            payload.is_public,
            payload.is_system_model,
            payload.is_active,
            payload.description,
            payload.icon,
            user_id
        )
        
        model_id = model_result["model_id"]
        
        # Create the actual table
        try:
            # Build CREATE TABLE statement
            columns = ["model_id SERIAL PRIMARY KEY"]
            
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
            
            # Add standard audit columns
            columns.append("created_by INTEGER REFERENCES public.users(user_id)")
            columns.append("idate TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL")
            columns.append("last_updated TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL")
            
            create_table_sql = f'CREATE TABLE public."{payload.table_name}" ({", ".join(columns)})'
            
            await PostgresDB.execute(create_table_sql)
            
        except Exception as e:
            # Rollback model creation if table creation fails
            await PostgresDB.execute("DELETE FROM public.data_models WHERE model_id = $1", model_id)
            raise HTTPException(
                status_code=500,
                detail=f"Failed to create table '{payload.table_name}': {str(e)}"
            )
        
        # Insert fields
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
                    field.order_no or idx + 1
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
            "SELECT model_id, table_name FROM public.data_models WHERE model_id = $1",
            model_id
        )
        
        if not existing:
            raise HTTPException(status_code=404, detail="Data model not found")
        
        old_table_name = existing["table_name"]
        
        # Build update query
        updates = []
        params = []
        param_idx = 1
        
        if payload.display_name is not None:
            updates.append(f"display_name = ${param_idx}")
            params.append(payload.display_name)
            param_idx += 1
        
        if payload.use_case is not None:
            updates.append(f"use_case = ${param_idx}")
            params.append(payload.use_case)
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
        
        if payload.icon is not None:
            updates.append(f"icon = ${param_idx}")
            params.append(payload.icon)
            param_idx += 1
        
        # Handle table name change (requires ALTER TABLE)
        if payload.table_name and payload.table_name != old_table_name:
            # Check if new table name exists
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
                    detail=f"Table '{payload.table_name}' already exists"
                )
            
            # Rename the table
            await PostgresDB.execute(
                f'ALTER TABLE public."{old_table_name}" RENAME TO "{payload.table_name}"'
            )
            
            updates.append(f"table_name = ${param_idx}")
            params.append(payload.table_name)
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


@router.delete("/model/{model_id}")
async def delete_data_model(
    model_id: int,
    delete_table: bool = Query(False, description="Also delete the actual database table"),
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee"])),
    db=Depends(get_db),
):
    """
    Delete a data model. Optionally delete the actual table.
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
        
        # Delete the table if requested
        if delete_table:
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
        
        # Delete model (fields will be deleted via CASCADE)
        await PostgresDB.execute("DELETE FROM public.data_models WHERE model_id = $1", model_id)
        
        return {"message": "Data model deleted successfully", "table_deleted": delete_table}
        
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
        
        # Get field type
        field_type = await PostgresDB.fetchrow(
            "SELECT actual_db_type FROM public.field_types WHERE field_type_id = $1",
            field.field_type_id
        )
        
        if not field_type:
            raise HTTPException(status_code=400, detail=f"Invalid field_type_id: {field.field_type_id}")
        
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
            field.order_no
        )
        
        # Add column to actual table
        table_name = model["table_name"]
        db_type = field_type["actual_db_type"]
        
        col_def = f'"{field.field_name}"'
        
        if db_type == "VARCHAR":
            max_length = field.field_config_json.get("max_length", 255) if field.field_config_json else 255
            col_def += f" VARCHAR({max_length})"
        else:
            col_def += f" {db_type}"
        
        if field.is_required and not field.is_primary_key:
            col_def += " NOT NULL"
        
        if field.default_value:
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
