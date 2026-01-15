import os
import asyncpg
from typing import List, Dict, Any, Optional
from errors import ERPError, ErrorType

class PostgresDB:
    _pool: Optional[asyncpg.Pool] = None

    @classmethod
    async def connect(cls):
        """Initializes the connection pool singleton."""
        if cls._pool is None:
            try:
                cls._pool = await asyncpg.create_pool(
                    user=os.getenv("POSTGRES_USER"),
                    password=os.getenv("POSTGRES_PASSWORD"),
                    database=os.getenv("POSTGRES_DATABASE"),
                    host=os.getenv("POSTGRES_HOST"),
                    port=os.getenv("POSTGRES_PORT"),
                    min_size=1,
                    max_size=10
                )
            except Exception as e:
                # Log critical failure here
                raise ERPError(e, ErrorType.DATABASE_CONNECTION_FAILED, {"context": "PostgresDB.connect"})

    @classmethod
    async def close(cls):
        """Closes the connection pool."""
        if cls._pool:
            await cls._pool.close()
            cls._pool = None

    @classmethod
    async def fetch(cls, query: str, *args) -> List[Dict[str, Any]]:
        """
        Executes a SELECT query and returns a list of dictionaries.
        Encourages parameterized queries using $1, $2, etc.
        """
        if not cls._pool:
            raise ERPError(None, ErrorType.DATABASE_CONNECTION_FAILED, {"message": "Pool not initialized"})

        async with cls._pool.acquire() as conn:
            try:
                records = await conn.fetch(query, *args)
                return [dict(record) for record in records]
            except Exception as e:
                raise ERPError(e, ErrorType.DATABASE_QUERY_EXECUTION_FAILED, {"query": query, "args": args})

    @classmethod
    async def fetchrow(cls, query: str, *args) -> Optional[Dict[str, Any]]:
        """
        Executes a SELECT query and returns a single dictionary (or None).
        """
        if not cls._pool:
            raise ERPError(None, ErrorType.DATABASE_CONNECTION_FAILED, {"message": "Pool not initialized"})

        async with cls._pool.acquire() as conn:
            try:
                record = await conn.fetchrow(query, *args)
                return dict(record) if record else None
            except Exception as e:
                raise ERPError(e, ErrorType.DATABASE_QUERY_EXECUTION_FAILED, {"query": query, "args": args})

    @classmethod
    async def execute(cls, query: str, *args) -> str:
        """
        Executes INSERT/UPDATE/DELETE queries.
        Returns the command status tag (e.g., "INSERT 0 1").
        """
        if not cls._pool:
            raise ERPError(None, ErrorType.DATABASE_CONNECTION_FAILED, {"message": "Pool not initialized"})

        async with cls._pool.acquire() as conn:
            try:
                return await conn.execute(query, *args)
            except Exception as e:
                # Catch IntegrityErrors (Unique constraints etc) specifically if needed
                raise ERPError(e, ErrorType.DATABASE_QUERY_EXECUTION_FAILED, {"query": query, "args": args})

    @classmethod
    async def executemany(cls, query: str, args_list: List[tuple]):
        """
        Executes batch operations efficiently.
        """
        if not cls._pool:
            raise ERPError(None, ErrorType.DATABASE_CONNECTION_FAILED, {"message": "Pool not initialized"})

        async with cls._pool.acquire() as conn:
            try:
                await conn.executemany(query, args_list)
            except Exception as e:
                raise ERPError(e, ErrorType.DATABASE_QUERY_EXECUTION_FAILED, {"query": query})
