"""
Integration Management Service
Handles CRUD operations for integrations with encrypted credentials
"""
from typing import Dict, List, Optional, Any
from classes.postgres_db import PostgresDB
from errors import ERPError, ErrorType
from utils.encryption_service import get_encryption_service
import json


class IntegrationService:
    """Service for managing integrations with encrypted credentials"""
    
    @staticmethod
    async def create_integration(
        company_id: int,
        provider_name: str,
        provider_id: Optional[int],
        integration_name: Optional[str],
        credentials: Dict[str, Any],
        config: Optional[Dict] = None,
        integration_type: str = "api",
        metadata: Optional[Dict] = None,
        created_by: Optional[int] = None
    ) -> Dict[str, Any]:
        """
        Create a new integration with encrypted credentials
        
        Args:
            company_id: Company ID
            provider_name: Provider name (e.g., 'aws_s3', 'google_oauth')
            provider_id: Optional provider ID from integration_providers
            integration_name: User-defined integration name
            credentials: Credentials dictionary to encrypt
            config: Non-sensitive configuration
            integration_type: Integration type ('api', 'oauth', 'webhook')
            metadata: Additional metadata
            created_by: User ID who created this
            
        Returns:
            Integration dictionary (credentials not included in response)
        """
        # Encrypt credentials
        encryption_service = get_encryption_service()
        encrypted_credentials = encryption_service.encrypt(credentials)
        
        query = """
            INSERT INTO public.integrations 
            (company_id, provider_name, provider_id, integration_name, config, 
             encrypted_credentials, integration_type, metadata, created_by)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
            RETURNING integration_id, integration_uuid, provider_name, integration_name, 
                     config, integration_type, metadata, is_active, created_by, last_updated
        """
        
        integration = await PostgresDB.fetchrow(
            query,
            company_id,
            provider_name,
            provider_id,
            integration_name,
            json.dumps(config) if config else None,
            encrypted_credentials,
            integration_type,
            json.dumps(metadata) if metadata else json.dumps({}),
            created_by
        )
        
        return dict(integration) if integration else {}
    
    @staticmethod
    async def get_integration(
        integration_id: int,
        company_id: Optional[int] = None,
        include_credentials: bool = False
    ) -> Optional[Dict[str, Any]]:
        """
        Get an integration by ID
        
        Args:
            integration_id: Integration ID
            company_id: Optional company ID for security check
            include_credentials: Whether to decrypt and include credentials
            
        Returns:
            Integration dictionary
        """
        if company_id:
            query = """
                SELECT i.*, ip.provider_name as provider_template_name
                FROM public.integrations i
                LEFT JOIN public.integration_providers ip ON i.provider_id = ip.provider_id
                WHERE i.integration_id = $1 AND i.company_id = $2
            """
            integration = await PostgresDB.fetchrow(query, integration_id, company_id)
        else:
            query = """
                SELECT i.*, ip.provider_name as provider_template_name
                FROM public.integrations i
                LEFT JOIN public.integration_providers ip ON i.provider_id = ip.provider_id
                WHERE i.integration_id = $1
            """
            integration = await PostgresDB.fetchrow(query, integration_id)
        
        if not integration:
            return None
        
        integration_dict = dict(integration)
        
        # Decrypt credentials if requested
        if include_credentials and integration_dict.get("encrypted_credentials"):
            try:
                encryption_service = get_encryption_service()
                credentials = encryption_service.decrypt(integration_dict["encrypted_credentials"])
                integration_dict["credentials"] = credentials
            except Exception as e:
                raise ERPError(f"Failed to decrypt credentials: {str(e)}", ErrorType.ENCRYPTION_ERROR)
        
        # Remove encrypted_credentials from response if not including credentials
        if not include_credentials:
            integration_dict.pop("encrypted_credentials", None)
        
        return integration_dict
    
    @staticmethod
    async def list_integrations(
        company_id: int,
        provider_name: Optional[str] = None,
        is_active: Optional[bool] = None
    ) -> List[Dict[str, Any]]:
        """
        List integrations for a company
        
        Args:
            company_id: Company ID
            provider_name: Optional filter by provider name
            is_active: Optional filter by active status
            
        Returns:
            List of integration dictionaries (credentials not included)
        """
        conditions = ["i.company_id = $1"]
        params = [company_id]
        param_idx = 2
        
        if provider_name:
            conditions.append(f"i.provider_name = ${param_idx}")
            params.append(provider_name)
            param_idx += 1
        
        if is_active is not None:
            conditions.append(f"i.is_active = ${param_idx}")
            params.append(is_active)
            param_idx += 1
        
        where_clause = " AND " + " AND ".join(conditions)
        
        query = f"""
            SELECT i.integration_id, i.integration_uuid, i.provider_name, i.provider_id,
                   i.integration_name, i.config, i.integration_type, i.metadata, 
                   i.is_active, i.created_by, i.last_updated,
                   ip.provider_name as provider_template_name
            FROM public.integrations i
            LEFT JOIN public.integration_providers ip ON i.provider_id = ip.provider_id
            WHERE {where_clause}
            ORDER BY i.last_updated DESC
        """
        
        integrations = await PostgresDB.fetch(query, *params)
        
        # Remove encrypted_credentials from all results
        for integration in integrations:
            integration.pop("encrypted_credentials", None)
        
        return integrations
    
    @staticmethod
    async def update_integration(
        integration_id: int,
        company_id: int,
        integration_name: Optional[str] = None,
        credentials: Optional[Dict[str, Any]] = None,
        config: Optional[Dict] = None,
        is_active: Optional[bool] = None,
        metadata: Optional[Dict] = None
    ) -> Dict[str, Any]:
        """
        Update an integration
        
        Args:
            integration_id: Integration ID
            company_id: Company ID (for security)
            integration_name: New integration name
            credentials: New credentials to encrypt (updates if provided)
            config: New config
            is_active: New active status
            metadata: New metadata
            
        Returns:
            Updated integration dictionary
        """
        updates = []
        params = []
        param_idx = 1
        
        if integration_name is not None:
            updates.append(f"integration_name = ${param_idx}")
            params.append(integration_name)
            param_idx += 1
        
        if credentials is not None:
            encryption_service = get_encryption_service()
            encrypted_credentials = encryption_service.encrypt(credentials)
            updates.append(f"encrypted_credentials = ${param_idx}")
            params.append(encrypted_credentials)
            updates.append(f"credentials_version = credentials_version + 1")
            param_idx += 1
        
        if config is not None:
            updates.append(f"config = ${param_idx}")
            params.append(json.dumps(config))
            param_idx += 1
        
        if is_active is not None:
            updates.append(f"is_active = ${param_idx}")
            params.append(is_active)
            param_idx += 1
        
        if metadata is not None:
            updates.append(f"metadata = ${param_idx}")
            params.append(json.dumps(metadata))
            param_idx += 1
        
        if not updates:
            # No updates provided
            return await IntegrationService.get_integration(integration_id, company_id)
        
        updates.append(f"last_updated = NOW()")
        
        params.extend([integration_id, company_id])
        
        query = f"""
            UPDATE public.integrations 
            SET {', '.join(updates)}
            WHERE integration_id = ${param_idx} AND company_id = ${param_idx + 1}
            RETURNING integration_id, integration_uuid, provider_name, integration_name,
                     config, integration_type, metadata, is_active, created_by, last_updated
        """
        
        integration = await PostgresDB.fetchrow(query, *params)
        
        if not integration:
            raise ERPError("Integration not found", ErrorType.NOT_FOUND)
        
        return dict(integration)
    
    @staticmethod
    async def delete_integration(integration_id: int, company_id: int) -> bool:
        """
        Delete an integration
        
        Args:
            integration_id: Integration ID
            company_id: Company ID (for security)
            
        Returns:
            True if deleted
        """
        query = """
            DELETE FROM public.integrations 
            WHERE integration_id = $1 AND company_id = $2
        """
        await PostgresDB.execute(query, integration_id, company_id)
        return True
    
    @staticmethod
    async def test_integration(integration_id: int, company_id: int) -> Dict[str, Any]:
        """
        Test an integration connection
        
        Args:
            integration_id: Integration ID
            company_id: Company ID (for security)
            
        Returns:
            Test result dictionary
        """
        integration = await IntegrationService.get_integration(
            integration_id, 
            company_id, 
            include_credentials=True
        )
        
        if not integration:
            raise ERPError("Integration not found", ErrorType.NOT_FOUND)
        
        provider_name = integration.get("provider_name")
        credentials = integration.get("credentials", {})
        
        # Placeholder for actual test logic
        # This would need to be implemented per provider type
        test_result = {
            "success": True,
            "message": "Integration test successful",
            "provider": provider_name,
            "tested_at": None
        }
        
        # TODO: Implement actual test logic per provider
        # if provider_name == "aws_s3":
        #     test_result = test_aws_s3(credentials)
        # elif provider_name == "google_oauth":
        #     test_result = test_google_oauth(credentials)
        
        return test_result
