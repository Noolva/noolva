"""
Database Routes
Provides endpoints for database administration: listing tables, getting table structure, records, and updating records
"""

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from typing import Any, Dict, List, Optional
from middlewares.auth import verify_jwt_token
from utils.db import get_db
from datetime import datetime, date
import json
import re

router = APIRouter(prefix="/dev-console/database", tags=["Developer Console - Database"])


class UpdateRecordRequest(BaseModel):
    table_name: str
    record_id: Any
    updates: Dict[str, Any]


class SchemaChange(BaseModel):
    type: str  # 'add_column', 'drop_column', 'rename_column', 'alter_column_type', 'alter_column_nullable', 'alter_column_default'
    column_name: str
    new_name: Optional[str] = None
    data_type: Optional[str] = None
    max_length: Optional[int] = None
    is_nullable: Optional[bool] = None
    default_value: Optional[str] = None
    old_name: Optional[str] = None


class UpdateSchemaRequest(BaseModel):
    changes: List[SchemaChange]


@router.get("/tables")
async def get_tables(
    search: Optional[str] = Query(None, description="Search filter for table names"),
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
    db=Depends(get_db),
):
    """
    Get list of all tables in the database.
    Only accessible to admins.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    try:
        # Query to get all tables from public schema (excluding system tables)
        query = """
            SELECT 
                table_name,
                table_type
            FROM information_schema.tables
            WHERE table_schema = 'public'
              AND table_type = 'BASE TABLE'
        """
        
        if search:
            query += " AND table_name ILIKE $1"
            params = [f"%{search}%"]
        else:
            params = []
        
        query += " ORDER BY table_name"
        
        rows = await db.fetch(query, *params)
        
        tables = [{"table_name": r["table_name"], "table_type": r["table_type"]} for r in rows]
        
        return {"tables": tables, "count": len(tables)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching tables: {str(e)}")


@router.get("/tables/{table_name}/structure")
async def get_table_structure(
    table_name: str,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
    db=Depends(get_db),
):
    """
    Get the structure (columns, types, constraints) of a specific table.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    try:
        # Verify table exists and is in public schema
        table_check = await db.fetchrow(
            """
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'public'
              AND table_name = $1
              AND table_type = 'BASE TABLE'
            """,
            table_name
        )
        
        if not table_check:
            raise HTTPException(status_code=404, detail=f"Table '{table_name}' not found")

        # Get column information
        columns_query = """
            SELECT 
                column_name,
                data_type,
                character_maximum_length,
                is_nullable,
                column_default,
                ordinal_position
            FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name = $1
            ORDER BY ordinal_position
        """
        
        columns = await db.fetch(columns_query, table_name)
        
        # Get primary key information
        pk_query = """
            SELECT 
                kcu.column_name
            FROM information_schema.table_constraints tc
            JOIN information_schema.key_column_usage kcu 
                ON tc.constraint_name = kcu.constraint_name
                AND tc.table_schema = kcu.table_schema
            WHERE tc.table_schema = 'public'
              AND tc.table_name = $1
              AND tc.constraint_type = 'PRIMARY KEY'
            ORDER BY kcu.ordinal_position
        """
        
        pk_columns = await db.fetch(pk_query, table_name)
        primary_keys = [r["column_name"] for r in pk_columns]
        
        # Get foreign key information
        fk_query = """
            SELECT 
                kcu.column_name,
                ccu.table_schema AS foreign_table_schema,
                ccu.table_name AS foreign_table_name,
                ccu.column_name AS foreign_column_name
            FROM information_schema.table_constraints AS tc
            JOIN information_schema.key_column_usage AS kcu
                ON tc.constraint_name = kcu.constraint_name
                AND tc.table_schema = kcu.table_schema
            JOIN information_schema.constraint_column_usage AS ccu
                ON ccu.constraint_name = tc.constraint_name
                AND ccu.table_schema = tc.table_schema
            WHERE tc.constraint_type = 'FOREIGN KEY'
                AND tc.table_schema = 'public'
                AND tc.table_name = $1
        """
        fk_columns = await db.fetch(fk_query, table_name)
        
        # Create a map of column_name -> foreign key info
        foreign_keys_map = {}
        for fk in fk_columns:
            column_name = fk["column_name"]
            if column_name not in foreign_keys_map:
                foreign_keys_map[column_name] = {
                    "referenced_table": fk["foreign_table_name"],
                    "referenced_column": fk["foreign_column_name"]
                }
        
        # Format column data
        structure = []
        for col in columns:
            col_info = {
                "column_name": col["column_name"],
                "data_type": col["data_type"],
                "max_length": col["character_maximum_length"],
                "is_nullable": col["is_nullable"] == "YES",
                "default_value": col["column_default"],
                "ordinal_position": col["ordinal_position"],
                "is_primary_key": col["column_name"] in primary_keys
            }
            
            # Add foreign key info if exists
            if col["column_name"] in foreign_keys_map:
                col_info["foreign_key"] = foreign_keys_map[col["column_name"]]
            
            structure.append(col_info)
        
        return {
            "table_name": table_name,
            "columns": structure,
            "primary_keys": primary_keys
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching table structure: {str(e)}")


@router.get("/tables/{table_name}/records")
async def get_table_records(
    table_name: str,
    limit: int = Query(100, ge=1, le=1000, description="Maximum number of records to return"),
    offset: int = Query(0, ge=0, description="Number of records to skip"),
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
    db=Depends(get_db),
):
    """
    Get records from a specific table with pagination.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    try:
        # Verify table exists
        table_check = await db.fetchrow(
            """
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'public'
              AND table_name = $1
              AND table_type = 'BASE TABLE'
            """,
            table_name
        )
        
        if not table_check:
            raise HTTPException(status_code=404, detail=f"Table '{table_name}' not found")

        # Get total count
        count_result = await db.fetchrow(
            f'SELECT COUNT(*) as total FROM public."{table_name}"'
        )
        total = count_result["total"] if count_result else 0

        # Get records
        records_query = f'SELECT * FROM public."{table_name}" LIMIT $1 OFFSET $2'
        records = await db.fetch(records_query, limit, offset)
        
        # Convert records to dictionaries
        records_list = [dict(r) for r in records]
        
        return {
            "table_name": table_name,
            "records": records_list,
            "total": total,
            "limit": limit,
            "offset": offset
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching records: {str(e)}")


@router.put("/tables/{table_name}/schema")
async def update_table_schema(
    table_name: str,
    payload: UpdateSchemaRequest,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee"])),
    db=Depends(get_db),
):
    """
    Update table schema (ALTER TABLE operations).
    Supports: add column, drop column, rename column, alter column type, alter nullable, alter default.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    try:
        # Verify table exists
        table_check = await db.fetchrow(
            """
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'public'
              AND table_name = $1
              AND table_type = 'BASE TABLE'
            """,
            table_name
        )
        
        if not table_check:
            raise HTTPException(status_code=404, detail=f"Table '{table_name}' not found")

        executed_changes = []
        errors = []

        for change in payload.changes:
            try:
                if change.type == 'add_column':
                    # Build column definition
                    col_def = f'"{change.column_name}" {change.data_type}'
                    
                    if change.max_length and change.data_type in ('varchar', 'char'):
                        col_def += f'({change.max_length})'
                    
                    if not change.is_nullable:
                        col_def += ' NOT NULL'
                    
                    if change.default_value:
                        col_def += f' DEFAULT {change.default_value}'
                    
                    query = f'ALTER TABLE public."{table_name}" ADD COLUMN {col_def}'
                    await db.execute(query)
                    executed_changes.append(f"Added column '{change.column_name}'")

                elif change.type == 'drop_column':
                    query = f'ALTER TABLE public."{table_name}" DROP COLUMN "{change.column_name}"'
                    await db.execute(query)
                    executed_changes.append(f"Dropped column '{change.column_name}'")

                elif change.type == 'rename_column':
                    query = f'ALTER TABLE public."{table_name}" RENAME COLUMN "{change.old_name}" TO "{change.new_name}"'
                    await db.execute(query)
                    executed_changes.append(f"Renamed column '{change.old_name}' to '{change.new_name}'")

                elif change.type == 'alter_column_type':
                    type_def = change.data_type
                    if change.max_length and change.data_type in ('varchar', 'char'):
                        type_def += f'({change.max_length})'
                    
                    query = f'ALTER TABLE public."{table_name}" ALTER COLUMN "{change.column_name}" TYPE {type_def}'
                    await db.execute(query)
                    executed_changes.append(f"Changed type of column '{change.column_name}'")

                elif change.type == 'alter_column_nullable':
                    nullable_clause = 'DROP NOT NULL' if change.is_nullable else 'SET NOT NULL'
                    query = f'ALTER TABLE public."{table_name}" ALTER COLUMN "{change.column_name}" {nullable_clause}'
                    await db.execute(query)
                    nullable_str = 'nullable' if change.is_nullable else 'not nullable'
                    executed_changes.append(f"Made column '{change.column_name}' {nullable_str}")

                elif change.type == 'alter_column_default':
                    if change.default_value:
                        query = f'ALTER TABLE public."{table_name}" ALTER COLUMN "{change.column_name}" SET DEFAULT {change.default_value}'
                    else:
                        query = f'ALTER TABLE public."{table_name}" ALTER COLUMN "{change.column_name}" DROP DEFAULT'
                    await db.execute(query)
                    executed_changes.append(f"Updated default value for column '{change.column_name}'")

            except Exception as e:
                errors.append(f"{change.type} on '{change.column_name}': {str(e)}")

        if errors:
            return {
                "message": "Some changes failed",
                "executed_changes": executed_changes,
                "errors": errors
            }

        return {
            "message": "Schema updated successfully",
            "executed_changes": executed_changes
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error updating schema: {str(e)}")


class ExecuteQueryRequest(BaseModel):
    query: str
    limit: Optional[int] = 1000  # Safety limit


@router.post("/execute-query")
async def execute_query(
    payload: ExecuteQueryRequest,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
    db=Depends(get_db),
):
    """
    Execute a SQL SELECT query.
    Only SELECT queries are allowed for safety.
    Results are paginated automatically.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    try:
        query = payload.query.strip()
        
        # Safety: Only allow SELECT queries
        query_upper = query.upper().strip()
        if not query_upper.startswith('SELECT'):
            raise HTTPException(status_code=400, detail="Only SELECT queries are allowed")
        
        # Safety: Block dangerous operations even if they start with SELECT
        dangerous_keywords = ['DROP', 'DELETE', 'UPDATE', 'INSERT', 'ALTER', 'TRUNCATE', 'CREATE', 'GRANT', 'REVOKE']
        for keyword in dangerous_keywords:
            if keyword in query_upper and keyword != 'SELECT':
                raise HTTPException(status_code=400, detail=f"Query contains forbidden keyword: {keyword}")
        
        # Add LIMIT if not present (safety)
        limit = min(payload.limit or 1000, 1000)  # Max 1000 rows
        
        # Check if LIMIT already exists
        if 'LIMIT' not in query_upper:
            query += f' LIMIT {limit}'
        
        # Execute query
        try:
            rows = await db.fetch(query)
        except Exception as db_error:
            raise HTTPException(status_code=400, detail=f"Query execution error: {str(db_error)}")
        
        # Convert to list of dicts
        results = [dict(row) for row in rows]
        
        # Get column names
        columns = list(results[0].keys()) if results else []
        
        return {
            "columns": columns,
            "rows": results,
            "row_count": len(results),
            "query": query
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error executing query: {str(e)}")


@router.get("/suggestions")
async def get_suggestions(
    prefix: Optional[str] = Query(None, description="Prefix to filter suggestions"),
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
    db=Depends(get_db),
):
    """
    Get auto-complete suggestions for tables and columns.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    try:
        suggestions = {
            "keywords": [
                "SELECT", "FROM", "WHERE", "ORDER BY", "GROUP BY", "HAVING",
                "JOIN", "INNER JOIN", "LEFT JOIN", "RIGHT JOIN", "FULL JOIN",
                "ON", "AS", "AND", "OR", "NOT", "IN", "LIKE", "BETWEEN",
                "COUNT", "SUM", "AVG", "MAX", "MIN", "DISTINCT", "LIMIT", "OFFSET"
            ],
            "tables": [],
            "columns": {}
        }
        
        # Get tables
        tables_query = """
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'public'
              AND table_type = 'BASE TABLE'
            ORDER BY table_name
        """
        
        if prefix:
            tables_query += " AND table_name ILIKE $1"
            params = [f"{prefix}%"]
        else:
            params = []
        
        tables = await db.fetch(tables_query, *params)
        suggestions["tables"] = [t["table_name"] for t in tables]
        
        # Get columns for each table
        for table in tables:
            table_name = table["table_name"]
            columns_query = """
                SELECT column_name, data_type
                FROM information_schema.columns
                WHERE table_schema = 'public'
                  AND table_name = $1
                ORDER BY ordinal_position
            """
            
            columns = await db.fetch(columns_query, table_name)
            suggestions["columns"][table_name] = [
                {"name": c["column_name"], "type": c["data_type"]} 
                for c in columns
            ]
        
        return suggestions
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching suggestions: {str(e)}")


class InsertRecordRequest(BaseModel):
    table_name: str
    data: Dict[str, Any]


class UpdateRecordRequest(BaseModel):
    table_name: str
    record_id: Any
    updates: Dict[str, Any]


class DeleteRecordRequest(BaseModel):
    table_name: str
    record_id: Any


@router.post("/records")
async def insert_record(
    payload: InsertRecordRequest,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee"])),
    db=Depends(get_db),
):
    """
    Insert a new record into a table.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    try:
        # Verify table exists
        table_check = await db.fetchrow(
            """
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'public'
              AND table_name = $1
              AND table_type = 'BASE TABLE'
            """,
            payload.table_name
        )
        
        if not table_check:
            raise HTTPException(status_code=404, detail=f"Table '{payload.table_name}' not found")

        # Get table columns to validate
        columns_query = """
            SELECT column_name, data_type, is_nullable, column_default
            FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name = $1
            ORDER BY ordinal_position
        """
        table_columns = await db.fetch(columns_query, payload.table_name)
        column_names = [col["column_name"] for col in table_columns]
        
        # Validate all provided columns exist
        invalid_columns = [col for col in payload.data.keys() if col not in column_names]
        if invalid_columns:
            raise HTTPException(status_code=400, detail=f"Invalid columns: {', '.join(invalid_columns)}")

        # Build INSERT query
        fields = list(payload.data.keys())
        placeholders = ', '.join([f'${i+1}' for i in range(len(fields))])
        fields_str = ', '.join([f'"{field}"' for field in fields])
        
        query = f'INSERT INTO public."{payload.table_name}" ({fields_str}) VALUES ({placeholders}) RETURNING *'
        
        values = [payload.data[field] for field in fields]
        new_record = await db.fetchrow(query, *values)
        
        return {
            "message": "Record inserted successfully",
            "record": dict(new_record)
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error inserting record: {str(e)}")


def convert_value_for_db(value: Any, data_type: str) -> Any:
    """
    Convert value to appropriate Python type for asyncpg based on PostgreSQL data type.
    Handles datetime, date, and other type conversions.
    """
    if value is None:
        return None
    
    data_type_lower = data_type.lower() if data_type else ''
    
    # Handle datetime/timestamp types
    if 'timestamp' in data_type_lower or 'datetime' in data_type_lower:
        if isinstance(value, str):
            try:
                # Try parsing ISO format datetime string
                # Handle both with and without microseconds
                if 'T' in value:
                    # ISO format: 2026-01-17T01:47:18.915180 or 2026-01-17T01:47:18
                    if '.' in value:
                        # With microseconds
                        return datetime.fromisoformat(value.replace('Z', '+00:00'))
                    else:
                        # Without microseconds
                        return datetime.fromisoformat(value.replace('Z', '+00:00'))
                else:
                    # Date only format
                    return datetime.strptime(value, '%Y-%m-%d')
            except (ValueError, AttributeError):
                # If parsing fails, try common formats
                for fmt in ['%Y-%m-%d %H:%M:%S', '%Y-%m-%d %H:%M:%S.%f', '%Y-%m-%d']:
                    try:
                        return datetime.strptime(value, fmt)
                    except ValueError:
                        continue
                # If all parsing fails, return as is and let asyncpg handle it
                return value
        elif isinstance(value, datetime):
            return value
        else:
            return value
    
    # Handle date types
    elif 'date' in data_type_lower and 'time' not in data_type_lower:
        if isinstance(value, str):
            try:
                return date.fromisoformat(value.split('T')[0])  # Extract date part if datetime string
            except (ValueError, AttributeError):
                try:
                    return date.strptime(value, '%Y-%m-%d')
                except ValueError:
                    return value
        elif isinstance(value, date):
            return value
        elif isinstance(value, datetime):
            return value.date()
        else:
            return value
    
    # Handle boolean types
    elif 'bool' in data_type_lower:
        if isinstance(value, bool):
            return value
        if isinstance(value, str):
            return value.lower() in ('true', '1', 'yes', 'on')
        if isinstance(value, (int, float)):
            return bool(value)
        return value
    
    # Handle numeric types
    elif any(t in data_type_lower for t in ['int', 'numeric', 'decimal', 'real', 'double', 'float']):
        if isinstance(value, (int, float)):
            return value
        if isinstance(value, str):
            try:
                if '.' in value:
                    return float(value)
                else:
                    return int(value)
            except ValueError:
                return value
        return value
    
    # For other types, return as is
    return value


@router.put("/records")
async def update_record(
    payload: UpdateRecordRequest,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee"])),
    db=Depends(get_db),
):
    """
    Update a record in a table.
    Only modified fields are sent in the updates dict.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    try:
        # Verify table exists
        table_check = await db.fetchrow(
            """
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'public'
              AND table_name = $1
              AND table_type = 'BASE TABLE'
            """,
            payload.table_name
        )
        
        if not table_check:
            raise HTTPException(status_code=404, detail=f"Table '{payload.table_name}' not found")

        # Get primary key columns
        pk_query = """
            SELECT 
                kcu.column_name
            FROM information_schema.table_constraints tc
            JOIN information_schema.key_column_usage kcu 
                ON tc.constraint_name = kcu.constraint_name
                AND tc.table_schema = kcu.table_schema
            WHERE tc.table_schema = 'public'
              AND tc.table_name = $1
              AND tc.constraint_type = 'PRIMARY KEY'
            ORDER BY kcu.ordinal_position
        """
        
        pk_columns = await db.fetch(pk_query, payload.table_name)
        
        if not pk_columns:
            raise HTTPException(status_code=400, detail=f"Table '{payload.table_name}' does not have a primary key")

        primary_key_col = pk_columns[0]["column_name"]
        
        # Get column data types for conversion
        columns_query = """
            SELECT column_name, data_type
            FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name = $1
        """
        table_columns = await db.fetch(columns_query, payload.table_name)
        column_types = {col["column_name"]: col["data_type"] for col in table_columns}
        
        # Build UPDATE query
        update_fields = list(payload.updates.keys())
        if not update_fields:
            raise HTTPException(status_code=400, detail="No fields to update")
        
        # Validate all provided columns exist
        invalid_columns = [col for col in update_fields if col not in column_types]
        if invalid_columns:
            raise HTTPException(status_code=400, detail=f"Invalid columns: {', '.join(invalid_columns)}")
        
        set_clause = ", ".join([f'"{field}" = ${i+2}' for i, field in enumerate(update_fields)])
        where_clause = f'"{primary_key_col}" = $1'
        
        query = f'UPDATE public."{payload.table_name}" SET {set_clause} WHERE {where_clause} RETURNING *'
        
        # Convert values to appropriate types for asyncpg
        converted_values = []
        for field in update_fields:
            data_type = column_types.get(field, '')
            value = payload.updates[field]
            converted_value = convert_value_for_db(value, data_type)
            converted_values.append(converted_value)
        
        params = [payload.record_id] + converted_values
        
        updated_record = await db.fetchrow(query, *params)
        
        if not updated_record:
            raise HTTPException(status_code=404, detail="Record not found or could not be updated")
        
        return {
            "message": "Record updated successfully",
            "record": dict(updated_record)
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error updating record: {str(e)}")


@router.delete("/records")
async def delete_record(
    table_name: str = Query(..., description="Table name"),
    record_id: str = Query(..., description="Primary key value"),
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee"])),
    db=Depends(get_db),
):
    """
    Delete a record from a table.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")

    try:
        # Verify table exists
        table_check = await db.fetchrow(
            """
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'public'
              AND table_name = $1
              AND table_type = 'BASE TABLE'
            """,
            table_name
        )
        
        if not table_check:
            raise HTTPException(status_code=404, detail=f"Table '{table_name}' not found")

        # Get primary key column
        pk_query = """
            SELECT 
                kcu.column_name
            FROM information_schema.table_constraints tc
            JOIN information_schema.key_column_usage kcu 
                ON tc.constraint_name = kcu.constraint_name
                AND tc.table_schema = kcu.table_schema
            WHERE tc.table_schema = 'public'
              AND tc.table_name = $1
              AND tc.constraint_type = 'PRIMARY KEY'
            ORDER BY kcu.ordinal_position
        """
        
        pk_columns = await db.fetch(pk_query, table_name)
        
        if not pk_columns:
            raise HTTPException(status_code=400, detail=f"Table '{table_name}' does not have a primary key")

        primary_key_col = pk_columns[0]["column_name"]
        
        # Build DELETE query
        query = f'DELETE FROM public."{table_name}" WHERE "{primary_key_col}" = $1 RETURNING *'
        
        deleted_record = await db.fetchrow(query, record_id)
        
        if not deleted_record:
            raise HTTPException(status_code=404, detail="Record not found")
        
        return {
            "message": "Record deleted successfully",
            "record": dict(deleted_record)
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error deleting record: {str(e)}")
