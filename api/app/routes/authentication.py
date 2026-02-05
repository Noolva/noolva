from fastapi import APIRouter, Depends, Request, HTTPException, Header
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import Optional, List, Dict
from models.authentication.login_service import LoginService
from models.authentication.session_service import SessionService
from middlewares.auth import verify_jwt_token, decode_jwt_payload
from utils.db import get_db
from errors.base_error import ERPError
from errors import ErrorType

router = APIRouter()

class LoginRequest(BaseModel):
    identifier: str  # username, email, or phone
    password: str
    company_id: Optional[int] = None


class LoginVerifyTotpRequest(BaseModel):
    temp_token: str
    totp_code: str

class CreateUserRequest(BaseModel):
    username: str
    password: str = None  # Optional for updates
    email: str = None
    phone: str = None
    first_name: str = None
    last_name: str = None
    user_type: str = "tenant_user"
    active_status: int = 1
    is_super_admin: bool = False
    idle_timeout_minutes: Optional[int] = None  # None = use global, -1 = no lock, >0 = minutes


class ResetPasswordRequest(BaseModel):
    new_password: str


class Verify2FARequest(BaseModel):
    code: str  # 6-digit TOTP code


class ReauthRequest(BaseModel):
    password: str
    totp_code: Optional[str] = None  # Required if user has enable_2fa


class MyIdleTimeoutRequest(BaseModel):
    idle_timeout_minutes: Optional[int] = None  # null = use global default, -1 = no lock, >0 = minutes

class SwitchAccountRequest(BaseModel):
    company_id: Optional[int] = None
    profile_name: Optional[str] = None

def get_client_info(request: Request) -> Dict:
    """Extract client information from request"""
    return {
        "ip_address": request.client.host if request.client else None,
        "user_agent": request.headers.get("user-agent"),
        "device_info": {
            "platform": request.headers.get("sec-ch-ua-platform", ""),
            "user_agent": request.headers.get("user-agent", "")
        }
    }

@router.get("/users")
async def list_users(
    request: Request,
    db=Depends(get_db),
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
):
    """
    List users (excluding system user by default). Requires admin/tenant_admin.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    users = await LoginService.list_users(exclude_system=True)
    return {"users": users}


@router.post("/create-user")
async def create_user(
    request: Request,
    data: CreateUserRequest,
    db=Depends(get_db),
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
):
    """
    Creates or updates a user. Encrypts password. Requires admin/tenant_admin.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    return await LoginService.create_or_update_user(data.dict())


@router.post("/users/{user_id}/reset-password")
async def reset_user_password(
    user_id: int,
    request: Request,
    data: ResetPasswordRequest,
    db=Depends(get_db),
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin"])),
):
    """
    Reset password for a user. Cannot reset system user. Requires admin/tenant_admin.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    try:
        return await LoginService.reset_password(user_id, data.new_password)
    except ERPError as e:
        return JSONResponse(status_code=400 if e.errorType == ErrorType.NOT_FOUND else 403, content=e.to_dict())

@router.post("/login")
async def login(request: Request, data: LoginRequest, db=Depends(get_db)):
    """
    Standard Login via Username/Email/Phone & Password.
    If user has 2FA enabled, returns requires_totp and temp_token; frontend must then call POST /auth/login/verify-totp.
    """
    try:
        client_info = get_client_info(request)
        return await LoginService.login_user(
            identifier=data.identifier,
            password=data.password,
            company_id=data.company_id,
            device_info=client_info["device_info"],
            ip_address=client_info["ip_address"],
            user_agent=client_info["user_agent"]
        )
    except ERPError as e:
        # Convert ERPError to JSONResponse directly
        # This ensures the error is properly returned without re-raising
        error_dict = e.to_dict()
        return JSONResponse(
            status_code=400,
            content=error_dict
        )


@router.post("/login/verify-totp")
async def login_verify_totp(request: Request, data: LoginVerifyTotpRequest, db=Depends(get_db)):
    """
    Complete login after password when user has 2FA. Requires temp_token from POST /auth/login response.
    """
    try:
        payload = decode_jwt_payload(data.temp_token)
        if payload.get("purpose") != "login_totp":
            raise HTTPException(status_code=400, detail="Invalid token")
        user_id = payload.get("user_id")
        company_id = payload.get("company_id")
        if not user_id:
            raise HTTPException(status_code=400, detail="Invalid token")
        client_info = get_client_info(request)
        return await LoginService.login_verify_totp(
            user_id=user_id,
            totp_code=data.totp_code,
            company_id=company_id,
            device_info=client_info["device_info"],
            ip_address=client_info["ip_address"],
            user_agent=client_info["user_agent"],
        )
    except ERPError as e:
        return JSONResponse(status_code=400, content=e.to_dict())
    except Exception as e:
        if "Signature" in str(e) or "expired" in str(e).lower():
            raise HTTPException(status_code=400, detail="Verification link expired. Please log in again.")
        raise


@router.get("/google")
async def google_login(request: Request):
    """
    Initiates Google OAuth Flow.
    """
    redirect_uri = request.url_for("google_auth_callback")
    return await request.app.state.oauth.google.authorize_redirect(request, redirect_uri)

@router.get("/google-callback", name="google_auth_callback")
async def google_auth_callback(request: Request, db=Depends(get_db)):
    """
    Handles Google OAuth Callback.
    """
    try:
        token = await request.app.state.oauth.google.authorize_access_token(request)
        user_info = token.get('userinfo')
        if not user_info:
            # Fallback if id_token flow
            user_info = await request.app.state.oauth.google.parse_id_token(request, token)
        
        email = user_info.get('email')
        if not email:
            raise HTTPException(status_code=400, detail="Email not provided by Google")
        
        client_info = get_client_info(request)
        company_id = request.query_params.get('company_id', type=int) if request.query_params.get('company_id') else None
        
        return await LoginService.google_login(
            email=email,
            company_id=company_id,
            device_info=client_info["device_info"],
            ip_address=client_info["ip_address"],
            user_agent=client_info["user_agent"]
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Google OAuth failed: {str(e)}")

@router.get("/me")
async def get_current_user(request: Request, db=Depends(get_db), user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"]))):
    """
    Returns the current user's profile, account profiles, and sessions.
    Requires Bearer Token.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    
    user_id = user.get("user_id")
    company_id = user.get("company_id")
    
    return await LoginService.get_user_context(user_id=user_id, company_id=company_id)

@router.get("/menus")
async def get_user_menus(request: Request, db=Depends(get_db), user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"]))):
    """
    Get menus for the current user based on permissions.
    Requires Bearer Token.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    
    from models.menus.menu_service import MenuService
    
    user_id = user.get("user_id")
    user_type = user.get("user_type")
    company_id = user.get("company_id")
    is_super_admin = user.get("is_super_admin", False)
    
    menus = await MenuService.get_user_menus(
        user_id=user_id,
        user_type=user_type,
        company_id=company_id,
        is_super_admin=is_super_admin
    )
    
    return menus

@router.get("/apps")
async def get_user_apps(request: Request, db=Depends(get_db), user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"]))):
    """
    Get all apps that the current user has access to.
    Requires Bearer Token.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    
    from models.menus.menu_service import MenuService
    
    user_id = user.get("user_id")
    user_type = user.get("user_type")
    company_id = user.get("company_id")
    is_super_admin = user.get("is_super_admin", False)
    
    apps = await MenuService.get_user_apps(
        user_id=user_id,
        user_type=user_type,
        company_id=company_id,
        is_super_admin=is_super_admin
    )
    
    return {"apps": apps}

@router.get("/apps/{app_id}/menus")
async def get_app_menus(
    app_id: int,
    request: Request,
    db=Depends(get_db),
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"]))
):
    """
    Get menus for a specific app that the current user has access to.
    Requires Bearer Token.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    
    from models.menus.menu_service import MenuService
    
    user_id = user.get("user_id")
    user_type = user.get("user_type")
    company_id = user.get("company_id")
    is_super_admin = user.get("is_super_admin", False)
    
    menus = await MenuService.get_app_menus(
        app_id=app_id,
        user_id=user_id,
        user_type=user_type,
        company_id=company_id,
        is_super_admin=is_super_admin
    )
    
    return {"menus": menus}

@router.get("/accounts")
async def get_accounts(request: Request, db=Depends(get_db), user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"]))):
    """
    Get all account profiles for the current user.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    
    user_id = user.get("user_id")
    profiles = await SessionService.get_user_account_profiles(user_id)
    return {"profiles": profiles}

@router.post("/switch-account")
async def switch_account(request: Request, data: SwitchAccountRequest, db=Depends(get_db), user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"]))):
    """
    Switch active account context.
    Creates a new token with the new company_id.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    
    user_id = user.get("user_id")
    
    # Update or create profile
    profile = await SessionService.create_or_update_account_profile(
        user_id=user_id,
        company_id=data.company_id,
        profile_name=data.profile_name,
        is_default=True
    )
    
    # Update profile last used
    if profile.get("profile_id"):
        await SessionService.update_profile_last_used(profile["profile_id"])
    
    # Get updated user context
    context = await LoginService.get_user_context(user_id=user_id, company_id=data.company_id)
    
    # Generate new token with updated company_id
    from middlewares import auth
    token_payload = {
        "user_id": user["user_id"],
        "username": user["username"],
        "user_type": user["user_type"],
        "is_super_admin": user.get("is_super_admin", False),
        "company_id": data.company_id
    }
    new_token = auth.create_jwt_token(token_payload)
    
    return {
        "user": context["user"],
        "company": context["company"],
        "access_token": new_token,
        "profile": profile
    }

@router.get("/sessions")
async def get_sessions(request: Request, db=Depends(get_db), user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"]))):
    """
    Get all active sessions for the current user.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    
    user_id = user.get("user_id")
    sessions = await SessionService.get_user_sessions(user_id, active_only=True)
    return {"sessions": sessions}

@router.delete("/sessions/{session_id}")
async def delete_session(request: Request, session_id: int, db=Depends(get_db), user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"]))):
    """
    Deactivate a session (logout from specific device).
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    
    user_id = user.get("user_id")
    await SessionService.deactivate_session(session_id, user_id)
    return {"message": "Session deactivated successfully"}

@router.delete("/accounts/{profile_id}")
async def delete_account_profile(request: Request, profile_id: int, db=Depends(get_db), user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"]))):
    """
    Delete an account profile.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    
    user_id = user.get("user_id")
    await SessionService.delete_account_profile(profile_id, user_id)
    return {"message": "Account profile deleted successfully"}

@router.get("/2fa/setup")
async def twofa_setup(
    request: Request,
    db=Depends(get_db),
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"])),
):
    """
    Start 2FA setup: generate TOTP secret and return provisioning URI for authenticator app.
    Saves secret to user; enable_2fa is set to True only after successful verify.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    import pyotp
    from classes.postgres_db import PostgresDB
    user_id = user["user_id"]
    username = user.get("username", "user")
    secret = pyotp.random_base32()
    totp = pyotp.TOTP(secret)
    provisioning_uri = totp.provisioning_uri(name=username, issuer_name="Noolva")
    await PostgresDB.execute(
        "UPDATE public.users SET mfa_secret = $1, enable_2fa = FALSE WHERE user_id = $2",
        secret, user_id
    )
    return {"secret": secret, "provisioning_uri": provisioning_uri}


@router.post("/2fa/verify")
async def twofa_verify(
    request: Request,
    data: Verify2FARequest,
    db=Depends(get_db),
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"])),
):
    """
    Verify TOTP code and enable 2FA for the current user.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    import pyotp
    from classes.postgres_db import PostgresDB
    user_id = user["user_id"]
    row = await PostgresDB.fetchrow(
        "SELECT mfa_secret FROM public.users WHERE user_id = $1", user_id
    )
    if not row or not row.get("mfa_secret"):
        raise HTTPException(status_code=400, detail="2FA setup not started. Call /auth/2fa/setup first.")
    totp = pyotp.TOTP(row["mfa_secret"])
    if not totp.verify(data.code.strip(), valid_window=1):
        raise HTTPException(status_code=400, detail="Invalid or expired code. Please try again.")
    await PostgresDB.execute(
        "UPDATE public.users SET enable_2fa = TRUE WHERE user_id = $1", user_id
    )
    return {"message": "Two-factor authentication enabled successfully"}


@router.post("/2fa/disable")
async def twofa_disable(
    request: Request,
    db=Depends(get_db),
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"])),
):
    """
    Disable 2FA and clear TOTP secret for the current user.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    from classes.postgres_db import PostgresDB
    user_id = user["user_id"]
    await PostgresDB.execute(
        "UPDATE public.users SET enable_2fa = FALSE, mfa_secret = NULL WHERE user_id = $1",
        user_id
    )
    return {"message": "Two-factor authentication disabled"}


@router.put("/me/idle-timeout")
async def update_my_idle_timeout(
    request: Request,
    data: MyIdleTimeoutRequest,
    db=Depends(get_db),
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"])),
):
    """
    Update current user's idle_timeout_minutes. null = use global default, -1 = no lock, >0 = lock after N minutes.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    user_id = user["user_id"]
    value = data.idle_timeout_minutes
    if value is not None and (value < -1 or value > 1440):
        raise HTTPException(status_code=400, detail="idle_timeout_minutes must be between -1 and 1440, or null for default")
    await LoginService.update_my_idle_timeout(user_id, value)
    return {"message": "Idle timeout updated", "idle_timeout_minutes": value}


@router.post("/reauth")
async def reauth(
    request: Request,
    data: ReauthRequest,
    db=Depends(get_db),
    user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"])),
):
    """
    Re-authenticate after idle lock: verify password (and TOTP if 2FA enabled), return new token.
    Does not log the user out; just confirms identity and issues a fresh token.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    try:
        result = await LoginService.reauth_user(
            user_id=user["user_id"],
            company_id=user.get("company_id"),
            password=data.password,
            totp_code=data.totp_code,
        )
        return result
    except ERPError as e:
        return JSONResponse(status_code=400, content=e.to_dict())


@router.post("/logout")
async def logout(request: Request, db=Depends(get_db), user: Dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"]))):
    """
    Logout - deactivate all sessions for the user.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    
    user_id = user.get("user_id")
    await SessionService.deactivate_all_user_sessions(user_id)
    return {"message": "Logged out successfully"}
