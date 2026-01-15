from fastapi import FastAPI, Request
from routes import authentication, products
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

# Routes
app.include_router(authentication.router, prefix="/auth", tags=["Authentication"])
app.include_router(products.router, prefix="/app", tags=["Products"])

# Import and include integrations router
from routes import integrations
app.include_router(integrations.router, tags=["Integrations"])

@app.get("/")
def home():
    return {"message": f"{BRAND_NAME} is running!"}

if __name__ == "__main__":
    port = int(os.getenv("APPLICATION_PORT", "9001"))
    uvicorn.run(
        app, 
        host="0.0.0.0", 
        port=port,
        log_config=None,  # Use our custom logging setup above
        access_log=False  # Disable uvicorn access log, use our middleware instead
    )
