from datetime import datetime, timedelta
from fastapi import HTTPException, Header, status
import jwt
import hashlib
from typing import Optional, Dict, List, Any
from classes.postgres_db import PostgresDB

SECRET_KEY = "your_strong_secret_key"  # Change this for production
ALGORITHM = "HS256"
#ACCESS_TOKEN_EXPIRE_MINUTES = 2 * 60  # 120 minutes   2hours
ACCESS_TOKEN_EXPIRE_MINUTES = 24 * 60  # 1440 minutes   one day


# Function to create JWT token
def create_jwt_token(data: Dict, expires_delta: Optional[timedelta] = None) -> str:
    payload = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    payload.update({"exp": expire})
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


def decode_jwt_payload(token: str) -> Dict:
    """Decode JWT and return payload; raises on invalid/expired."""
    return jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])

# Function to verify JWT token from Authorization header
def verify_jwt_token(allowed_user_types: Optional[List[str]] = None):
    """Dependency function to verify JWT and check allowed user types.
    
    - If `allowed_user_types` is empty, public access is allowed.
    - If `allowed_user_types` is specified, the user must have a valid token and be in the list.
    """
    def validator(authorization: Optional[str] = Header(None)) -> Optional[Dict]:
        # Public access: No token required
        if not allowed_user_types:
            return None  # Public access, no user validation required

        # If authorization header is missing, deny access
        if not authorization or not authorization.startswith("Bearer "):
            raise HTTPException(status_code=401, detail="Invalid or missing token")
        
        token = authorization.split(" ")[1]
        
        try:
            payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
            user_type = payload.get("user_type")

            if user_type not in allowed_user_types:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Access denied: You do not have permission to access this resource."
                )

            return payload  # Return validated user data

        except jwt.ExpiredSignatureError:
            raise HTTPException(status_code=401, detail="Token expired")
        except jwt.InvalidTokenError:
            raise HTTPException(status_code=401, detail="Invalid token")

    return validator  # Return the validator function


async def resolve_bearer_to_user(authorization: Optional[str]) -> Optional[Dict[str, Any]]:
    """
    Resolve Bearer token to user payload. Tries JWT first, then Personal Access Token.
    Returns same payload shape as JWT (user_id, username, user_type, is_super_admin, company_id) or None.
    """
    if not authorization or not authorization.startswith("Bearer "):
        return None
    token = authorization.split(" ", 1)[1].strip()
    if not token:
        return None
    # 1) Try JWT
    try:
        return jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    except Exception:
        pass
    # 2) Try PAT
    try:
        token_hash = hashlib.sha256(token.encode("utf-8")).hexdigest()
        row = await PostgresDB.fetchrow(
            """
            SELECT pat.pat_id, pat.user_id, pat.company_id, pat.expires_at
            FROM public.personal_access_tokens pat
            WHERE pat.token_hash = $1 AND pat.expires_at > CURRENT_TIMESTAMP
            """,
            token_hash,
        )
        if not row:
            return None
        await PostgresDB.execute(
            "UPDATE public.personal_access_tokens SET last_used_at = CURRENT_TIMESTAMP WHERE pat_id = $1",
            row["pat_id"],
        )
        user_row = await PostgresDB.fetchrow(
            "SELECT user_id, username, user_type, is_super_admin FROM public.users WHERE user_id = $1",
            row["user_id"],
        )
        if not user_row:
            return None
        return {
            "user_id": user_row["user_id"],
            "username": user_row["username"],
            "user_type": user_row["user_type"],
            "is_super_admin": user_row["is_super_admin"],
            "company_id": row.get("company_id"),
        }
    except Exception:
        return None
