"""
Logging Middleware
Logs all HTTP requests (method, path, status, user, timestamp) to a single log file
"""
import time
import logging
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response
from fastapi import status


logger = logging.getLogger("noolva_api")


class LoggingMiddleware(BaseHTTPMiddleware):
    """Middleware to log all HTTP requests"""
    
    async def dispatch(self, request: Request, call_next):
        # Record start time
        start_time = time.time()
        
        # Extract user info from token if available
        user_info = "anonymous"
        auth_header = request.headers.get("Authorization", "")
        if auth_header.startswith("Bearer "):
            try:
                token = auth_header.replace("Bearer ", "")
                # Decode token to get user info (without verification for logging)
                import jwt
                # Get secret from auth module (same as auth middleware)
                from middlewares.auth import SECRET_KEY
                payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"], options={"verify_signature": False})
                user_info = payload.get("username", f"user_id:{payload.get('user_id', 'unknown')}")
            except Exception:
                pass
        
        # Process request - let exceptions propagate to exception handlers
        response = await call_next(request)
        
        # Calculate duration
        duration = time.time() - start_time
        
        # Log the request
        log_message = (
            f"{request.method} {request.url.path} "
            f"- Status: {response.status_code} "
            f"- User: {user_info} "
            f"- Duration: {duration:.3f}s "
            f"- IP: {request.client.host if request.client else 'unknown'}"
        )
        
        # Log login/logout events at INFO level
        if request.url.path in ["/auth/login", "/auth/logout"] and response.status_code == status.HTTP_200_OK:
            logger.info(f"🔐 {log_message}")
        else:
            logger.info(log_message)
        
        return response
