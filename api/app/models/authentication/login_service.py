from datetime import datetime, timedelta
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
    async def create_or_update_user(cls, data: dict):
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
            
            # Update other fields if provided (idle_timeout_minutes: None = use global, -1 = no lock, >0 = minutes)
            for field in ["email", "phone", "user_type", "active_status", "is_super_admin", "idle_timeout_minutes"]:
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
                INSERT INTO public.users (username, password, email, phone, first_name, last_name, user_type, active_status, is_super_admin, idle_timeout_minutes)
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
                RETURNING user_id
            """
            # Default values if not provided (idle_timeout_minutes NULL = use global)
            idle_min = data.get("idle_timeout_minutes")
            if idle_min is not None and idle_min != "":
                try:
                    idle_min = int(idle_min)
                except (TypeError, ValueError):
                    idle_min = None
            params = [
                username,
                hashed_password,
                data.get("email"),
                data.get("phone"),
                data.get("first_name"),
                data.get("last_name"),
                data.get("user_type", "tenant_user"),
                data.get("active_status", 1),
                data.get("is_super_admin", False),
                idle_min,
            ]
            
            res = await PostgresDB.fetchrow(query, *params)
            return {"message": "User created successfully", "user_id": res["user_id"]}

    @classmethod
    async def list_users(cls, exclude_system: bool = True) -> list:
        """
        List users. By default excludes user_type='system'.
        """
        if exclude_system:
            query = """
                SELECT user_id, user_uuid, username, email, phone, first_name, last_name,
                       user_type, is_super_admin, active_status, enable_2fa, idle_timeout_minutes, last_login, idate
                FROM public.users
                WHERE user_type != 'system' AND deleted_at IS NULL
                ORDER BY username
            """
        else:
            query = """
                SELECT user_id, user_uuid, username, email, phone, first_name, last_name,
                       user_type, is_super_admin, active_status, enable_2fa, idle_timeout_minutes, last_login, idate
                FROM public.users
                WHERE deleted_at IS NULL
                ORDER BY username
            """
        rows = await PostgresDB.fetch(query)
        return [dict(r) for r in rows] if rows else []

    @classmethod
    async def update_my_idle_timeout(cls, user_id: int, idle_timeout_minutes: Optional[int]) -> None:
        """Update current user's idle_timeout_minutes. None = use global, -1 = no lock, >0 = minutes."""
        await PostgresDB.execute(
            "UPDATE public.users SET idle_timeout_minutes = $1, last_updated = NOW() WHERE user_id = $2",
            idle_timeout_minutes, user_id
        )

    @classmethod
    async def reauth_user(cls, user_id: int, password: str, totp_code: Optional[str] = None, company_id: Optional[int] = None) -> Dict[str, Any]:
        """
        Re-authenticate after idle lock: verify password and TOTP (if 2FA enabled), return new token.
        """
        user = await PostgresDB.fetchrow(
            """
            SELECT user_id, user_uuid, username, password, user_type, is_super_admin, enable_2fa, mfa_secret
            FROM public.users WHERE user_id = $1
            """,
            user_id
        )
        if not user:
            raise ERPError("User not found", ErrorType.NOT_FOUND)
        if not cls.verify_password(password, user["password"]):
            raise ERPError("Invalid password", ErrorType.AUTHENTICATION_ERROR)
        if user.get("enable_2fa"):
            if not totp_code or not user.get("mfa_secret"):
                raise ERPError("Two-factor code required", ErrorType.AUTHENTICATION_ERROR)
            import pyotp
            totp = pyotp.TOTP(user["mfa_secret"])
            if not totp.verify(totp_code.strip(), valid_window=1):
                raise ERPError("Invalid or expired two-factor code", ErrorType.AUTHENTICATION_ERROR)
        token_payload = {
            "user_id": user["user_id"],
            "user_uuid": str(user["user_uuid"]) if user.get("user_uuid") is not None else None,
            "username": user["username"],
            "user_type": user["user_type"],
            "is_super_admin": user["is_super_admin"],
            "company_id": company_id,
        }
        token = auth.create_jwt_token(token_payload)
        return {
            "user": token_payload,
            "access_token": token,
        }

    @classmethod
    async def reset_password(cls, user_id: int, new_password: str) -> dict:
        """
        Reset password for a user by id. Does not allow resetting system user.
        """
        user = await PostgresDB.fetchrow(
            "SELECT user_id, user_type FROM public.users WHERE user_id = $1", user_id
        )
        if not user:
            raise ERPError("User not found", ErrorType.NOT_FOUND)
        if user["user_type"] == "system":
            raise ERPError("Cannot reset password for system user", ErrorType.AUTHORIZATION_ERROR)
        hashed = cls.get_password_hash(new_password)
        await PostgresDB.execute(
            "UPDATE public.users SET password = $1, last_updated = NOW() WHERE user_id = $2",
            hashed, user_id
        )
        return {"message": "Password reset successfully", "user_id": user_id}

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
        # 1. Fetch User - support username, email, or phone; include enable_2fa for 2FA flow
        query = """
            SELECT user_id, user_uuid, username, password, email, phone, user_type, active_status, is_super_admin, enable_2fa, mfa_secret
            FROM public.users
            WHERE username = $1 OR email = $1 OR phone = $1
        """
        user = await PostgresDB.fetchrow(query, identifier)
        
        if not user:
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
            raise ERPError(
                "Invalid password",
                ErrorType.AUTHENTICATION_ERROR,
                errorData={"field": "password"},
                message="Invalid password"
            )

        # 4. If 2FA enabled, return requires_totp and short-lived temp token (no session yet)
        if user.get("enable_2fa") and user.get("mfa_secret"):
            temp_payload = {
                "user_id": user["user_id"],
                "username": user["username"],
                "purpose": "login_totp",
                "company_id": company_id,
            }
            temp_token = auth.create_jwt_token(temp_payload, expires_delta=timedelta(minutes=5))
            return {
                "requires_totp": True,
                "temp_token": temp_token,
                "user": {
                    "user_id": user["user_id"],
                    "username": user["username"],
                    "user_type": user["user_type"],
                    "is_super_admin": user["is_super_admin"],
                    "company_id": company_id,
                },
            }

        # 5. No 2FA: generate token and create session
        token_payload = {
            "user_id": user["user_id"],
            "user_uuid": str(user["user_uuid"]) if user.get("user_uuid") is not None else None,
            "username": user["username"],
            "user_type": user["user_type"],
            "is_super_admin": user["is_super_admin"],
            "company_id": company_id
        }
        token = auth.create_jwt_token(token_payload)
        session = await SessionService.create_session(
            user_id=user["user_id"],
            company_id=company_id,
            login_method="password",
            device_info=device_info,
            ip_address=ip_address,
            user_agent=user_agent
        )
        await PostgresDB.execute("UPDATE public.users SET last_login = NOW() WHERE user_id = $1", user["user_id"])
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
    async def login_verify_totp(
        cls,
        user_id: int,
        totp_code: str,
        company_id: Optional[int] = None,
        device_info: Optional[Dict] = None,
        ip_address: Optional[str] = None,
        user_agent: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Complete login after password step when user has 2FA: verify TOTP and issue token + session.
        """
        user = await PostgresDB.fetchrow(
            """
            SELECT user_id, user_uuid, username, user_type, is_super_admin, enable_2fa, mfa_secret
            FROM public.users WHERE user_id = $1
            """,
            user_id,
        )
        if not user or not user.get("enable_2fa") or not user.get("mfa_secret"):
            raise ERPError("Two-factor verification not required or not set up", ErrorType.AUTHENTICATION_ERROR)
        import pyotp
        totp = pyotp.TOTP(user["mfa_secret"])
        if not totp.verify(totp_code.strip(), valid_window=1):
            raise ERPError("Invalid or expired two-factor code", ErrorType.AUTHENTICATION_ERROR)
        token_payload = {
            "user_id": user["user_id"],
            "user_uuid": str(user["user_uuid"]) if user.get("user_uuid") is not None else None,
            "username": user["username"],
            "user_type": user["user_type"],
            "is_super_admin": user["is_super_admin"],
            "company_id": company_id,
        }
        token = auth.create_jwt_token(token_payload)
        session = await SessionService.create_session(
            user_id=user["user_id"],
            company_id=company_id,
            login_method="mfa",
            device_info=device_info,
            ip_address=ip_address,
            user_agent=user_agent,
        )
        await PostgresDB.execute("UPDATE public.users SET last_login = NOW() WHERE user_id = $1", user["user_id"])
        if company_id:
            await SessionService.create_or_update_account_profile(
                user_id=user["user_id"],
                company_id=company_id
            )
        return {
            "user": token_payload,
            "access_token": token,
            "session_id": session.get("session_id"),
            "session_uuid": session.get("session_uuid"),
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
            SELECT user_id, user_uuid, username, user_type, active_status, is_super_admin 
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
            "user_uuid": str(user["user_uuid"]) if user.get("user_uuid") is not None else None,
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
        # Get user info (include idle_timeout_minutes for session lock)
        user = await PostgresDB.fetchrow(
            """
            SELECT user_id, username, email, phone, first_name, last_name,
                   avatar_url, user_type, is_super_admin, active_status, enable_2fa, idle_timeout_minutes
            FROM public.users
            WHERE user_id = $1
            """,
            user_id
        )
        
        if not user:
            raise ERPError("User not found", ErrorType.NOT_FOUND)
        
        # Effective idle timeout: user override (NULL = use global), -1 = no lock
        global_row = await PostgresDB.fetchrow(
            """
            SELECT value FROM public.settings
            WHERE setting_key = 'idle_timeout_minutes' AND scope = 'global' AND tenant_id IS NULL
            """
        )
        global_minutes = None
        if global_row and global_row.get("value") is not None:
            raw = global_row["value"]
            if isinstance(raw, (int, float)):
                global_minutes = int(raw)
            elif isinstance(raw, str):
                try:
                    global_minutes = int(float(raw.strip()))
                except (ValueError, TypeError):
                    pass
        if global_minutes is None:
            global_minutes = 15  # default 15 minutes
        user_idle = user.get("idle_timeout_minutes")
        effective_idle_minutes = int(user_idle) if user_idle is not None else global_minutes
        user_dict = dict(user)
        user_dict["effective_idle_timeout_minutes"] = effective_idle_minutes
        
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
            "user": user_dict,
            "company": dict(company) if company else None,
            "profiles": profiles,
            "sessions": sessions
        }
