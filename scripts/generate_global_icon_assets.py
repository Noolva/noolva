#!/usr/bin/env python3
"""Generate platform-specific global_icons under api/assets/global_icons/ and SQL upserts."""
from __future__ import annotations

import json
from pathlib import Path

from global_icon_generator_lib import (
    PRESET_PATHS,
    android_vector,
    build_meta,
    preset_for_key,
    sql_escape,
    sql_keywords_array,
    svg_ios,
    svg_linux,
    svg_macos,
    svg_web,
    windows_png,
)

REPO = Path(__file__).resolve().parents[1]
ASSETS_ROOT = REPO / "api" / "assets" / "global_icons"
MANIFEST_PATH = REPO / "api" / "assets" / "assets_manifest.json"
SEED_SQL_PATH = REPO / "db-structure" / "global_icons_seed_values.sql"
ASSETS_FEED_SQL_PATH = REPO / "db-structure" / "global_icons_assets_feed.sql"
V2_MIGRATION_PATH = REPO / "db-structure" / "update_old_db_global_icons_v2_descriptions_platform_assets.sql"
FEEDS_PATH = REPO / "db-structure" / "noolvandb_feeds.sql"

ICON_KEYS = [
    "home", "user", "users", "settings", "search", "menu", "close", "add", "edit", "delete",
    "save", "cancel", "check", "back", "forward", "refresh", "download", "upload", "share", "link",
    "copy", "filter", "sort", "calendar", "clock", "mail", "phone", "map", "location", "camera",
    "image", "file", "folder", "document", "print", "lock", "unlock", "key", "star", "heart",
    "bell", "flag", "bookmark", "tag", "cart", "shop", "credit_card", "dollar", "chart", "graph",
    "table", "list", "grid", "layout", "mobile", "tablet", "desktop", "wifi", "bluetooth", "battery",
    "volume", "play", "pause", "stop", "next_track", "previous_track", "info", "help", "warning",
    "error", "success", "question", "eye", "eye_off", "plus", "minus", "expand", "collapse", "more",
    "dots_vertical", "arrow_up", "arrow_down", "arrow_left", "arrow_right", "chevron_up", "chevron_down",
    "external_link", "attachment", "archive", "trash", "undo", "redo", "bold", "italic", "code",
    "globe", "cloud", "database", "server", "shield", "wrench", "tool", "sparkles", "robot", "chat",
    "message", "team", "building", "truck", "plane", "car", "coffee", "sun", "moon", "language",
    "log_in", "log_out", "profile", "notification", "dashboard", "activity", "layers", "compass",
    "target", "award", "gift", "megaphone", "puzzle", "brush", "crop", "adjust", "zoom_in", "zoom_out",
    "inbox", "send", "reply", "forward_mail", "folder_open", "note", "pin", "unpin", "history",
    "sync", "import_icon", "export_icon", "template", "workflow", "api", "webhook", "terminal",
]


def _strip_global_icon_manifest(manifest: dict) -> None:
    assets = manifest.get("assets", [])
    manifest["assets"] = [a for a in assets if not str(a.get("file_name", "")).startswith("global_icons/")]


def _patch_feeds_section() -> None:
    text = FEEDS_PATH.read_text(encoding="utf-8")
    start = text.find("-- ==========================================\n-- 2.2 Global icons")
    end = text.find("\n-- ==========================================\n-- 3. Settings")
    if start == -1 or end == -1:
        print("WARNING: could not find feeds 2.2 Global icons block; skip noolvandb_feeds.sql patch")
        return
    assets_body = ASSETS_FEED_SQL_PATH.read_text(encoding="utf-8")
    seed_body = SEED_SQL_PATH.read_text(encoding="utf-8")
    new_block = (
        "-- ==========================================\n"
        "-- 2.2 Global icons (bundled pack; platform paths under public/global_icons/{web,android,ios,macos,windows,linux}/)\n"
        "-- ==========================================\n"
        f"{assets_body}\n\n{seed_body}\n"
    )
    FEEDS_PATH.write_text(text[:start] + new_block + text[end:], encoding="utf-8")
    print(f"Patched {FEEDS_PATH}")


def main() -> None:
    for sub in ("web", "android", "ios", "macos", "windows", "linux"):
        (ASSETS_ROOT / sub).mkdir(parents=True, exist_ok=True)

    for legacy in ASSETS_ROOT.glob("*.svg"):
        if legacy.is_file():
            legacy.unlink()

    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    _strip_global_icon_manifest(manifest)

    sql_lines: list[str] = []
    asset_rows: list[str] = []
    new_manifest: list[dict] = []

    for key in ICON_KEYS:
        preset = preset_for_key(key)
        path_d = PRESET_PATHS[preset]
        desc, kw = build_meta(key)

        pw = f"public/global_icons/web/{key}.svg"
        pa = f"public/global_icons/android/{key}.xml"
        pi = f"public/global_icons/ios/{key}.svg"
        pm = f"public/global_icons/macos/{key}.svg"
        pwin = f"public/global_icons/windows/{key}.png"
        plin = f"public/global_icons/linux/{key}.svg"

        (ASSETS_ROOT / "web" / f"{key}.svg").write_text(
            svg_web(path_d, key, fill="#475569", bg="#f8fafc"), encoding="utf-8"
        )
        (ASSETS_ROOT / "android" / f"{key}.xml").write_text(android_vector(path_d), encoding="utf-8")
        (ASSETS_ROOT / "ios" / f"{key}.svg").write_text(svg_ios(path_d, key), encoding="utf-8")
        (ASSETS_ROOT / "macos" / f"{key}.svg").write_text(svg_macos(path_d, key), encoding="utf-8")
        (ASSETS_ROOT / "windows" / f"{key}.png").write_bytes(windows_png(preset))
        (ASSETS_ROOT / "linux" / f"{key}.svg").write_text(svg_linux(path_d, key), encoding="utf-8")

        desc_sql = sql_escape(desc)
        kw_sql = sql_keywords_array(kw)
        sql_lines.append(
            "    ("
            f"'{key}', '{pw}', '{pa}', '{pi}', '{pm}', '{pwin}', '{plin}', "
            f"'{desc_sql}', {kw_sql}"
            ")"
        )

        specs = [
            (f"global_icons/web/{key}.svg", f"{key}.svg", "image/svg+xml"),
            (f"global_icons/android/{key}.xml", f"{key}.xml", "application/xml"),
            (f"global_icons/ios/{key}.svg", f"{key}.svg", "image/svg+xml"),
            (f"global_icons/macos/{key}.svg", f"{key}.svg", "image/svg+xml"),
            (f"global_icons/windows/{key}.png", f"{key}.png", "image/png"),
            (f"global_icons/linux/{key}.svg", f"{key}.svg", "image/svg+xml"),
        ]
        for file_name, orig, mime in specs:
            asset_rows.append(
                f"        ('{orig}', '{orig}', '{mime}', '{file_name}', TRUE, NULL, v_system_user_id)"
            )
            new_manifest.append(
                {
                    "file_name": file_name,
                    "original_name": orig,
                    "mime_type": mime,
                    "is_public": True,
                    "description": f"Global icon ({file_name.split('/')[1]}): {key}",
                }
            )

    manifest.setdefault("assets", []).extend(new_manifest)
    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

    upsert_sql = (
        "-- Generated by scripts/generate_global_icon_assets.py (do not hand-edit)\n"
        "INSERT INTO public.global_icons (\n"
        "    icon_key, icon_path_web, icon_path_android, icon_path_ios, icon_path_macos,\n"
        "    icon_path_windows, icon_path_linux, description, keywords\n"
        ") VALUES\n"
        + ",\n".join(sql_lines)
        + "\nON CONFLICT (icon_key) DO UPDATE SET\n"
        "    icon_path_web = EXCLUDED.icon_path_web,\n"
        "    icon_path_android = EXCLUDED.icon_path_android,\n"
        "    icon_path_ios = EXCLUDED.icon_path_ios,\n"
        "    icon_path_macos = EXCLUDED.icon_path_macos,\n"
        "    icon_path_windows = EXCLUDED.icon_path_windows,\n"
        "    icon_path_linux = EXCLUDED.icon_path_linux,\n"
        "    description = EXCLUDED.description,\n"
        "    keywords = EXCLUDED.keywords;\n"
    )
    SEED_SQL_PATH.write_text(upsert_sql, encoding="utf-8")

    assets_vals = ",\n".join(asset_rows)
    ASSETS_FEED_SQL_PATH.write_text(
        "-- Generated by scripts/generate_global_icon_assets.py (do not hand-edit)\n"
        "DO $$\n"
        "DECLARE\n"
        "    v_system_user_id INTEGER;\n"
        "BEGIN\n"
        "    SELECT user_id INTO v_system_user_id FROM public.users WHERE is_super_admin = TRUE LIMIT 1;\n"
        "    INSERT INTO public.assets (file_name, original_name, mime_type, storage_path, is_public, company_id, uploaded_by)\n"
        "    SELECT * FROM (VALUES\n"
        f"{assets_vals}\n"
        "    ) AS t(file_name, original_name, mime_type, storage_path, is_public, company_id, uploaded_by)\n"
        "    WHERE NOT EXISTS (\n"
        "        SELECT 1 FROM public.assets a WHERE a.storage_path = t.storage_path AND a.company_id IS NULL\n"
        "    );\n"
        "END $$;\n",
        encoding="utf-8",
    )

    v2_sql = (
        "-- Add description, keywords, Windows/Linux paths and refresh catalog (run after global_icons table exists).\n"
        "-- Regenerate body via: python3 scripts/generate_global_icon_assets.py\n\n"
        "ALTER TABLE public.global_icons ADD COLUMN IF NOT EXISTS description TEXT;\n"
        "ALTER TABLE public.global_icons ADD COLUMN IF NOT EXISTS keywords TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[];\n"
        "ALTER TABLE public.global_icons ADD COLUMN IF NOT EXISTS icon_path_windows TEXT;\n"
        "ALTER TABLE public.global_icons ADD COLUMN IF NOT EXISTS icon_path_linux TEXT;\n\n"
        "CREATE INDEX IF NOT EXISTS idx_global_icons_keywords ON public.global_icons USING GIN (keywords);\n\n"
        + upsert_sql
    )
    V2_MIGRATION_PATH.write_text(v2_sql, encoding="utf-8")

    _patch_feeds_section()

    print(f"Wrote assets under {ASSETS_ROOT} ({len(ICON_KEYS)} keys × 6 files)")
    print(f"Manifest entries added: {len(new_manifest)}")
    print(f"Wrote {SEED_SQL_PATH}")
    print(f"Wrote {ASSETS_FEED_SQL_PATH}")
    print(f"Wrote {V2_MIGRATION_PATH}")


if __name__ == "__main__":
    main()
