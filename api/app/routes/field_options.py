"""
Field Options Routes
Provides endpoints to fetch options for Single Choice and Multiple Choice fields
based on options_mode: collections, foreign_key, or custom_collection
"""

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from typing import Any, Dict, List, Optional
from middlewares.auth import verify_jwt_token
from utils.db import get_db
from classes.postgres_db import PostgresDB
import json
import re

router = APIRouter(prefix="/field-options", tags=["Field Options"])


class FieldOptionsRequest(BaseModel):
    options_mode: str  # 'collections', 'foreign_key', or 'custom_collection'
    collection_id: Optional[int] = None  # Required if options_mode = 'collections'
    table_column: Optional[str] = None  # Required if options_mode = 'foreign_key', format: 'table.column'
    display_columns: Optional[str] = None  # Required if options_mode = 'foreign_key', format: 'title + "- " + name'
    options: Optional[List[Dict[str, Any]]] = None  # Required if options_mode = 'custom_collection'


@router.post("/fetch")
async def fetch_field_options(
    payload: FieldOptionsRequest,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"])),
    db=Depends(get_db),
):
    """
    Fetch options for a field based on options_mode.
    
    - collections: Fetch from collections table using collection_id
    - foreign_key: Fetch from a table using table_column and format with display_columns
    - custom_collection: Return the options array directly
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    try:
        if payload.options_mode == "collections":
            if payload.collection_id is None:
                raise HTTPException(
                    status_code=400,
                    detail="collection_id is required when options_mode is 'collections'"
                )
            
            # Fetch collection items
            collection = await PostgresDB.fetchrow(
                """
                SELECT items_json, tenant_id
                FROM public.collections
                WHERE collection_id = $1
                """,
                payload.collection_id
            )
            
            if not collection:
                raise HTTPException(status_code=404, detail="Collection not found")
            
            items = collection.get("items_json", [])
            
            # Normalize items to {label, value} format
            options = []
            if isinstance(items, list):
                for item in items:
                    if isinstance(item, dict):
                        # Handle both {label, value} and {value, label} formats
                        label = item.get("label") or item.get("name") or str(item.get("value", ""))
                        value = item.get("value") or item.get("id") or item.get("key")
                        if value is not None:
                            options.append({"label": str(label), "value": value})
                    elif isinstance(item, (str, int, float)):
                        options.append({"label": str(item), "value": item})
            
            return {"options": options}
        
        elif payload.options_mode == "foreign_key":
            if not payload.table_column:
                raise HTTPException(
                    status_code=400,
                    detail="table_column is required when options_mode is 'foreign_key'"
                )
            
            # Parse table.column format
            parts = payload.table_column.split(".")
            if len(parts) != 2:
                raise HTTPException(
                    status_code=400,
                    detail="table_column must be in format 'table.column'"
                )
            
            table_name, column_name = parts[0].strip(), parts[1].strip()
            
            # Validate table exists
            table_check = await PostgresDB.fetchrow(
                """
                SELECT table_name
                FROM information_schema.tables
                WHERE table_schema = 'public' AND table_name = $1
                """,
                table_name
            )
            
            if not table_check:
                raise HTTPException(
                    status_code=404,
                    detail=f"Table '{table_name}' not found"
                )
            
            # Build display expression from display_columns
            # Example: "title + '- ' + name" -> "COALESCE(title, '') || '- ' || COALESCE(name, '')"
            if payload.display_columns:
                # Parse the display_columns expression
                # Simple parser for expressions like "title + '- ' + name"
                # Split by '+' and process each part
                parts_expr = [p.strip().strip("'\"") for p in payload.display_columns.split("+")]
                
                display_parts = []
                for part in parts_expr:
                    part = part.strip()
                    # Check if it's a column name (no quotes) or a literal string (with quotes)
                    if part.startswith("'") and part.endswith("'"):
                        # Literal string
                        display_parts.append(f"'{part[1:-1]}'")
                    elif part.startswith('"') and part.endswith('"'):
                        # Literal string
                        display_parts.append(f"'{part[1:-1]}'")
                    else:
                        # Column name - validate it exists
                        col_check = await PostgresDB.fetchrow(
                            """
                            SELECT column_name
                            FROM information_schema.columns
                            WHERE table_schema = 'public' 
                              AND table_name = $1 
                              AND column_name = $2
                            """,
                            table_name, part
                        )
                        if not col_check:
                            raise HTTPException(
                                status_code=400,
                                detail=f"Column '{part}' not found in table '{table_name}'"
                            )
                        display_parts.append(f'COALESCE("{part}"::text, \'\')')
                
                display_expr = " || ".join(display_parts)
            else:
                # Default: use the column itself
                display_expr = f'COALESCE("{column_name}"::text, \'\')'
            
            # Fetch data with display expression
            query = f'''
                SELECT DISTINCT
                    "{column_name}" as value,
                    ({display_expr}) as label
                FROM public."{table_name}"
                WHERE "{column_name}" IS NOT NULL
                ORDER BY label
                LIMIT 1000
            '''
            
            rows = await PostgresDB.fetch(query)
            
            options = [
                {"label": str(row["label"]), "value": row["value"]}
                for row in rows
            ]
            
            return {"options": options}
        
        elif payload.options_mode == "custom_collection":
            if payload.options is None:
                return {"options": []}
            
            # Normalize options to {label, value} format
            normalized_options = []
            for opt in payload.options:
                if isinstance(opt, dict):
                    label = opt.get("label") or opt.get("name") or str(opt.get("value", ""))
                    value = opt.get("value") or opt.get("id") or opt.get("key")
                    if value is not None:
                        normalized_options.append({"label": str(label), "value": value})
                elif isinstance(opt, (str, int, float)):
                    normalized_options.append({"label": str(opt), "value": opt})
            
            return {"options": normalized_options}
        
        else:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid options_mode: {payload.options_mode}. Must be 'collections', 'foreign_key', or 'custom_collection'"
            )
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch field options: {str(e)}")


@router.get("/collections")
async def list_collections(
    tenant_id: Optional[int] = Query(None, description="Filter by tenant_id (null for global)"),
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"])),
    db=Depends(get_db),
):
    """
    List available collections.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    try:
        where = []
        params = []
        param_idx = 1
        
        if tenant_id is not None:
            where.append(f"tenant_id = ${param_idx}")
            params.append(tenant_id)
            param_idx += 1
        else:
            # Include both global (NULL) and tenant-specific
            pass
        
        query = """
            SELECT collection_id, collection_uuid, collection_name, collection_code,
                   tenant_id, items_json, is_system
            FROM public.collections
        """
        
        if where:
            query += " WHERE " + " AND ".join(where)
        
        query += " ORDER BY collection_name"
        
        rows = await PostgresDB.fetch(query, *params)
        
        return {
            "collections": [
                {
                    "collection_id": r["collection_id"],
                    "collection_uuid": str(r["collection_uuid"]),
                    "collection_name": r["collection_name"],
                    "collection_code": r["collection_code"],
                    "tenant_id": r["tenant_id"],
                    "item_count": len(r.get("items_json", [])) if r.get("items_json") else 0,
                    "is_system": r["is_system"]
                }
                for r in rows
            ]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list collections: {str(e)}")
