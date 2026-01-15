from classes.postgres_db import PostgresDB
from fastapi import APIRouter, Depends, HTTPException,Form,Request
from errors import ERPError,ErrorType
import json
from pydantic import BaseModel, Field, ValidationError
from middlewares import auth
from models.authentication.login_service import LoginService

async def saas_login_model(request: Request = None, data: dict = None,db=None):
      #user_data = {**locals()}  # Collects all parameters into a dictionary
    if request: # for api route
        form_data = await request.form()
        user_data = dict(form_data)
    elif data:  #for cli or other access
        user_data = data
    else:
        raise ERPError("Missing login data", ErrorType.VALIDATION_ERROR)
    
    #validation
    class LoginSchema(BaseModel):
        username: str = Field(..., min_length=3, max_length=50)
        password: str = Field(..., min_length=5, max_length=100)
    try:
        validated_data = LoginSchema(**user_data).dict()  # Validate with Pydantic
        """ validated_data.update({
            "user_type": "saas-admin",  
        }) """
       
        # Fetch user by username (passwords are hashed, so we verify separately)
        user_record = await db.fetchrow(
            "SELECT * FROM public.users WHERE username = $1",
            validated_data["username"]
        )
        
        if not user_record:
            return {"status":0,"message":"No Such Login Exist"}
        
        # Verify password using LoginService
        if not LoginService.verify_password(validated_data["password"], user_record["password"]):
            return {"status":0,"message":"Invalid credentials"}
        
        # Check if user is active
        if user_record.get("active_status") != 1:
            return {"status":0,"message":"Account is inactive"}
        
        # Create token (exclude password from token payload)
        token_payload = {
            "user_id": user_record["user_id"],
            "username": user_record["username"],
            "user_type": user_record.get("user_type"),
            "is_super_admin": user_record.get("is_super_admin", False)
        }
        token = auth.create_jwt_token(token_payload)
        
        # Remove password from user record before returning
        user_record.pop("password", None)
        
        return {"status":1,"message":"Login Success","data":{"user":user_record,"access_token": token,}}
            
       
    except ValidationError as e:
        raise ERPError(e,ErrorType.VALIDATION_ERROR,{"inputs":user_data})
async def saas_resetpassword(request: Request = None, data: dict = None,db=None):
      #user_data = {**locals()}  # Collects all parameters into a dictionary
    if request: # for api route
        form_data = await request.form()
        user_data = dict(form_data)
    elif data:  #for cli or other access
        user_data = data
    else:
        raise ERPError("Missing login data", ErrorType.VALIDATION_ERROR)
    
    #validation
    class LoginSchema(BaseModel):
        username: str = Field(..., min_length=3, max_length=50)
        new_password: str = Field(..., min_length=5, max_length=100)
    try:
        validated_data = LoginSchema(**user_data).dict()  # Validate with Pydantic
        """ validated_data.update({
            "user_type": "saas-admin",  
        }) """

        username = validated_data["username"]
        # Use PostgresDB.fetchrow() to check if user exists
        change_user_data = await db.fetchrow(
            "SELECT user_id FROM public.users WHERE username = $1",
            username
        )
        print(change_user_data)

        if change_user_data:
            # Hash password before storing
            hashed_password = LoginService.get_password_hash(validated_data["new_password"])
            # Use PostgresDB.execute() to update password
            await db.execute(
                "UPDATE public.users SET password = $1, last_updated = CURRENT_TIMESTAMP WHERE username = $2",
                hashed_password,
                username
            )
            return {"status":1,"message":"Password changed","data":{"username":username}}
        else:
            return {"status":0,"message":"No Such username"}
            
       
    except ValidationError as e:
        raise ERPError(e,ErrorType.VALIDATION_ERROR,{"inputs":user_data})
    