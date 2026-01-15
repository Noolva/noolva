from datetime import datetime, timedelta
from fastapi import HTTPException, Header,status
import jwt
from typing import Optional, Dict,List
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
