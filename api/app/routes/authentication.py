from fastapi import APIRouter, Depends, Request, HTTPException, Header
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import Optional, List, Dict
from models.authentication.login_service import LoginService
from models.authentication.session_service import SessionService
from middlewares.auth import verify_jwt_token
from utils.db import get_db
from errors.base_error import ERPError

router = APIRouter()

class LoginRequest(BaseModel):
    identifier: str  # username, email, or phone
    password: str
    company_id: Optional[int] = None

class CreateUserRequest(BaseModel):
    username: str
    password: str = None  # Optional for updates
    email: str = None
    phone: str = None
    user_type: str = "user"
    active_status: int = 1
    is_super_admin: bool = False

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

@router.post("/create-user")
async def create_user(request: Request, data: CreateUserRequest, db=Depends(get_db)):
    """
    Creates or Updates a User. Encrypts password.
    """
    # Passing request for Audit Logging
    return await LoginService.create_or_update_user(data.dict())

@router.post("/login")
async def login(request: Request, data: LoginRequest, db=Depends(get_db)):
    """
    Standard Login via Username/Email/Phone & Password.
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
