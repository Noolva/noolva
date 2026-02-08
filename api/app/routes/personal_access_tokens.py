"""
Personal Access Tokens (PAT) Routes
Create, list, and revoke PATs. Tokens are shown in plaintext only on create.
"""

import json
import secrets
import hashlib
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional, List, Any
from middlewares.auth import verify_jwt_token
from utils.db import get_db
from classes.postgres_db import PostgresDB

router = APIRouter()

PAT_PREFIX = "nvpat_"


class CreatePATRequest(BaseModel):
    name: str
    expires_days: int = 90
    company_id: Optional[int] = None
    scopes: Optional[List[str]] = None


@router.post("/create")
async def create_pat(
    body: CreatePATRequest,
    user: dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"])),
    db=Depends(get_db),
):
    """
    Create a new Personal Access Token. The plaintext token is returned only once; store it securely.
    """
    if not body.name or not body.name.strip():
        raise HTTPException(status_code=400, detail="name is required")
    if body.expires_days < 1 or body.expires_days > 3650:
        raise HTTPException(status_code=400, detail="expires_days must be between 1 and 3650")
    plaintext = f"{PAT_PREFIX}{secrets.token_hex(32)}"
    token_hash = hashlib.sha256(plaintext.encode("utf-8")).hexdigest()
    expires_at = datetime.utcnow() + timedelta(days=body.expires_days)
    scopes_json = body.scopes if body.scopes is not None else []
    row = await PostgresDB.fetchrow(
        """
        INSERT INTO public.personal_access_tokens
        (user_id, company_id, name, token_hash, scopes_json, expires_at)
        VALUES ($1, $2, $3, $4, $5::jsonb, $6)
        RETURNING pat_id, pat_uuid, name, expires_at, created_at
        """,
        user["user_id"],
        body.company_id,
        body.name.strip(),
        token_hash,
        json.dumps(scopes_json),
        expires_at,
    )
    return {
        "pat_id": row["pat_id"],
        "pat_uuid": str(row["pat_uuid"]),
        "name": row["name"],
        "expires_at": row["expires_at"].isoformat() if row.get("expires_at") else None,
        "created_at": row["created_at"].isoformat() if row.get("created_at") else None,
        "token": plaintext,
        "message": "Copy the token now; it will not be shown again.",
    }


@router.get("/list")
async def list_pats(
    user: dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"])),
    db=Depends(get_db),
):
    """List current user's Personal Access Tokens (without token values)."""
    rows = await PostgresDB.fetch(
        """
        SELECT pat_id, pat_uuid, name, scopes_json, expires_at, last_used_at, created_at, company_id
        FROM public.personal_access_tokens
        WHERE user_id = $1
        ORDER BY created_at DESC
        """,
        user["user_id"],
    )
    data = []
    for r in rows or []:
        data.append({
            "pat_id": r["pat_id"],
            "pat_uuid": str(r["pat_uuid"]),
            "name": r["name"],
            "scopes": r.get("scopes_json") or [],
            "expires_at": r["expires_at"].isoformat() if r.get("expires_at") else None,
            "last_used_at": r["last_used_at"].isoformat() if r.get("last_used_at") else None,
            "created_at": r["created_at"].isoformat() if r.get("created_at") else None,
            "company_id": r.get("company_id"),
        })
    return {"tokens": data}


@router.delete("/{pat_id}")
async def revoke_pat(
    pat_id: int,
    user: dict = Depends(verify_jwt_token(["saas_admin", "saas_employee", "tenant_admin", "tenant_user"])),
    db=Depends(get_db),
):
    """Revoke a Personal Access Token. Only the owner can revoke."""
    result = await PostgresDB.execute(
        "DELETE FROM public.personal_access_tokens WHERE pat_id = $1 AND user_id = $2",
        pat_id,
        user["user_id"],
    )
    if result == "DELETE 0":
        raise HTTPException(status_code=404, detail="Token not found or you do not own it")
    return {"revoked": True, "pat_id": pat_id}
