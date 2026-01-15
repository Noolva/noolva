from fastapi import APIRouter,Depends
from middlewares import auth
from typing import Dict, List, Optional
router = APIRouter()
@router.post("/products")
def protected_route(current_user: Optional[Dict] = Depends(auth.verify_jwt_token(["saas-admin", "saas-employees"]))):
    return {"message": "Welcome!", "user": current_user}
 