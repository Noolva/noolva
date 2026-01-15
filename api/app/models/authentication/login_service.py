from datetime import datetime
from typing import Dict, Optional, Any
from classes.postgres_db import PostgresDB
from errors import ERPError, ErrorType
from middlewares import auth  # Assuming auth.py has create_jwt_token
from passlib.context import CryptContext
from models.authentication.session_service import SessionService

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

class LoginService:
    @staticmethod
    def verify_password(plain_password, hashed_password):
        return pwd_context.verify(plain_password, hashed_password)

    @staticmethod
    def get_password_hash(password):
        return pwd_context.hash(password)

    @classmethod
    async def create_or_update_user(cls, request: Any, data: dict):
        """
        Creates a new user or updates an existing one safely.
        """
        username = data.get("username")
        password = data.get("password")
        
        # 1. Check Existence
        existing_user = await PostgresDB.fetchrow("SELECT user_id FROM public.users WHERE username = $1", username)
        
        hashed_password = cls.get_password_hash(password) if password else None

        if existing_user:
            # UPDATE Logic
            user_id = existing_user["user_id"]
            
            # Build dynamic update query
            updates = []
            params = []
            idx = 1
            
            if hashed_password:
                updates.append(f"password = ${idx}")
                params.append(hashed_password)
                idx += 1
            
            # Update other fields if provided
            for field in ["email", "phone", "user_type", "active_status", "is_super_admin"]:
                if field in data and data[field] is not None:
                    updates.append(f"{field} = ${idx}")
                    params.append(data[field])
                    idx += 1
            
            if updates:
                params.append(user_id)
                query = f"UPDATE public.users SET {', '.join(updates)} WHERE user_id = ${idx}"
                await PostgresDB.execute(query, *params)
                return {"message": "User updated successfully", "user_id": user_id}
            else:
                return {"message": "No changes detected", "user_id": user_id}

        else:
            # CREATE Logic
            if not password:
                raise ERPError("Password is required for new users", ErrorType.VALIDATION_ERROR)
            
            query = """
                INSERT INTO public.users (username, password, email, phone, user_type, active_status, is_super_admin)
                VALUES ($1, $2, $3, $4, $5, $6, $7)
                RETURNING user_id
            """
            # Default values if not provided
            params = [
                username,
                hashed_password,
                data.get("email"),
                data.get("phone"),
                data.get("user_type", "user"),
                data.get("active_status", 1),
                data.get("is_super_admin", False)
            ]
            
            res = await PostgresDB.fetchrow(query, *params)
            return {"message": "User created successfully", "user_id": res["user_id"]}

    @classmethod
    async def login_user(
        cls, 
        identifier: str, 
        password: str,
        company_id: Optional[int] = None,
        device_info: Optional[Dict] = None,
        ip_address: Optional[str] = None,
        user_agent: Optional[str] = None
    ):
        """
        Authenticates a user via username/email/phone.
        """
        # 1. Fetch User - support username, email, or phone
        # Using parameterized query for security
        query = """
            SELECT user_id, username, password, email, phone, user_type, active_status, is_super_admin 
            FROM public.users 
            WHERE username = $1 
               OR email = $1
               OR phone = $1
        """
        user = await PostgresDB.fetchrow(query, identifier)
        
        if not user:
            # Specific error message for invalid identifier
            raise ERPError(
                "Invalid username, email, or phone number",
                ErrorType.AUTHENTICATION_ERROR,
                errorData={"field": "identifier"},
                message="Invalid username, email, or phone number"
            )

        # 2. Status Check
        if user["active_status"] != 1:
            raise ERPError(
                "Account is inactive or suspended",
                ErrorType.AUTHENTICATION_ERROR,
                errorData={"field": "status"},
                message="Account is inactive or suspended"
            )

        # 3. Password Check
        if not cls.verify_password(password, user["password"]):
            # Specific error message for invalid password
            raise ERPError(
                "Invalid password",
                ErrorType.AUTHENTICATION_ERROR,
                errorData={"field": "password"},
                message="Invalid password"
            )

        # 4. Generate Token
        # Helper to strip sensitive data
        token_payload = {
            "user_id": user["user_id"],
            "username": user["username"],
            "user_type": user["user_type"],
            "is_super_admin": user["is_super_admin"],
            "company_id": company_id
        }
        token = auth.create_jwt_token(token_payload)

        # 5. Create Session
        session = await SessionService.create_session(
            user_id=user["user_id"],
            company_id=company_id,
            login_method="password",
            device_info=device_info,
            ip_address=ip_address,
            user_agent=user_agent
        )

        # 6. Update Last Login
        await PostgresDB.execute("UPDATE public.users SET last_login = NOW() WHERE user_id = $1", user["user_id"])

        # 7. Create/Update Account Profile
        if company_id:
            await SessionService.create_or_update_account_profile(
                user_id=user["user_id"],
                company_id=company_id
            )

        return {
            "user": token_payload,
            "access_token": token,
            "session_id": session.get("session_id"),
            "session_uuid": session.get("session_uuid")
        }

    @classmethod
    async def google_login(
        cls,
        email: str,
        company_id: Optional[int] = None,
        device_info: Optional[Dict] = None,
        ip_address: Optional[str] = None,
        user_agent: Optional[str] = None
    ):
        """
        Authenticates via Google Email. No auto-signup.
        """
        query = """
            SELECT user_id, username, user_type, active_status, is_super_admin 
            FROM public.users 
            WHERE username = $1 OR email = $1
        """
        user = await PostgresDB.fetchrow(query, email)

        if not user:
            raise ERPError("User not registered in system", ErrorType.AUTHORIZATION_ERROR)

        if user["active_status"] != 1:
            raise ERPError("Account is inactive", ErrorType.AUTHENTICATION_ERROR)

        token_payload = {
            "user_id": user["user_id"],
            "username": user["username"],
            "user_type": user["user_type"],
            "is_super_admin": user["is_super_admin"],
            "company_id": company_id
        }
        token = auth.create_jwt_token(token_payload)
        
        # Create Session
        session = await SessionService.create_session(
            user_id=user["user_id"],
            company_id=company_id,
            login_method="google_oauth",
            device_info=device_info,
            ip_address=ip_address,
            user_agent=user_agent
        )
        
        await PostgresDB.execute("UPDATE public.users SET last_login = NOW() WHERE user_id = $1", user["user_id"])

        # Create/Update Account Profile
        if company_id:
            await SessionService.create_or_update_account_profile(
                user_id=user["user_id"],
                company_id=company_id
            )

        return {
            "user": token_payload,
            "access_token": token,
            "session_id": session.get("session_id"),
            "session_uuid": session.get("session_uuid")
        }
    
    @classmethod
    async def get_user_context(cls, user_id: int, company_id: Optional[int] = None) -> Dict[str, Any]:
        """
        Get user context including account profiles and sessions
        
        Args:
            user_id: User ID
            company_id: Optional company ID
            
        Returns:
            User context dictionary
        """
        # Get user info
        user = await PostgresDB.fetchrow(
            """
            SELECT user_id, username, email, phone, first_name, last_name, 
                   avatar_url, user_type, is_super_admin, active_status
            FROM public.users 
            WHERE user_id = $1
            """,
            user_id
        )
        
        if not user:
            raise ERPError("User not found", ErrorType.NOT_FOUND)
        
        # Get account profiles
        profiles = await SessionService.get_user_account_profiles(user_id)
        
        # Get active sessions
        sessions = await SessionService.get_user_sessions(user_id, active_only=True)
        
        # Get company info if company_id provided
        company = None
        if company_id:
            company = await PostgresDB.fetchrow(
                """
                SELECT company_id, company_uuid, company_name, company_code, logo_url
                FROM public.companies
                WHERE company_id = $1
                """,
                company_id
            )
        
        return {
            "user": dict(user),
            "company": dict(company) if company else None,
            "profiles": profiles,
            "sessions": sessions
        }
