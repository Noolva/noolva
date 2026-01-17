# cli.py
import typer
import os
import sys
import logging
from datetime import datetime
from dotenv import load_dotenv
load_dotenv()
from main import app
import asyncio
import uvicorn
from fastapi import HTTPException
from models.authentication.saas_login_model import saas_login_model, saas_resetpassword
from models.authentication.login_service import LoginService
from utils.db import get_db_cli, close_db_cli
from middlewares import auth
from typing import Optional
import psycopg2
import json
import mimetypes
from pathlib import Path

# Setup CLI logger
LOG_DIR = os.getenv("LOG_DIR", "logs")
os.makedirs(LOG_DIR, exist_ok=True)
LOG_FILE = os.path.join(LOG_DIR, "noolva.log")

# Configure CLI logging to same file
cli_logger = logging.getLogger("noolva_cli")
if not cli_logger.handlers:
    from logging.handlers import RotatingFileHandler
    handler = RotatingFileHandler(LOG_FILE, maxBytes=10*1024*1024, backupCount=5)
    handler.setFormatter(logging.Formatter('%(asctime)s - %(levelname)s - CLI - %(message)s'))
    cli_logger.addHandler(handler)
    cli_logger.setLevel(logging.INFO)

cli = typer.Typer()
AUTH_FILE = os.path.expanduser("~/.fastapi_erp_token")
VERSION = "1.0.0"

def get_saved_token() -> str:
    if os.path.exists(AUTH_FILE):
        with open(AUTH_FILE, "r") as f:
            return f.read().strip()
    typer.echo("Not logged in. Run `python cli.py login` first.", err=True)
    raise typer.Exit()

@cli.command()
def runserver(
    host: str = typer.Option("0.0.0.0", "--host", "-h", help="Host to bind to"),
    port: int = typer.Option(int(os.getenv("APPLICATION_PORT", "9001")), "--port", "-p", help="Port to bind to")
):
    """Start the FastAPI ERP server."""
    typer.echo(f"📝 Logs will be written to: {LOG_FILE}")
    cli_logger.info(f"CLI - runserver - Starting server on {host}:{port}")
    uvicorn.run("main:app", host=host, port=port, reload=True, log_config=None, access_log=False)
@cli.command()
def login(
    username: str = typer.Option(None, "--username", "-u", prompt=True, help="Your username"),
    password: str = typer.Option(None, "--password", "-p", prompt=True, hide_input=True, help="Your password")
):
    """Login with username and password."""
    async def do_login():
        db=await get_db_cli()
        response = await saas_login_model(None,data={"username": username, "password": password},db=db)
        await close_db_cli(db)
        if response["status"] == 1:
            typer.echo("Login successful!")
            typer.echo(f"User: {response['data']['user']}")
            typer.echo(f"Token: {response['data']['access_token']}")
            token = response['data']['access_token']
            with open(AUTH_FILE, "w") as f:
                f.write(token)
            cli_logger.info(f"CLI - login - Login successful for user: {username}")
        else:
            typer.echo("Login failed:", err=True)
            typer.echo(response["message"], err=True)
            cli_logger.warning(f"CLI - login - Login failed for user: {username}")

    asyncio.run(do_login())
@cli.command()
def logout():
    """Remove saved login token."""
    if os.path.exists(AUTH_FILE):
        os.remove(AUTH_FILE)
        typer.echo("Logged out.")
        cli_logger.info("CLI - logout - User logged out")
    else:
        typer.echo("Already logged out.")
@cli.command()
def resetpass():
    """Reset a user's password (requires root password)."""
    expected_root_password = os.getenv("APP_ROOT_PASSWORD")

    if not expected_root_password:
        typer.echo("Root password not set in environment.", err=True)
        raise typer.Exit(code=1)

    root_password = typer.prompt("Root password", hide_input=True)

    if root_password != expected_root_password:
        typer.echo("Root password incorrect.", err=True)
        raise typer.Exit(code=1)

    username = typer.prompt("Username to reset password for")
    new_password = typer.prompt("New password", hide_input=True)
    confirm_password = typer.prompt("Confirm password", hide_input=True)

    if new_password != confirm_password:
        typer.echo("Passwords do not match.", err=True)
        raise typer.Exit(code=1)

    async def do_reset():
        db = await get_db_cli()
        try:
            # Check if user exists
            user = await db.fetchrow("SELECT user_id FROM public.users WHERE username = $1", username)
            if not user:
                typer.echo(f"User '{username}' not found.", err=True)
                raise typer.Exit(code=1)
            
            # Hash password before storing
            hashed_password = LoginService.get_password_hash(new_password)
            await db.execute(
                "UPDATE public.users SET password = $1, last_updated = CURRENT_TIMESTAMP WHERE username = $2",
                hashed_password, username
            )
            typer.echo(f"✅ Password reset successful for user: {username}")
        except Exception as e:
            typer.echo(f"❌ Password reset failed: {str(e)}", err=True)
            raise typer.Exit(code=1)
        finally:
            await close_db_cli(db)

    asyncio.run(do_reset())

@cli.command()
def reset_admin_password(
    username: str = typer.Option("admin", "--username", "-u", help="Admin username"),
):
    """Reset admin user password (requires root password)."""
    expected_root_password = os.getenv("APP_ROOT_PASSWORD")

    if not expected_root_password:
        typer.echo("❌ Root password not set in environment.", err=True)
        typer.echo("Set APP_ROOT_PASSWORD in your .env file.", err=True)
        raise typer.Exit(code=1)

    root_password = typer.prompt("Root password", hide_input=True)

    if root_password != expected_root_password:
        typer.echo("❌ Root password incorrect.", err=True)
        raise typer.Exit(code=1)

    new_password = typer.prompt("New password", hide_input=True)
    confirm_password = typer.prompt("Confirm password", hide_input=True)

    if new_password != confirm_password:
        typer.echo("❌ Passwords do not match.", err=True)
        raise typer.Exit(code=1)

    async def do_reset():
        db = await get_db_cli()
        try:
            # Check if user exists and is admin
            user = await db.fetchrow(
                "SELECT user_id, user_type FROM public.users WHERE username = $1",
                username
            )
            if not user:
                typer.echo(f"❌ User '{username}' not found.", err=True)
                raise typer.Exit(code=1)
            
            if user['user_type'] not in ['saas_admin', 'system']:
                typer.echo(f"⚠️  User '{username}' is not an admin user (type: {user['user_type']}).", err=True)
                if not typer.confirm("Continue anyway?"):
                    raise typer.Exit(code=1)
            
            # Hash password before storing
            hashed_password = LoginService.get_password_hash(new_password)
            await db.execute(
                "UPDATE public.users SET password = $1, last_updated = CURRENT_TIMESTAMP WHERE username = $2",
                hashed_password, username
            )
            typer.echo(f"✅ Password reset successful for admin user: {username}")
        except typer.Exit:
            raise
        except Exception as e:
            typer.echo(f"❌ Password reset failed: {str(e)}", err=True)
            raise typer.Exit(code=1)
        finally:
            await close_db_cli(db)

    asyncio.run(do_reset())

def _execute_sql_file(file_path: str, db_config: dict):
    """Execute SQL file using psycopg2 (handles multi-statement files properly)."""
    conn = None
    try:
        conn = psycopg2.connect(
            host=db_config['host'],
            port=db_config['port'],
            user=db_config['user'],
            password=db_config['password'],
            database=db_config['database']
        )
        conn.autocommit = False
        cursor = conn.cursor()
        
        with open(file_path, 'r', encoding='utf-8') as f:
            sql_content = f.read()
        
        # Execute SQL file - psycopg2 handles multi-statement files
        cursor.execute(sql_content)
        conn.commit()
        cursor.close()
        conn.close()
        return True
    except Exception as e:
        if conn:
            conn.rollback()
            conn.close()
        raise e

async def _is_db_setup(db) -> bool:
    """Check if database is already set up by checking for key tables."""
    key_tables = ['users', 'tenants', 'companies', 'apps', 'roles']
    for table in key_tables:
        result = await db.fetchrow(
            "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = $1)",
            table
        )
        if not result or not result.get('exists'):
            return False
    return True

@cli.command()
def setup(
    admin_user: str = typer.Option("admin", "--admin", "-a", help="Admin username"),
    admin_pass: str = typer.Option(None, "--password", "-p", help="Admin password (will prompt if not provided)"),
    force: bool = typer.Option(False, "--force", "-f", help="Force setup even if DB is already initialized")
):
    """Initial setup: Create tables and default users."""
    async def do_setup():
        # First validate environment
        required_vars = ["POSTGRES_HOST", "POSTGRES_USER", "POSTGRES_PASSWORD", "POSTGRES_DATABASE", "POSTGRES_PORT"]
        missing = [v for v in required_vars if not os.getenv(v)]
        if missing:
            typer.echo(f"❌ Missing required environment variables: {', '.join(missing)}", err=True)
            typer.echo("Please set them in your .env file.", err=True)
            raise typer.Exit(code=1)
        
        # Ensure ENCRYPTION_KEY is set (will auto-generate if not present)
        if not os.getenv("ENCRYPTION_KEY"):
            typer.echo("ℹ️  ENCRYPTION_KEY not found. Generating and saving to .env file...")
            try:
                from utils.encryption_service import EncryptionService
                # This will auto-generate and save the key
                EncryptionService._get_or_create_encryption_key()
                # Reload .env to get the new key
                from dotenv import load_dotenv
                load_dotenv(override=True)
                typer.echo("✅ Encryption key generated and saved to .env file.")
            except Exception as e:
                typer.echo(f"⚠️  Could not auto-generate encryption key: {str(e)}", err=True)
                typer.echo("   You may need to set ENCRYPTION_KEY manually in .env file.", err=True)

        db = await get_db_cli()
        try:
            # 1. Check if DB is already setup
            is_setup = await _is_db_setup(db)
            
            if is_setup and not force:
                typer.echo("✅ Database already initialized.")
                if not typer.confirm("Do you want to continue with user creation?"):
                    typer.echo("Setup cancelled.")
                    return
            else:
                if force:
                    typer.echo("⚠️  Force flag set. Proceeding with setup...")
                
                typer.echo("Initializing database schema...")
                schema_path = os.path.join(os.path.dirname(__file__), "..", "..", "db-structure", "noolvandb_schema.sql")
                feeds_path = os.path.join(os.path.dirname(__file__), "..", "..", "db-structure", "noolvandb_feeds.sql")
                
                if not os.path.exists(schema_path):
                    typer.echo(f"❌ Schema file not found at {schema_path}", err=True)
                    raise typer.Exit(code=1)
                
                if not os.path.exists(feeds_path):
                    typer.echo(f"❌ Feeds file not found at {feeds_path}", err=True)
                    raise typer.Exit(code=1)
                
                # Execute SQL file using psycopg2 (handles multi-statement files)
                db_config = {
                    'host': os.getenv("POSTGRES_HOST"),
                    'port': os.getenv("POSTGRES_PORT"),
                    'user': os.getenv("POSTGRES_USER"),
                    'password': os.getenv("POSTGRES_PASSWORD"),
                    'database': os.getenv("POSTGRES_DATABASE")
                }
                
                try:
                    _execute_sql_file(schema_path, db_config)
                    typer.echo("✅ Schema created successfully.")
                    cli_logger.info("CLI - setup-db - Schema created successfully")
                    
                    _execute_sql_file(feeds_path, db_config)
                    typer.echo("✅ Essential feeds loaded successfully.")
                    cli_logger.info("CLI - setup-db - Essential feeds loaded successfully")
                    
                    # Ask if sample feeds are required
                    if typer.confirm("\nDo you want to load sample feeds (AI model, actions)?", default=False):
                        sample_feeds_dir = os.path.join(os.path.dirname(__file__), "..", "..", "db-structure", "sample_feeds")
                        if os.path.exists(sample_feeds_dir):
                            sample_files = sorted([f for f in os.listdir(sample_feeds_dir) if f.endswith('.sql')])
                            if sample_files:
                                typer.echo(f"Loading {len(sample_files)} sample feed file(s)...")
                                for feed_file in sample_files:
                                    feed_path = os.path.join(sample_feeds_dir, feed_file)
                                    try:
                                        _execute_sql_file(feed_path, db_config)
                                        typer.echo(f"✅ Loaded {feed_file}")
                                        cli_logger.info(f"CLI - setup-db - Loaded sample feed: {feed_file}")
                                    except Exception as e:
                                        typer.echo(f"⚠️  Failed to load {feed_file}: {str(e)}", err=True)
                                        cli_logger.error(f"CLI - setup-db - Failed to load {feed_file}: {str(e)}")
                                typer.echo("✅ Sample feeds loaded successfully.")
                                cli_logger.info("CLI - setup-db - Sample feeds loaded successfully")
                            else:
                                typer.echo("⚠️  No sample feed files found in sample_feeds directory.")
                        else:
                            typer.echo("⚠️  Sample feeds directory not found.")
                except Exception as e:
                    typer.echo(f"❌ SQL execution failed: {str(e)}", err=True)
                    cli_logger.error(f"CLI - setup-db - SQL execution failed: {str(e)}")
                    raise typer.Exit(code=1)

            # 2. Check for system user
            system_user = await db.fetchrow("SELECT user_id FROM public.users WHERE user_type = 'system'")
            if not system_user:
                typer.echo("Creating system user...")
                # System user password is not hashed (internal use only)
                await db.execute(
                    "INSERT INTO public.users (username, password, user_type, is_super_admin) VALUES ($1, $2, $3, $4)",
                    "system", "system_internal_locked", "system", True
                )
                typer.echo("✅ System user created.")

            # 3. Create Admin user
            admin_username = admin_user
            admin_password = admin_pass
            if not admin_password:
                admin_password = typer.prompt("Enter password for admin user", hide_input=True)
                confirm_password = typer.prompt("Confirm password", hide_input=True)
                if admin_password != confirm_password:
                    typer.echo("❌ Passwords do not match.", err=True)
                    raise typer.Exit(code=1)

            existing_admin = await db.fetchrow("SELECT user_id FROM public.users WHERE username = $1", admin_username)
            if existing_admin:
                typer.echo(f"⚠️  Admin user '{admin_username}' already exists.")
                if typer.confirm("Do you want to update the password?"):
                    hashed_password = LoginService.get_password_hash(admin_password)
                    await db.execute(
                        "UPDATE public.users SET password = $1, last_updated = CURRENT_TIMESTAMP WHERE username = $2",
                        hashed_password, admin_username
                    )
                    typer.echo(f"✅ Admin user '{admin_username}' password updated.")
                    cli_logger.info(f"CLI - setup-db - Admin user '{admin_username}' password updated")
            else:
                typer.echo(f"Creating admin user '{admin_username}'...")
                hashed_password = LoginService.get_password_hash(admin_password)
                await db.execute(
                    "INSERT INTO public.users (username, password, user_type, is_super_admin) VALUES ($1, $2, $3, $4)",
                    admin_username, hashed_password, "saas_admin", True
                )
                typer.echo(f"✅ Admin user '{admin_username}' created.")
                cli_logger.info(f"CLI - setup-db - Admin user '{admin_username}' created")
            
            # 4. Setup S3 Integration (Required for assets)
            typer.echo("\n" + "="*60)
            typer.echo("S3 Bucket Configuration (Required for Asset Storage)")
            typer.echo("="*60)
            
            if not typer.confirm("Do you want to configure S3 bucket for asset storage?", default=True):
                typer.echo("⚠️  S3 configuration skipped. You can configure it later.")
                typer.echo("   Assets will be stored locally until S3 is configured.")
            else:
                # Get S3 configuration
                aws_access_key_id = typer.prompt("AWS Access Key ID")
                aws_secret_access_key = typer.prompt("AWS Secret Access Key", hide_input=True)
                bucket_name = typer.prompt("S3 Bucket Name")
                aws_region = typer.prompt("AWS Region", default="us-east-1")
                
                # Bucket prefix/folder
                bucket_prefix = typer.prompt("Bucket Prefix/Folder (optional, e.g., 'production', 'staging'. Press Enter to skip)", default="", show_default=False)
                if not bucket_prefix or bucket_prefix.strip() == "":
                    bucket_prefix = None
                else:
                    bucket_prefix = bucket_prefix.strip()
                
                # Optional fields
                typer.echo("\nNote: Custom Endpoint URL is only for S3-compatible services (e.g., MinIO, DigitalOcean Spaces).")
                typer.echo("      For AWS S3, leave this empty.")
                endpoint_url = typer.prompt("Custom Endpoint URL (optional, press Enter to skip)", default="", show_default=False)
                if not endpoint_url or endpoint_url.strip() == "":
                    endpoint_url = None
                else:
                    endpoint_url = endpoint_url.strip()
                    # Warn if it looks like a bucket URL
                    if 's3.' in endpoint_url and '.amazonaws.com' in endpoint_url:
                        typer.echo("⚠️  Warning: This looks like a bucket URL, not an endpoint URL.", err=True)
                        typer.echo("   For AWS S3, endpoint URL should be empty. Continuing anyway...", err=True)
                
                cdn_url = typer.prompt("CDN URL for public assets (optional, press Enter to skip)", default="", show_default=False)
                if not cdn_url:
                    cdn_url = None
                
                # Test S3 connection
                typer.echo("\nTesting S3 connection...")
                try:
                    from utils.s3_service import S3Service
                    s3_service = S3Service(
                        access_key_id=aws_access_key_id,
                        secret_access_key=aws_secret_access_key,
                        bucket_name=bucket_name,
                        region=aws_region,
                        endpoint_url=endpoint_url,
                        cdn_url=cdn_url,
                        bucket_prefix=bucket_prefix
                    )
                    test_result = s3_service.test_connection()
                    
                    if not test_result.get('success'):
                        typer.echo(f"❌ S3 connection test failed: {test_result.get('message')}", err=True)
                        
                        # Show suggestions if available
                        if 'suggestions' in test_result:
                            typer.echo("\nSuggestions:", err=True)
                            for suggestion in test_result.get('suggestions', []):
                                typer.echo(f"  • {suggestion}", err=True)
                        
                        # Show error details
                        if 'error' in test_result:
                            typer.echo(f"\nError details: {test_result.get('error')}", err=True)
                        
                        if not typer.confirm("\nContinue anyway? (You can configure S3 later)"):
                            typer.echo("Setup cancelled.")
                            return
                    else:
                        typer.echo(f"✅ S3 connection test successful!")
                        typer.echo(f"   Bucket: {bucket_name}")
                        typer.echo(f"   Region: {aws_region}")
                        
                        # Get provider_id for aws_s3
                        provider = await db.fetchrow(
                            "SELECT provider_id FROM public.integration_providers WHERE provider_name = $1",
                            'aws_s3'
                        )
                        
                        if not provider:
                            typer.echo("⚠️  AWS S3 provider not found in integration_providers. Skipping integration creation.")
                            typer.echo("   Make sure to load integration_providers seed data.")
                        else:
                            # Get system user for created_by
                            system_user = await db.fetchrow("SELECT user_id FROM public.users WHERE user_type = 'system'")
                            system_user_id = system_user['user_id'] if system_user else None
                            
                            # Get first company (or create a default one if needed)
                            company = await db.fetchrow("SELECT company_id FROM public.companies LIMIT 1")
                            
                            if company:
                                company_id = company['company_id']
                                
                                # Encrypt credentials
                                from utils.encryption_service import get_encryption_service
                                encryption_service = get_encryption_service()
                                credentials = {
                                    'aws_access_key_id': aws_access_key_id,
                                    'aws_secret_access_key': aws_secret_access_key,
                                    'bucket_name': bucket_name,
                                    'aws_region': aws_region
                                }
                                if bucket_prefix:
                                    credentials['bucket_prefix'] = bucket_prefix
                                if endpoint_url:
                                    credentials['endpoint_url'] = endpoint_url
                                if cdn_url:
                                    credentials['cdn_url'] = cdn_url
                                
                                encrypted_credentials = encryption_service.encrypt(credentials)
                                
                                # Create integration
                                await db.execute(
                                    """
                                    INSERT INTO public.integrations 
                                    (company_id, provider_id, provider_name, integration_name, 
                                     encrypted_credentials, config, integration_type, is_default, created_by)
                                    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
                                    ON CONFLICT DO NOTHING
                                    """,
                                    company_id,
                                    provider['provider_id'],
                                    'aws_s3',
                                    'Default S3 Bucket',
                                    encrypted_credentials,
                                    json.dumps({
                                        'bucket_name': bucket_name,
                                        'region': aws_region,
                                        'bucket_prefix': bucket_prefix
                                    }),
                                    'api',
                                    True,
                                    system_user_id
                                )
                                
                                typer.echo("✅ S3 integration created successfully.")
                                
                                # Upload assets to S3
                                typer.echo("\nUploading assets to S3...")
                                # Assets directory is at api/assets (one level up from app/)
                                assets_dir = os.path.join(os.path.dirname(__file__), "..", "assets")
                                assets_dir = os.path.abspath(assets_dir)
                                assets_manifest_path = os.path.join(assets_dir, "assets_manifest.json")
                                
                                if os.path.exists(assets_dir) and os.path.exists(assets_manifest_path):
                                    try:
                                        with open(assets_manifest_path, 'r') as f:
                                            assets_manifest = json.load(f)
                                        
                                        uploaded_count = 0
                                        for asset_entry in assets_manifest.get('assets', []):
                                            file_name = asset_entry.get('file_name')
                                            file_path = os.path.join(assets_dir, file_name)
                                            
                                            if os.path.exists(file_path):
                                                # Upload to assets/ folder (will be under bucket_prefix if set)
                                                s3_key = f"assets/{file_name}"
                                                is_public = asset_entry.get('is_public', False)
                                                content_type = asset_entry.get('mime_type') or mimetypes.guess_type(file_path)[0] or 'application/octet-stream'
                                                
                                                upload_result = s3_service.upload_file(
                                                    file_path=file_path,
                                                    s3_key=s3_key,
                                                    is_public=is_public,
                                                    content_type=content_type
                                                )
                                                
                                                if upload_result.get('success'):
                                                    # Insert into assets table
                                                    # Use the full S3 key (with prefix) for storage_path
                                                    full_s3_key = upload_result.get('s3_key', s3_key)
                                                    
                                                    # Show warning if ACL is not supported
                                                    if upload_result.get('acl_warning'):
                                                        typer.echo(f"  ⚠️  Uploaded {file_name} (ACLs not supported - ensure bucket policy allows public read)")
                                                    
                                                    await db.execute(
                                                        """
                                                        INSERT INTO public.assets 
                                                        (company_id, file_name, original_name, mime_type, file_size,
                                                         storage_provider, storage_path, public_url, is_public, uploaded_by)
                                                        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
                                                        """,
                                                        company_id,
                                                        file_name,
                                                        asset_entry.get('original_name', file_name),
                                                        content_type,
                                                        os.path.getsize(file_path),
                                                        's3',
                                                        full_s3_key,
                                                        upload_result.get('public_url'),
                                                        is_public,
                                                        system_user_id
                                                    )
                                                    uploaded_count += 1
                                                    typer.echo(f"  ✅ Uploaded: {file_name}")
                                                else:
                                                    typer.echo(f"  ⚠️  Failed to upload {file_name}: {upload_result.get('message')}", err=True)
                                        
                                        typer.echo(f"\n✅ Uploaded {uploaded_count} asset(s) to S3.")
                                        cli_logger.info(f"CLI - setup - Uploaded {uploaded_count} assets to S3")
                                    except Exception as e:
                                        typer.echo(f"⚠️  Failed to upload assets: {str(e)}", err=True)
                                        cli_logger.error(f"CLI - setup - Failed to upload assets: {str(e)}")
                                else:
                                    typer.echo("ℹ️  No assets directory or manifest found. Skipping asset upload.")
                            else:
                                typer.echo("⚠️  No company found. Skipping S3 integration creation.")
                                typer.echo("   Create a company first, then configure S3 integration.")
                except ImportError:
                    typer.echo("⚠️  S3 service not available. Install boto3: pip install boto3", err=True)
                    typer.echo("   Skipping S3 configuration.")
                except Exception as e:
                    typer.echo(f"⚠️  S3 configuration error: {str(e)}", err=True)
                    cli_logger.error(f"CLI - setup - S3 configuration error: {str(e)}")
                    if not typer.confirm("Continue with setup?"):
                        raise typer.Exit(code=1)
            
            typer.echo("\n✅ Setup completed successfully!")
            typer.echo(f"   Admin username: {admin_username}")
            typer.echo(f"   You can now login using: python cli.py login -u {admin_username}")
            cli_logger.info(f"CLI - setup-db - Setup completed successfully for user: {admin_username}")
            
        except typer.Exit:
            raise
        except Exception as e:
            typer.echo(f"❌ Setup failed: {str(e)}", err=True)
            import traceback
            typer.echo(traceback.format_exc(), err=True)
            raise typer.Exit(code=1)
        finally:
            await close_db_cli(db)

    asyncio.run(do_setup())

@cli.command(name="validate_env")
def validate_env():
    """Validate .env file and database connection."""
    typer.echo("Validating environment configuration...\n")
    
    # Required variables
    required_vars = {
        "POSTGRES_HOST": "PostgreSQL host",
        "POSTGRES_USER": "PostgreSQL user",
        "POSTGRES_PASSWORD": "PostgreSQL password",
        "POSTGRES_DATABASE": "PostgreSQL database name",
        "POSTGRES_PORT": "PostgreSQL port",
        "JWT_SECRET": "JWT secret key"
    }
    
    # Optional but recommended
    optional_vars = {
        "APPLICATION_PORT": "Application server port",
        "ENV": "Environment (development/production)",
        "SESSION_SECRET": "Session secret key"
    }
    
    missing = []
    for var, desc in required_vars.items():
        value = os.getenv(var)
        if not value:
            typer.echo(f"❌ {var} ({desc}): Missing")
            missing.append(var)
        else:
            # Mask password
            display_value = "***" if "PASSWORD" in var or "SECRET" in var else value
            typer.echo(f"✅ {var} ({desc}): {display_value}")
    
    for var, desc in optional_vars.items():
        value = os.getenv(var)
        if value:
            display_value = "***" if "SECRET" in var else value
            typer.echo(f"ℹ️  {var} ({desc}): {display_value}")
        else:
            typer.echo(f"⚠️  {var} ({desc}): Not set (using default)")
    
    if missing:
        typer.echo(f"\n❌ Missing required environment variables: {', '.join(missing)}", err=True)
        typer.echo("Please set them in your .env file.", err=True)
        raise typer.Exit(code=1)
    
    typer.echo("\n✅ Environment variables validated.")
    
    # Test database connection
    typer.echo("\nTesting database connection...")
    async def check_db():
        try:
            db = await get_db_cli()
            result = await db.fetchrow("SELECT version()")
            if result:
                typer.echo("✅ Database connection successful.")
                # Try to get database version
                version_str = result.get('version', '').split(',')[0] if result.get('version') else 'Unknown'
                typer.echo(f"   {version_str}")
            await close_db_cli(db)
        except Exception as e:
            typer.echo(f"❌ Database connection failed: {str(e)}", err=True)
            typer.echo("   Please check your database configuration.", err=True)
            raise typer.Exit(code=1)
            
    asyncio.run(check_db())

@cli.command()
def status():
    """Check the status of the ERP system."""
    typer.echo("Noolva ERP System Status\n")
    typer.echo(f"Version: {VERSION}")
    typer.echo(f"Environment: {os.getenv('ENV', 'development')}")
    
    async def get_stats():
        try:
            db = await get_db_cli()
            
            # Check if database is set up
            is_setup = await _is_db_setup(db)
            if not is_setup:
                typer.echo("\n⚠️  Database not fully initialized.")
                typer.echo("   Run: python cli.py setup")
                await close_db_cli(db)
                return
            
            # Get statistics
            user_count = await db.fetchrow("SELECT count(*) as count FROM public.users")
            tenant_count = await db.fetchrow("SELECT count(*) as count FROM public.tenants")
            company_count = await db.fetchrow("SELECT count(*) as count FROM public.companies")
            app_count = await db.fetchrow("SELECT count(*) as count FROM public.apps")
            
            typer.echo("\nDatabase Statistics:")
            typer.echo(f"  Users: {user_count.get('count', 0) if user_count else 0}")
            typer.echo(f"  Tenants: {tenant_count.get('count', 0) if tenant_count else 0}")
            typer.echo(f"  Companies: {company_count.get('count', 0) if company_count else 0}")
            typer.echo(f"  Apps: {app_count.get('count', 0) if app_count else 0}")
            
            # Check database setup
            is_setup = await _is_db_setup(db)
            if not is_setup:
                typer.echo("\n⚠️  Database not fully initialized.")
            
            await close_db_cli(db)
        except Exception as e:
            typer.echo(f"\n❌ Could not fetch stats: {str(e)}", err=True)
            typer.echo("   Database might not be initialized.", err=True)
            
    asyncio.run(get_stats())
@cli.command()
def version():
    """Show the current ERP version."""
    typer.echo(f"Noolva ERP version {VERSION}")
    typer.echo(f"Python version: {sys.version.split()[0]}")
    typer.echo(f"Environment: {os.getenv('ENV', 'development')}")

if __name__ == "__main__":
    cli()