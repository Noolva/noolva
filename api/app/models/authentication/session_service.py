"""
Session Management Service
Handles user sessions, multi-account support, and account switching
"""
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from classes.postgres_db import PostgresDB
from errors import ERPError, ErrorType
import json


class SessionService:
    """Service for managing user sessions and multi-account support"""
    
    @staticmethod
    async def create_session(
        user_id: int,
        company_id: Optional[int],
        login_method: str,
        device_info: Optional[Dict] = None,
        ip_address: Optional[str] = None,
        user_agent: Optional[str] = None,
        expires_hours: int = 24
    ) -> Dict[str, Any]:
        """
        Create a new user session
        
        Args:
            user_id: User ID
            company_id: Optional company ID
            login_method: Login method ('password', 'google_oauth', 'mfa')
            device_info: Device information dict
            ip_address: Client IP address
            user_agent: Client user agent
            expires_hours: Session expiration in hours
            
        Returns:
            Session dictionary
        """
        expires_at = datetime.utcnow() + timedelta(hours=expires_hours)
        
        query = """
            INSERT INTO public.user_sessions 
            (user_id, company_id, login_method, device_info, ip_address, user_agent, expires_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING session_id, session_uuid, login_at, expires_at
        """
        
        session = await PostgresDB.fetchrow(
            query,
            user_id,
            company_id,
            login_method,
            json.dumps(device_info) if device_info else None,
            ip_address,
            user_agent,
            expires_at
        )
        
        return dict(session) if session else {}
    
    @staticmethod
    async def get_user_sessions(user_id: int, active_only: bool = True) -> List[Dict[str, Any]]:
        """
        Get all sessions for a user
        
        Args:
            user_id: User ID
            active_only: Only return active sessions
            
        Returns:
            List of session dictionaries
        """
        if active_only:
            query = """
                SELECT s.*, c.company_name
                FROM public.user_sessions s
                LEFT JOIN public.companies c ON s.company_id = c.company_id
                WHERE s.user_id = $1 
                  AND s.is_active = TRUE 
                  AND s.expires_at > NOW()
                ORDER BY s.last_activity DESC
            """
        else:
            query = """
                SELECT s.*, c.company_name
                FROM public.user_sessions s
                LEFT JOIN public.companies c ON s.company_id = c.company_id
                WHERE s.user_id = $1
                ORDER BY s.last_activity DESC
            """
        
        sessions = await PostgresDB.fetch(query, user_id)
        return sessions
    
    @staticmethod
    async def update_session_activity(session_id: int):
        """Update last activity timestamp for a session"""
        query = """
            UPDATE public.user_sessions 
            SET last_activity = NOW() 
            WHERE session_id = $1
        """
        await PostgresDB.execute(query, session_id)
    
    @staticmethod
    async def deactivate_session(session_id: int, user_id: int):
        """
        Deactivate a session (logout)
        
        Args:
            session_id: Session ID
            user_id: User ID (for security)
        """
        query = """
            UPDATE public.user_sessions 
            SET is_active = FALSE 
            WHERE session_id = $1 AND user_id = $2
        """
        await PostgresDB.execute(query, session_id, user_id)
    
    @staticmethod
    async def deactivate_all_user_sessions(user_id: int, except_session_id: Optional[int] = None):
        """
        Deactivate all sessions for a user (except optionally one)
        
        Args:
            user_id: User ID
            except_session_id: Optional session ID to keep active
        """
        if except_session_id:
            query = """
                UPDATE public.user_sessions 
                SET is_active = FALSE 
                WHERE user_id = $1 AND session_id != $2
            """
            await PostgresDB.execute(query, user_id, except_session_id)
        else:
            query = """
                UPDATE public.user_sessions 
                SET is_active = FALSE 
                WHERE user_id = $1
            """
            await PostgresDB.execute(query, user_id)
    
    @staticmethod
    async def get_user_account_profiles(user_id: int) -> List[Dict[str, Any]]:
        """
        Get all account profiles for a user
        
        Args:
            user_id: User ID
            
        Returns:
            List of account profile dictionaries
        """
        query = """
            SELECT p.*, c.company_name, c.company_code
            FROM public.user_account_profiles p
            LEFT JOIN public.companies c ON p.company_id = c.company_id
            WHERE p.user_id = $1
            ORDER BY p.is_default DESC, p.last_used DESC
        """
        
        profiles = await PostgresDB.fetch(query, user_id)
        return profiles
    
    @staticmethod
    async def create_or_update_account_profile(
        user_id: int,
        company_id: Optional[int],
        profile_name: Optional[str] = None,
        is_default: bool = False,
        preferences: Optional[Dict] = None
    ) -> Dict[str, Any]:
        """
        Create or update an account profile
        
        Args:
            user_id: User ID
            company_id: Company ID
            profile_name: Profile name
            is_default: Whether this is the default profile
            preferences: Profile preferences
            
        Returns:
            Profile dictionary
        """
        # If setting as default, unset other defaults
        if is_default:
            await PostgresDB.execute(
                "UPDATE public.user_account_profiles SET is_default = FALSE WHERE user_id = $1",
                user_id
            )
        
        # Generate default profile name if not provided
        if not profile_name:
            if company_id:
                company = await PostgresDB.fetchrow(
                    "SELECT company_name FROM public.companies WHERE company_id = $1",
                    company_id
                )
                profile_name = company.get("company_name", "Work Account") if company else "Work Account"
            else:
                profile_name = "Personal Account"
        
        # Check if profile exists
        existing = await PostgresDB.fetchrow(
            """
            SELECT profile_id FROM public.user_account_profiles 
            WHERE user_id = $1 AND company_id = $2 AND profile_name = $3
            """,
            user_id,
            company_id,
            profile_name
        )
        
        if existing:
            # Update existing profile
            query = """
                UPDATE public.user_account_profiles
                SET is_default = $1, preferences = $2, last_used = NOW()
                WHERE profile_id = $3
                RETURNING *
            """
            profile = await PostgresDB.fetchrow(
                query,
                is_default,
                json.dumps(preferences) if preferences else json.dumps({}),
                existing["profile_id"]
            )
        else:
            # Create new profile
            query = """
                INSERT INTO public.user_account_profiles
                (user_id, company_id, profile_name, is_default, preferences)
                VALUES ($1, $2, $3, $4, $5)
                RETURNING *
            """
            profile = await PostgresDB.fetchrow(
                query,
                user_id,
                company_id,
                profile_name,
                is_default,
                json.dumps(preferences) if preferences else json.dumps({})
            )
        
        return dict(profile) if profile else {}
    
    @staticmethod
    async def update_profile_last_used(profile_id: int):
        """Update last_used timestamp for a profile"""
        query = """
            UPDATE public.user_account_profiles 
            SET last_used = NOW() 
            WHERE profile_id = $1
        """
        await PostgresDB.execute(query, profile_id)
    
    @staticmethod
    async def delete_account_profile(profile_id: int, user_id: int):
        """
        Delete an account profile
        
        Args:
            profile_id: Profile ID
            user_id: User ID (for security)
        """
        query = """
            DELETE FROM public.user_account_profiles 
            WHERE profile_id = $1 AND user_id = $2
        """
        await PostgresDB.execute(query, profile_id, user_id)
