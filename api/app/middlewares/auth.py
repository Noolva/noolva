import logging
from datetime import datetime, timedelta
from fastapi import HTTPException, Header, status
import jwt
import hashlib
from typing import Optional, Dict, List, Any
from classes.postgres_db import PostgresDB

logger = logging.getLogger("noolva_api")

# PAT tokens start with this prefix; when present we only try PAT lookup (not JWT)
PAT_PREFIX = "nvpat_"


def _mask_token_for_log(token: str, max_visible: int = 10) -> str:
    """Return a safe string for logging (e.g. nvpat_abc123... or jwt_eyJ...)."""
    if not token or len(token) <= max_visible:
        return "(empty or short)"
    return f"{token[:max_visible]}...({len(token)} chars)"

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
    When token starts with PAT_PREFIX (nvpat_), only PAT lookup is tried.
    Returns same payload shape as JWT (user_id, username, user_type, is_super_admin, company_id) or None.
    """
    if not authorization or not str(authorization).strip():
        logger.info("Auth: no Authorization header or empty value")
        return None
    if not authorization.strip().startswith("Bearer "):
        logger.info("Auth: Authorization header present but does not start with 'Bearer ' (value prefix: %s)",
                    _mask_token_for_log(authorization.strip()[:50], 20))
        return None
    token = authorization.split(" ", 1)[1].strip()
    if not token:
        logger.info("Auth: Bearer scheme present but token is empty")
        return None

    token_desc = _mask_token_for_log(token)
    # When token is a PAT (starts with nvpat_), only try PAT lookup
    if token.startswith(PAT_PREFIX):
        user = await _resolve_pat(token)
        if user is None:
            logger.info("Auth: PAT token %s -> lookup failed (no match, expired, or error)", token_desc)
        return user

    # 1) Try JWT
    try:
        return jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    except Exception as e:
        logger.info("Auth: JWT decode failed for %s: %s", token_desc, type(e).__name__)
    # 2) Try PAT for non-prefixed tokens (e.g. legacy or custom)
    user = await _resolve_pat(token)
    if user is None:
        logger.info("Auth: token %s -> not valid JWT and PAT lookup failed", token_desc)
    return user


async def _resolve_pat(token: str) -> Optional[Dict[str, Any]]:
    """Look up PAT by token hash and return user payload; None if invalid/expired."""
    try:
        token_hash = hashlib.sha256(token.encode("utf-8")).hexdigest()
        row = await PostgresDB.fetchrow(
            """
            SELECT pat.pat_id, pat.user_id, pat.company_id, pat.expires_at, pat.scopes_json
            FROM public.personal_access_tokens pat
            WHERE pat.token_hash = $1 AND pat.expires_at > CURRENT_TIMESTAMP
            """,
            token_hash,
        )
        if not row:
            logger.info("PAT lookup: no row for token hash (token may be wrong or expired); token prefix: %s",
                        _mask_token_for_log(token))
            return None
        await PostgresDB.execute(
            "UPDATE public.personal_access_tokens SET last_used_at = CURRENT_TIMESTAMP WHERE pat_id = $1",
            row["pat_id"],
        )
        user_row = await PostgresDB.fetchrow(
            "SELECT user_id, user_uuid, username, user_type, is_super_admin FROM public.users WHERE user_id = $1",
            row["user_id"],
        )
        if not user_row:
            logger.warning("PAT lookup: user_id %s not found in users", row["user_id"])
            return None
        out = {
            "user_id": user_row["user_id"],
            "user_uuid": str(user_row["user_uuid"]) if user_row.get("user_uuid") is not None else None,
            "username": user_row["username"],
            "user_type": user_row["user_type"],
            "is_super_admin": user_row["is_super_admin"],
            "company_id": row.get("company_id"),
        }
        # Include PAT scopes when present (for optional scope checks on specific endpoints)
        scopes = row.get("scopes_json")
        if scopes is not None:
            out["pat_scopes"] = scopes if isinstance(scopes, list) else []
        return out
    except Exception as e:
        logger.warning("PAT lookup failed: %s", e, exc_info=True)
        return None
