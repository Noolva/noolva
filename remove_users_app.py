#!/usr/bin/env python3
"""
Script to remove "users" app and all related menus from the database.
Since users functionality is now in the Organization app.
"""

import asyncio
import os
import sys
from pathlib import Path

# Add the api/app directory to the path
sys.path.insert(0, str(Path(__file__).parent / "api" / "app"))

from classes.postgres_db import PostgresDB


async def remove_users_app():
    """Remove users app and all related menus from the database."""
    try:
        # Connect to database
        await PostgresDB.connect()
        print("Connected to database")

        # Step 1: Get the users app_id
        users_app = await PostgresDB.fetchrow(
            """
            SELECT app_id 
            FROM public.apps 
            WHERE app_name = 'users' 
              AND tenant_id IS NULL 
              AND company_id IS NULL
            """
        )

        if not users_app:
            print("Users app not found in database. Nothing to remove.")
            return

        app_id = users_app["app_id"]
        print(f"Found users app with app_id: {app_id}")

        # Step 2: Get all menu_ids associated with the users app
        menus = await PostgresDB.fetch(
            """
            SELECT menu_id, menu_title
            FROM public.menus 
            WHERE app_id = $1
            """,
            app_id
        )
        menu_ids = [m["menu_id"] for m in menus]
        print(f"Found {len(menu_ids)} menus associated with users app: {[m['menu_title'] for m in menus]}")

        # Step 3: Delete menu permissions for all menus associated with the users app
        if menu_ids:
            deleted_permissions = await PostgresDB.execute(
                """
                DELETE FROM public.menu_permissions
                WHERE menu_id = ANY($1::int[])
                """,
                menu_ids
            )
            print(f"Deleted menu permissions: {deleted_permissions}")

        # Step 4: Delete all menus associated with the users app
        if menu_ids:
            deleted_menus = await PostgresDB.execute(
                """
                DELETE FROM public.menus
                WHERE app_id = $1
                """,
                app_id
            )
            print(f"Deleted menus: {deleted_menus}")

        # Step 5: Delete the users app from the apps table
        deleted_app = await PostgresDB.execute(
            """
            DELETE FROM public.apps
            WHERE app_id = $1
            """,
            app_id
        )
        print(f"Deleted users app: {deleted_app}")

        print("\n✓ Successfully removed users app and all related data from the database!")

    except Exception as e:
        print(f"\n✗ Error removing users app: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
    finally:
        await PostgresDB.close()
        print("Database connection closed")


if __name__ == "__main__":
    # Check if required environment variables are set
    required_vars = ["POSTGRES_USER", "POSTGRES_PASSWORD", "POSTGRES_DATABASE", "POSTGRES_HOST", "POSTGRES_PORT"]
    missing_vars = [var for var in required_vars if not os.getenv(var)]
    
    if missing_vars:
        print(f"Error: Missing required environment variables: {', '.join(missing_vars)}")
        print("\nPlease set these environment variables before running the script.")
        sys.exit(1)

    asyncio.run(remove_users_app())
