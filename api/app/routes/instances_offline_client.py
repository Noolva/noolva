"""
Client-facing offline sync: manifest, schema pack, snapshot URL, instance navigation menus.
Auth: Bearer JWT or PAT (same as /upload). Instance access respects instances.company_id.
"""
from __future__ import annotations

import logging
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Header, HTTPException, Query

from classes.postgres_db import PostgresDB
from middlewares.auth import resolve_bearer_to_user
from utils.instance_offline import (
    build_dataset_manifest_entries,
    build_offline_write_endpoints_manifest,
    build_schema_pack_for_instance,
    resolve_instance_by_ref,
    snapshot_url_for_dataset,
    user_can_access_instance,
)

logger = logging.getLogger("noolva_api.instances_offline_client")

_CLIENT_MENU_TYPES = frozenset({"web", "android", "ios", "macos", "linux"})

router = APIRouter(prefix="/instances", tags=["Client instances - Offline sync"])


async def _require_user(authorization: Optional[str] = Header(None)):
    user = await resolve_bearer_to_user(authorization)
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required (Bearer JWT or PAT)")
    return user


def _company_id_for_s3(user: dict) -> Optional[int]:
    cid = user.get("company_id")
    if cid is not None:
        try:
            return int(cid)
        except (TypeError, ValueError):
            return None
    return None


@router.get("/{instance_ref}/offline/manifest")
async def get_offline_manifest(
    instance_ref: str,
    authorization: Optional[str] = Header(None),
):
    user = await _require_user(authorization)
    inst = await resolve_instance_by_ref(instance_ref)
    if not inst or not inst.get("is_active", True):
        raise HTTPException(status_code=404, detail="Instance not found or inactive")
    if not user_can_access_instance(user, inst):
        raise HTTPException(status_code=403, detail="Not allowed to access this instance")
    await PostgresDB.execute(
        """
        INSERT INTO public.instance_offline_settings (instance_id)
        VALUES ($1)
        ON CONFLICT (instance_id) DO NOTHING
        """,
        int(inst["instance_id"]),
    )
    row = await PostgresDB.fetchrow(
        "SELECT * FROM public.instance_offline_settings WHERE instance_id = $1",
        int(inst["instance_id"]),
    )
    settings = dict(row) if row else {}
    s3_company_id = _company_id_for_s3(user)
    datasets, warnings = await build_dataset_manifest_entries(int(inst["instance_id"]), s3_company_id)
    writes = await build_offline_write_endpoints_manifest(int(inst["instance_id"]))
    return {
        "instance": {
            "instance_id": inst["instance_id"],
            "instance_uuid": str(inst["instance_uuid"]),
            "name": inst["name"],
            "company_id": inst.get("company_id"),
        },
        "offline": {
            "enable_offline_data": bool(settings.get("enable_offline_data")),
            "schema_pack_version": (settings.get("schema_pack_version") or "1"),
        },
        "datasets": datasets,
        "offline_write_endpoints": writes,
        "_warnings": warnings,
    }


@router.get("/{instance_ref}/offline/schema-pack")
async def get_schema_pack(
    instance_ref: str,
    authorization: Optional[str] = Header(None),
):
    user = await _require_user(authorization)
    inst = await resolve_instance_by_ref(instance_ref)
    if not inst or not inst.get("is_active", True):
        raise HTTPException(status_code=404, detail="Instance not found or inactive")
    if not user_can_access_instance(user, inst):
        raise HTTPException(status_code=403, detail="Not allowed to access this instance")
    row = await PostgresDB.fetchrow(
        "SELECT enable_offline_data, schema_pack_version FROM public.instance_offline_settings WHERE instance_id = $1",
        int(inst["instance_id"]),
    )
    if not row or not row.get("enable_offline_data"):
        raise HTTPException(status_code=403, detail="Offline data is not enabled for this instance")
    pack = await build_schema_pack_for_instance(int(inst["instance_id"]))
    pack["schema_pack_version"] = (row.get("schema_pack_version") or "1")
    pack["instance_uuid"] = str(inst["instance_uuid"])
    return pack


@router.get("/{instance_ref}/offline/snapshot-url")
async def get_snapshot_url(
    instance_ref: str,
    dataset_key: str = Query(..., description="Dataset key (source_kind flattened_s3)"),
    authorization: Optional[str] = Header(None),
):
    user = await _require_user(authorization)
    inst = await resolve_instance_by_ref(instance_ref)
    if not inst or not inst.get("is_active", True):
        raise HTTPException(status_code=404, detail="Instance not found or inactive")
    if not user_can_access_instance(user, inst):
        raise HTTPException(status_code=403, detail="Not allowed to access this instance")
    row = await PostgresDB.fetchrow(
        "SELECT enable_offline_data FROM public.instance_offline_settings WHERE instance_id = $1",
        int(inst["instance_id"]),
    )
    if not row or not row.get("enable_offline_data"):
        raise HTTPException(status_code=403, detail="Offline data is not enabled for this instance")
    pub, presigned, meta, err = await snapshot_url_for_dataset(
        int(inst["instance_id"]),
        dataset_key,
        _company_id_for_s3(user),
    )
    if err:
        raise HTTPException(status_code=400, detail=err)
    out = {
        "dataset_key": dataset_key.strip(),
        "public_url": pub,
        "presigned_url": presigned,
        "meta": meta,
    }
    return out


def _default_render_mode(client_type: str) -> str:
    return "web" if client_type == "web" else "native"


def _menus_list_to_tree(rows: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    by_id: Dict[int, Dict[str, Any]] = {}
    roots: List[Dict[str, Any]] = []
    for r in rows:
        item = {**r, "children": []}
        by_id[int(r["id"])] = item
    for r in rows:
        nid = int(r["id"])
        pid = r.get("parent_id")
        node = by_id[nid]
        if pid is None:
            roots.append(node)
        else:
            parent = by_id.get(int(pid))
            if parent:
                parent["children"].append(node)
            else:
                roots.append(node)
    for n in by_id.values():
        ch = n.get("children") or []
        ch.sort(key=lambda x: (x.get("sort_order") or 0, (x.get("menu_title") or "").lower()))
        n["children"] = ch
    roots.sort(key=lambda x: (x.get("sort_order") or 0, (x.get("menu_title") or "").lower()))
    return roots


@router.get("/{instance_ref}/menus")
async def get_instance_menus_for_client(
    instance_ref: str,
    client_type: str = Query(
        ...,
        description="Platform: web | android | ios | macos | linux",
    ),
    tree: bool = Query(False, description="If true, nest items with parent_id under children[]"),
    authorization: Optional[str] = Header(None),
):
    """
    Navigation items configured in Noolva console → Instance menus for this client instance.
    Respects per-stack rows in instance_menu_client_config; missing row = enabled with default render_mode.
    """
    ct = (client_type or "").strip().lower()
    if ct not in _CLIENT_MENU_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid client_type (expected one of: {', '.join(sorted(_CLIENT_MENU_TYPES))})",
        )
    user = await _require_user(authorization)
    inst = await resolve_instance_by_ref(instance_ref)
    if not inst or not inst.get("is_active", True):
        raise HTTPException(status_code=404, detail="Instance not found or inactive")
    if not user_can_access_instance(user, inst):
        raise HTTPException(status_code=403, detail="Not allowed to access this instance")
    iid = int(inst["instance_id"])
    default = _default_render_mode(ct)
    rows = await PostgresDB.fetch(
        """
        SELECT m.id,
               m.menu_title,
               m.route_path,
               m.icon_key,
               m.parent_id,
               m.sort_order,
               m.is_builtin,
               COALESCE(c.render_mode, $2::text) AS render_mode
        FROM public.instance_menus m
        LEFT JOIN public.instance_menu_client_config c
          ON c.instance_menu_id = m.id AND c.client_type = $3::text
        WHERE m.instance_id = $1
          AND COALESCE(c.is_enabled, TRUE) IS TRUE
        ORDER BY m.parent_id NULLS FIRST, m.sort_order, m.menu_title
        """,
        iid,
        default,
        ct,
    )
    flat: List[Dict[str, Any]] = []
    for r in rows or []:
        flat.append(
            {
                "id": r["id"],
                "menu_title": r["menu_title"],
                "route_path": r.get("route_path"),
                "icon_key": r.get("icon_key"),
                "parent_id": r.get("parent_id"),
                "sort_order": r.get("sort_order") or 0,
                "is_builtin": bool(r.get("is_builtin")),
                "render_mode": (r.get("render_mode") or default).strip().lower(),
                "client_type": ct,
            }
        )
    out: Dict[str, Any] = {
        "instance": {
            "instance_id": inst["instance_id"],
            "instance_uuid": str(inst["instance_uuid"]),
            "name": inst["name"],
        },
        "client_type": ct,
        "menus": _menus_list_to_tree(flat) if tree else flat,
    }
    return out
