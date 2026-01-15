from classes.postgres_db import PostgresDB

async def get_db():
    return PostgresDB

async def get_db_cli():
    """CLI helper to ensure DB is connected."""
    await PostgresDB.connect()
    return PostgresDB

async def close_db_cli(db_class):
    """CLI helper to close DB connection."""
    await db_class.close()

