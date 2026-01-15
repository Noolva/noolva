import json
from fastapi import Request
from classes.postgres_db import PostgresDB
from errors import ERPError, ErrorType

class AuditService:
    @staticmethod
    async def log_event(
        request: Request,
        action: str,
        resource_type: str,
        resource_id: str = None,
        details: dict = None,
        user_id: int = None,
        tenant_id: int = None,
        company_id: int = None
    ):
        """
        Logs an event to public.audit_logs.
        Silently fails (logs error) to prevent blocking the main request flow,
        unless critical.
        """
        try:
            ip_address = request.client.host if request.client else "unknown"
            user_agent = request.headers.get("user-agent", "unknown")
            
            # Serialize details
            details_json = json.dumps(details) if details else "{}"

            query = """
                INSERT INTO public.audit_logs 
                (user_id, tenant_id, company_id, action, resource_type, resource_id, details_json, ip_address, user_agent)
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
            """
            
            await PostgresDB.execute(
                query,
                user_id,
                tenant_id,
                company_id,
                action,
                resource_type,
                resource_id,
                details_json,
                ip_address,
                user_agent
            )
        except Exception as e:
            # Fallback logger
            print(f"AUDIT LOG FAILED: {str(e)}")
