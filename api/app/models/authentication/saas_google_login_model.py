# saas_google_login_model.py
from fastapi import Request
from fastapi.responses import RedirectResponse
from errors import ERPError, ErrorType
from middlewares import auth
import json

async def saas_google_login_model(request: Request, db):
    oauth = request.app.state.oauth
    token = await oauth.google.authorize_access_token(request)
    print("Token response:", token)  # Optional: For debugging

    # Use already-parsed userinfo from token
    user_info = token.get("userinfo")

    if not user_info:
        raise ERPError("Failed to fetch user info from Google", ErrorType.AUTHENTICATION_ERROR)

    email = user_info.get("email")
    name = user_info.get("name")

    # Check or register in DB using PostgresDB.fetchrow()
    user_record = await db.fetchrow(
        "SELECT * FROM public.users WHERE username = $1",
        email
    )

    if not user_record:
        # Optional: Auto-register user if not exists
        return {"status": 0, "message": "User not found. Please contact admin or sign up."}

    # Create JWT
    token = auth.create_jwt_token(user_record)
    return {
        "status": 1,
        "message": "Google Login Success",
        "data": {"user": user_record, "access_token": token}
    }
