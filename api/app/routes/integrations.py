"""
Company integrations: providers registry and CRUD for integrations (encrypted credentials).
"""

import json
import logging
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from middlewares.auth import verify_jwt_token
from utils.db import get_db
from classes.postgres_db import PostgresDB
from utils.encryption_service import get_encryption_service

logger = logging.getLogger(__name__)

router = APIRouter()


def _parse_jsonb(val: Any) -> Any:
    if val is None:
        return None
    if isinstance(val, (dict, list)):
        return val
    if isinstance(val, str):
        try:
            return json.loads(val)
        except json.JSONDecodeError:
            return val
    return val


_PG_INT_MAX = 2147483647
_PG_INT_MIN = -2147483648


async def _resolve_company_scope(user: dict, company_id: Optional[int]) -> int:
    """
    Resolve target company: explicit company_id (query/body), then JWT company_id,
    then first row in public.companies (single-tenant / setup default), same idea as default S3.
    """
    jwt_cid = user.get("company_id")
    if company_id is not None:
        q = int(company_id)
        if q < _PG_INT_MIN or q > _PG_INT_MAX:
            raise HTTPException(
                status_code=400,
                detail="company_id is out of valid range (use the database company id, not a session key)",
            )
        if jwt_cid is not None and int(jwt_cid) != q:
            if not user.get("is_super_admin"):
                raise HTTPException(
                    status_code=403,
                    detail="company_id does not match your active company",
                )
        return q
    if jwt_cid is not None:
        j = int(jwt_cid)
        if j < _PG_INT_MIN or j > _PG_INT_MAX:
            raise HTTPException(
                status_code=400,
                detail="company_id is out of valid range",
            )
        return j
    row = await PostgresDB.fetchrow(
        "SELECT company_id FROM public.companies ORDER BY company_id ASC LIMIT 1"
    )
    if not row:
        raise HTTPException(
            status_code=400,
            detail="No company configured; create a company or pass company_id",
        )
    cid = int(row["company_id"])
    logger.info(
        "integrations: no company in request/session; using default company_id=%s",
        cid,
    )
    return cid


async def _get_integration_for_company(integration_id: int, company_id: int) -> Optional[Dict[str, Any]]:
    row = await PostgresDB.fetchrow(
        """
        SELECT i.*, p.provider_display_name, p.provider_category
        FROM public.integrations i
        LEFT JOIN public.integration_providers p ON p.provider_id = i.provider_id
        WHERE i.integration_id = $1 AND i.company_id = $2
        """,
        integration_id,
        company_id,
    )
    return dict(row) if row else None


def _validate_credentials_for_provider(
    credentials: Dict[str, Any],
    provider: Dict[str, Any],
) -> None:
    required = _parse_jsonb(provider.get("required_fields_json")) or []
    if not isinstance(required, list):
        return
    for f in required:
        if not isinstance(f, dict):
            continue
        if not f.get("is_required"):
            continue
        name = f.get("field_name")
        if not name:
            continue
        v = credentials.get(name)
        if v is None or (isinstance(v, str) and not v.strip()):
            raise HTTPException(
                status_code=400,
                detail=f"Missing required credential field: {f.get('display_name') or name}",
            )


def _apply_defaults_from_provider(
    credentials: Dict[str, Any], provider: Dict[str, Any]
) -> Dict[str, Any]:
    out = dict(credentials)
    for key in ("required_fields_json", "optional_fields_json"):
        fields = _parse_jsonb(provider.get(key)) or []
        if not isinstance(fields, list):
            continue
        for f in fields:
            if not isinstance(f, dict):
                continue
            fn = f.get("field_name")
            if not fn or fn in out:
                continue
            dv = f.get("default_value")
            if dv is not None and dv != "":
                out[fn] = dv
    return out


@router.get("/providers")
async def list_integration_providers(
    user: dict = Depends(
        verify_jwt_token(
            ["saas_admin", "saas_employee", "tenant_admin", "tenant_user"]
        )
    ),
    db=Depends(get_db),
):
    rows = await PostgresDB.fetch(
        """
        SELECT provider_id, provider_uuid, provider_name, provider_display_name,
               provider_category, description, documentation_url,
               required_fields_json, optional_fields_json, metadata_json,
               is_active, is_builtin, created_at, last_updated
        FROM public.integration_providers
        WHERE is_active = TRUE
        ORDER BY provider_category, provider_display_name
        """
    )
    return {"providers": [dict(r) for r in rows]}


@router.get("")
async def list_integrations(
    company_id: Optional[int] = Query(None),
    user: dict = Depends(
        verify_jwt_token(
            ["saas_admin", "saas_employee", "tenant_admin", "tenant_user"]
        )
    ),
    db=Depends(get_db),
):
    cid = await _resolve_company_scope(user, company_id)
    rows = await PostgresDB.fetch(
        """
        SELECT i.integration_id, i.integration_uuid, i.company_id, i.provider_id,
               i.provider_name, i.integration_name, i.config, i.integration_type,
               i.metadata, i.is_active, i.is_default, i.created_by, i.last_updated,
               p.provider_display_name, p.provider_category,
               (i.encrypted_credentials IS NOT NULL AND length(trim(i.encrypted_credentials)) > 0) AS has_credentials
        FROM public.integrations i
        LEFT JOIN public.integration_providers p ON p.provider_id = i.provider_id
        WHERE i.company_id = $1
        ORDER BY p.provider_category NULLS LAST, i.integration_name NULLS LAST, i.integration_id
        """,
        cid,
    )
    out = []
    for r in rows:
        d = dict(r)
        if d.get("integration_uuid") is not None:
            d["integration_uuid"] = str(d["integration_uuid"])
        d["config"] = _parse_jsonb(d.get("config"))
        d["metadata"] = _parse_jsonb(d.get("metadata"))
        out.append(d)
    return {"integrations": out, "company_id": cid}


class IntegrationCreateBody(BaseModel):
    company_id: Optional[int] = None
    provider_id: Optional[int] = None
    provider_name: Optional[str] = None
    integration_name: Optional[str] = None
    credentials: Dict[str, Any] = Field(default_factory=dict)
    config: Optional[Dict[str, Any]] = None
    integration_type: str = "api"
    metadata: Optional[Dict[str, Any]] = None
    is_active: bool = True
    is_default: bool = False


@router.post("")
async def create_integration(
    body: IntegrationCreateBody,
    user: dict = Depends(
        verify_jwt_token(
            ["saas_admin", "saas_employee", "tenant_admin", "tenant_user"]
        )
    ),
    db=Depends(get_db),
):
    cid = await _resolve_company_scope(user, body.company_id)
    prov = None
    if body.provider_id is not None:
        prov = await PostgresDB.fetchrow(
            "SELECT * FROM public.integration_providers WHERE provider_id = $1 AND is_active = TRUE",
            body.provider_id,
        )
    elif body.provider_name:
        prov = await PostgresDB.fetchrow(
            "SELECT * FROM public.integration_providers WHERE provider_name = $1 AND is_active = TRUE",
            body.provider_name.strip(),
        )
    if not prov:
        raise HTTPException(status_code=400, detail="Unknown or inactive integration provider")

    creds = _apply_defaults_from_provider(dict(body.credentials or {}), dict(prov))
    _validate_credentials_for_provider(creds, dict(prov))

    enc = get_encryption_service()
    encrypted = enc.encrypt(creds)
    pname = prov["provider_name"]
    config_json = json.dumps(body.config) if body.config is not None else None
    meta_json = json.dumps(body.metadata) if body.metadata is not None else "{}"

    if body.is_default:
        await PostgresDB.execute(
            """
            UPDATE public.integrations
            SET is_default = FALSE
            WHERE company_id = $1 AND provider_name = $2 AND is_default = TRUE
            """,
            cid,
            pname,
        )

    row = await PostgresDB.fetchrow(
        """
        INSERT INTO public.integrations (
            company_id, provider_id, provider_name, integration_name,
            encrypted_credentials, credentials_version, config, integration_type,
            metadata, is_active, is_default, created_by
        )
        VALUES ($1, $2, $3, $4, $5, 1, $6::jsonb, $7, $8::jsonb, $9, $10, $11)
        RETURNING integration_id, integration_uuid, company_id, provider_id, provider_name,
                  integration_name, config, integration_type, metadata, is_active, is_default, last_updated
        """,
        cid,
        prov["provider_id"],
        pname,
        (body.integration_name or "").strip() or f"{prov['provider_display_name']}",
        encrypted,
        config_json,
        body.integration_type,
        meta_json,
        body.is_active,
        body.is_default,
        user.get("user_id"),
    )
    d = dict(row)
    d["integration_uuid"] = str(d["integration_uuid"])
    d["config"] = _parse_jsonb(d.get("config"))
    d["metadata"] = _parse_jsonb(d.get("metadata"))
    d["has_credentials"] = True
    d["provider_display_name"] = prov["provider_display_name"]
    return d


class IntegrationUpdateBody(BaseModel):
    company_id: Optional[int] = None
    integration_name: Optional[str] = None
    credentials: Optional[Dict[str, Any]] = None
    config: Optional[Dict[str, Any]] = None
    integration_type: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None
    is_active: Optional[bool] = None
    is_default: Optional[bool] = None


@router.put("/{integration_id}")
async def update_integration(
    integration_id: int,
    body: IntegrationUpdateBody,
    user: dict = Depends(
        verify_jwt_token(
            ["saas_admin", "saas_employee", "tenant_admin", "tenant_user"]
        )
    ),
    db=Depends(get_db),
):
    cid = await _resolve_company_scope(user, body.company_id)
    row = await _get_integration_for_company(integration_id, cid)
    if not row:
        raise HTTPException(status_code=404, detail="Integration not found")

    prov = await PostgresDB.fetchrow(
        "SELECT * FROM public.integration_providers WHERE provider_id = $1",
        row["provider_id"],
    )
    if not prov:
        prov = {"required_fields_json": [], "optional_fields_json": [], "provider_name": row["provider_name"]}

    enc = get_encryption_service()
    encrypted = row.get("encrypted_credentials")
    if body.credentials is not None and len(body.credentials) > 0:
        existing: Dict[str, Any] = {}
        if encrypted:
            try:
                existing = enc.decrypt(encrypted) or {}
            except Exception as e:
                logger.warning("Decrypt existing integration %s failed: %s", integration_id, e)
                raise HTTPException(
                    status_code=500,
                    detail="Could not decrypt existing credentials for merge",
                ) from e
        merged = dict(existing)
        for k, v in body.credentials.items():
            if v is None or (isinstance(v, str) and v == ""):
                continue
            merged[k] = v
        _validate_credentials_for_provider(merged, dict(prov))
        encrypted = enc.encrypt(merged)

    pname = row["provider_name"]
    if body.is_default is True:
        await PostgresDB.execute(
            """
            UPDATE public.integrations
            SET is_default = FALSE
            WHERE company_id = $1 AND provider_name = $2 AND integration_id <> $3 AND is_default = TRUE
            """,
            cid,
            pname,
            integration_id,
        )

    sets: List[str] = []
    args: List[Any] = []

    def add_set(column: str, value: Any, cast: str = "") -> None:
        args.append(value)
        ph = f"${len(args)}" + cast
        sets.append(f"{column} = {ph}")

    if encrypted != row.get("encrypted_credentials"):
        add_set("encrypted_credentials", encrypted)

    if body.integration_name is not None:
        add_set("integration_name", body.integration_name.strip() or row.get("integration_name"))

    if body.config is not None:
        add_set("config", json.dumps(body.config), "::jsonb")

    if body.integration_type is not None:
        add_set("integration_type", body.integration_type)

    if body.metadata is not None:
        add_set("metadata", json.dumps(body.metadata), "::jsonb")

    if body.is_active is not None:
        add_set("is_active", body.is_active)

    if body.is_default is not None:
        add_set("is_default", body.is_default)

    if not sets:
        raise HTTPException(status_code=400, detail="No fields to update")

    sets.append("last_updated = CURRENT_TIMESTAMP")
    args.append(integration_id)
    args.append(cid)
    i1 = len(args) - 1
    i2 = len(args)
    q = f"""
        UPDATE public.integrations
        SET {", ".join(sets)}
        WHERE integration_id = ${i1} AND company_id = ${i2}
        RETURNING integration_id, integration_uuid, company_id, provider_id, provider_name,
                  integration_name, config, integration_type, metadata, is_active, is_default, last_updated,
                  (encrypted_credentials IS NOT NULL AND length(trim(encrypted_credentials)) > 0) AS has_credentials
    """
    updated = await PostgresDB.fetchrow(q, *args)
    d = dict(updated)
    d["integration_uuid"] = str(d["integration_uuid"])
    d["config"] = _parse_jsonb(d.get("config"))
    d["metadata"] = _parse_jsonb(d.get("metadata"))
    prow = await PostgresDB.fetchrow(
        "SELECT provider_display_name FROM public.integration_providers WHERE provider_id = $1",
        d.get("provider_id"),
    )
    if prow:
        d["provider_display_name"] = prow["provider_display_name"]
    return d


@router.delete("/{integration_id}")
async def delete_integration(
    integration_id: int,
    company_id: Optional[int] = Query(None),
    user: dict = Depends(
        verify_jwt_token(
            ["saas_admin", "saas_employee", "tenant_admin", "tenant_user"]
        )
    ),
    db=Depends(get_db),
):
    cid = await _resolve_company_scope(user, company_id)
    res = await PostgresDB.execute(
        """
        DELETE FROM public.integrations
        WHERE integration_id = $1 AND company_id = $2
        """,
        integration_id,
        cid,
    )
    if res == "DELETE 0":
        raise HTTPException(status_code=404, detail="Integration not found")
    return {"ok": True, "integration_id": integration_id}
