from fastapi import FastAPI, Request
from routes import authentication
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
from contextlib import asynccontextmanager
from starlette.middleware.sessions import SessionMiddleware
from classes.postgres_db import PostgresDB
from errors.base_error import ERPError
from fastapi.responses import JSONResponse
import os
import logging
from logging.handlers import RotatingFileHandler
from utils.google_oauth import setup_google_oauth
from middlewares.logging_middleware import LoggingMiddleware
from fastapi.staticfiles import StaticFiles
from pathlib import Path

BRAND_NAME = 'Noolva API'

# Setup single log file for all logs
LOG_DIR = os.getenv("LOG_DIR", "logs")
os.makedirs(LOG_DIR, exist_ok=True)
LOG_FILE = os.path.join(LOG_DIR, "noolva.log")

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        RotatingFileHandler(LOG_FILE, maxBytes=10*1024*1024, backupCount=5),
        logging.StreamHandler()
    ]
)

# Get logger for this module
logger = logging.getLogger("noolva_api")
logger.setLevel(logging.INFO)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("Application startup initiated")
    await PostgresDB.connect()
    logger.info("Database connected")
    
    # Log registered routes for debugging
    routes = []
    for route in app.routes:
        try:
            route_path = getattr(route, "path", None) or str(route)
            route_methods = getattr(route, "methods", None)
            if route_methods:
                try:
                    methods_list = list(route_methods) if route_methods else []
                except (TypeError, AttributeError):
                    methods_list = []
            else:
                methods_list = []
            
            route_info = {
                "path": route_path,
                "methods": methods_list,
                "name": getattr(route, "name", None)
            }
            routes.append(route_info)
        except Exception as e:
            # Skip routes that can't be inspected (like Mount objects)
            logger.debug(f"Could not inspect route: {type(route).__name__}, error: {e}")
    
    logger.info(f"Registered {len(routes)} routes")
    app_menus_routes = [r for r in routes if "app-menus" in r.get("path", "")]
    if app_menus_routes:
        logger.info(f"App Menus routes registered: {[r.get('path', '') for r in app_menus_routes]}")
    else:
        logger.warning("No app-menus routes found in registered routes!")
    
    yield
    # Shutdown
    logger.info("Application shutdown initiated")
    await PostgresDB.close()
    logger.info("Database connection closed")

app = FastAPI(title="Noolva SaaS API", lifespan=lifespan)

# Register ERPError handler first (more specific handler)
@app.exception_handler(ERPError)
async def erp_error_handler(request: Request, exc: ERPError):
    """
    Handles ERPError exceptions specifically.
    Returns a structured JSON response with error details.
    """
    error_dict = exc.to_dict()
    logger.info(f"ERPError caught: {error_dict.get('type')} - {error_dict.get('description')}")
    
    # Return JSONResponse with proper status code
    response = JSONResponse(
        status_code=400,
        content=error_dict
    )
    return response

# Global Error Handler for all other exceptions
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """
    Catches all other unhandled exceptions.
    Returns a sanitized JSON response.
    """
    # Generic Unhandled Exceptions (Security: Hide details in Prod)
    logger.exception(f"CRITICAL ERROR: {exc}")
    return JSONResponse(
        status_code=500,
        content={
            "type": "SERVER_ERROR",
            "code": 1005,
            "description": "Internal Server Error",
            "solution": "Check server logs for details.",
            "details": {
                "originalError": str(exc),
                "traceback": [],
                "additionalData": {}
            }
        }
    )

# Register exception handlers BEFORE middleware
# This ensures exceptions are caught before middleware processes them

app.state.oauth = setup_google_oauth()
app.add_middleware(SessionMiddleware, secret_key=os.getenv("SESSION_SECRET", "supersecret"))

# CORS - Allow all origins for development (restrict in production)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for development
    allow_credentials=False,  # Must be False when allow_origins=["*"]
    allow_methods=["*"],
    allow_headers=["*"],
)

# Add logging middleware (should be added last to log final response)
app.add_middleware(LoggingMiddleware)

# Static assets (api/assets/*) served at /assets/*
ASSETS_DIR = Path(__file__).resolve().parent.parent / "assets"
if ASSETS_DIR.exists():
    app.mount("/assets", StaticFiles(directory=str(ASSETS_DIR)), name="assets")

# Routes
app.include_router(authentication.router, prefix="/auth", tags=["Authentication"])

# Import and include settings router
from routes import settings
app.include_router(settings.router, tags=["Settings"])

# Import and include themes router
from routes import themes
app.include_router(themes.router, tags=["Themes"])

# Import and include database router
from routes import database
app.include_router(database.router, tags=["Developer Console - Database"])

# Import and include menus router (CRUD operations)
try:
    from routes import menus
    app.include_router(menus.router, prefix="/app-menus", tags=["App Menus"])
    logger.info("Menus router registered successfully at /app-menus")
except Exception as e:
    logger.error(f"Failed to register menus router: {e}")
    raise

# Import and include data models router
try:
    from routes import data_models
    app.include_router(data_models.router, prefix="/data-models", tags=["Data Models"])
    logger.info("Data models router registered successfully at /data-models")
except Exception as e:
    logger.error(f"Failed to register data models router: {e}")
    raise

# Import and include field options router
try:
    from routes import field_options
    app.include_router(field_options.router, tags=["Field Options"])
    logger.info("Field options router registered successfully at /field-options")
except Exception as e:
    logger.error(f"Failed to register field options router: {e}")
    raise

# Import and include icons router
try:
    from routes import icons
    app.include_router(icons.router, prefix="/icons", tags=["Icons"])
    logger.info("Icons router registered successfully at /icons")
except Exception as e:
    logger.error(f"Failed to register icons router: {e}")
    raise

# Import and include collections router
try:
    from routes import collections
    app.include_router(collections.router, prefix="/collections", tags=["Collections"])
    logger.info("Collections router registered successfully at /collections")
except Exception as e:
    logger.error(f"Failed to register collections router: {e}")
    raise

# Import and include api_endpoints router
try:
    from routes import api_endpoints
    app.include_router(api_endpoints.router, prefix="/api-endpoints", tags=["API Endpoints"])
    logger.info("API endpoints router registered successfully at /api-endpoints")
except Exception as e:
    logger.error(f"Failed to register api_endpoints router: {e}")
    raise

# Import and include personal_access_tokens router
try:
    from routes import personal_access_tokens
    app.include_router(personal_access_tokens.router, prefix="/personal-access-tokens", tags=["Personal Access Tokens"])
    logger.info("Personal Access Tokens router registered successfully at /personal-access-tokens")
except Exception as e:
    logger.error(f"Failed to register personal_access_tokens router: {e}")
    raise


@app.get("/")
def home():
    return {"message": f"{BRAND_NAME} is running!"}

# Catch-all route for unmatched API paths - return proper JSON 404
# This prevents FastAPI from returning HTML 404 for frontend routes
# IMPORTANT: This must be registered LAST, after all other routes
# Note: This will only match if no other route matches (FastAPI matches more specific routes first)
@app.api_route("/{path:path}", methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"])
async def catch_all(request: Request, path: str):
    """
    Catch-all handler for unmatched routes.
    Returns JSON 404 for API-like requests, otherwise lets frontend handle routing.
    This should only be reached if no specific route matched.
    """
    # For paths that look like API routes but weren't matched by any router
    if path.startswith(("assets/", "auth/", "app/", "api/", "settings", "dev-console/")):
        return JSONResponse(
            status_code=404,
            content={
                "type": "NOT_FOUND",
                "code": 1004,
                "description": f"API endpoint not found: /{path}",
                "solution": "Check the API documentation for available endpoints.",
            }
        )
    
    # For organization routes - check if it's exactly the base path or a sub-path
    # If it's exactly "app-menus", "companies", etc., the router should have handled it
    # If we're here, it means a specific endpoint wasn't found
    # Note: "data-models" is handled by its router, so don't catch it here
    base_paths = ["app-menus", "companies", "user-groups", "teams", "roles", "permissions"]
    for base_path in base_paths:
        if path == base_path or path.startswith(f"{base_path}/"):
            return JSONResponse(
                status_code=404,
                content={
                    "type": "NOT_FOUND",
                    "code": 1004,
                    "description": f"API endpoint not found: /{path}",
                    "solution": "Check the API documentation for available endpoints.",
                }
            )
    
    # For frontend routes (not starting with API prefixes), return 404 JSON
    # The frontend should handle routing via React Router
    return JSONResponse(
        status_code=404,
        content={
            "type": "NOT_FOUND",
            "code": 1004,
            "description": f"Route not found: /{path}. This appears to be a frontend route.",
            "solution": "Frontend routes should be handled by React Router. If this is an API call, use the correct API endpoint path.",
        }
    )

if __name__ == "__main__":
    port = int(os.getenv("APPLICATION_PORT", "9001"))
    uvicorn.run(
        app, 
        host="0.0.0.0", 
        port=port,
        log_config=None,  # Use our custom logging setup above
        access_log=False  # Disable uvicorn access log, use our middleware instead
    )
