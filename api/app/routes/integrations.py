"""
Integration Management Routes
Handles CRUD operations for integrations
"""
from fastapi import APIRouter, Depends, Request, HTTPException
from pydantic import BaseModel
from typing import Optional, Dict, Any, List
from models.integrations.integration_service import IntegrationService
from middlewares.auth import verify_jwt_token
from utils.db import get_db

router = APIRouter(prefix="/integrations", tags=["Integrations"])

class CreateIntegrationRequest(BaseModel):
    provider_name: str
    provider_id: Optional[int] = None
    integration_name: Optional[str] = None
    credentials: Dict[str, Any]
    config: Optional[Dict[str, Any]] = None
    integration_type: str = "api"
    metadata: Optional[Dict[str, Any]] = None

class UpdateIntegrationRequest(BaseModel):
    integration_name: Optional[str] = None
    credentials: Optional[Dict[str, Any]] = None
    config: Optional[Dict[str, Any]] = None
    is_active: Optional[bool] = None
    metadata: Optional[Dict[str, Any]] = None

@router.get("/")
async def list_integrations(
    request: Request,
    provider_name: Optional[str] = None,
    is_active: Optional[bool] = None,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "tenant_admin", "tenant_user"]))
):
    """
    List all integrations for the user's company.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    
    company_id = user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=400, detail="Company context required")
    
    integrations = await IntegrationService.list_integrations(
        company_id=company_id,
        provider_name=provider_name,
        is_active=is_active
    )
    
    return {"integrations": integrations}

@router.get("/{integration_id}")
async def get_integration(
    request: Request,
    integration_id: int,
    include_credentials: bool = False,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "tenant_admin"]))
):
    """
    Get an integration by ID.
    Only admins can include credentials.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    
    company_id = user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=400, detail="Company context required")
    
    integration = await IntegrationService.get_integration(
        integration_id=integration_id,
        company_id=company_id,
        include_credentials=include_credentials
    )
    
    if not integration:
        raise HTTPException(status_code=404, detail="Integration not found")
    
    return {"integration": integration}

@router.post("/")
async def create_integration(
    request: Request,
    data: CreateIntegrationRequest,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "tenant_admin"]))
):
    """
    Create a new integration.
    Credentials will be encrypted before storage.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    
    company_id = user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=400, detail="Company context required")
    
    integration = await IntegrationService.create_integration(
        company_id=company_id,
        provider_name=data.provider_name,
        provider_id=data.provider_id,
        integration_name=data.integration_name,
        credentials=data.credentials,
        config=data.config,
        integration_type=data.integration_type,
        metadata=data.metadata,
        created_by=user.get("user_id")
    )
    
    return {"integration": integration, "message": "Integration created successfully"}

@router.put("/{integration_id}")
async def update_integration(
    request: Request,
    integration_id: int,
    data: UpdateIntegrationRequest,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "tenant_admin"]))
):
    """
    Update an integration.
    Credentials will be encrypted if provided.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    
    company_id = user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=400, detail="Company context required")
    
    integration = await IntegrationService.update_integration(
        integration_id=integration_id,
        company_id=company_id,
        integration_name=data.integration_name,
        credentials=data.credentials,
        config=data.config,
        is_active=data.is_active,
        metadata=data.metadata
    )
    
    return {"integration": integration, "message": "Integration updated successfully"}

@router.delete("/{integration_id}")
async def delete_integration(
    request: Request,
    integration_id: int,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "tenant_admin"]))
):
    """
    Delete an integration.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    
    company_id = user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=400, detail="Company context required")
    
    await IntegrationService.delete_integration(integration_id, company_id)
    
    return {"message": "Integration deleted successfully"}

@router.post("/{integration_id}/test")
async def test_integration(
    request: Request,
    integration_id: int,
    user: Dict = Depends(verify_jwt_token(["saas_admin", "tenant_admin"]))
):
    """
    Test an integration connection.
    """
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    
    company_id = user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=400, detail="Company context required")
    
    result = await IntegrationService.test_integration(integration_id, company_id)
    
    return {"result": result}
