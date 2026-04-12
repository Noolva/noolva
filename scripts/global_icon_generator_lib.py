"""Shared presets, metadata, and asset builders for generate_global_icon_assets.py."""
from __future__ import annotations

import io
import re
from typing import List, Sequence, Tuple

from PIL import Image, ImageDraw

# Logical key -> Material-style pathData (24x24 viewport). Used for web SVG + Android vector drawable.
PRESET_PATHS: dict[str, str] = {
    "home": "M10,20V10h4v10h5v-8h3L12,3L2,12h3v8z",
    "user": "M12,12c2.2,0,4-1.8,4-4s-1.8-4-4-4s-4,1.8-4,4s1.8,4,4,4zm0,2c-2.7,0-8,1.3-8,4v2h16v-2C20,15.3,14.7,14,12,14z",
    "users": "M16,11c1.7,0,3-1.3,3-3s-1.3-3-3-3s-3,1.3-3,3s1.3,3,3,3zm-8,0c1.7,0,3-1.3,3-3s-1.3-3-3-3s-3,1.3-3,3s1.3,3,3,3zm0,2c-2.3,0-7,1.2-7,3.5V19h14v-2.5C19,14.2,14.3,13,12,13zm8,0h-1.2c1.2,0.9,1.9,2,1.9,3.5V19h6v-2.5C26.9,15.3,22.5,13,20,13z",
    "settings": "M19.1,12.8l-1.1-0.9c0.1-0.4,0.1-0.7,0.1-1.1s0-0.7-0.1-1.1l1.1-0.9c0.3-0.3,0.4-0.7,0.2-1l-1-1.7c-0.2-0.4-0.6-0.5-1-0.4l-1.4,0.6c-0.6-0.5-1.3-0.9-2-1.1L12.7,4h-1.4l-0.2,1.5c-0.8,0.2-1.5,0.6-2,1.1L7.7,6.1c-0.4-0.1-0.8,0-1,0.4l-1,1.7c-0.2,0.4-0.1,0.8,0.2,1l1.1,0.9C6.9,10.1,6.9,10.4,6.9,10.8s0,0.7,0.1,1.1l-1.1,0.9c-0.3,0.3-0.4,0.7-0.2,1l1,1.7c0.2,0.4,0.6,0.5,1,0.4l1.4-0.6c0.6,0.5,1.3,0.9,2,1.1l0.2,1.5h1.4l0.2-1.5c0.8-0.2,1.5-0.6,2-1.1l1.4,0.6c0.4,0.1,0.8,0,1-0.4l1-1.7c0.2-0.4,0.1-0.8-0.2-1zM12,15.5c-2.5,0-4.5-2-4.5-4.5s2-4.5,4.5-4.5s4.5,2,4.5,4.5S14.5,15.5,12,15.5z",
    "search": "M15.5,14h-0.8l-0.3-0.3c1-1.1,1.6-2.6,1.6-4.2C16,5.9,13.1,3,9.5,3S3,5.9,3,9.5S5.9,16,9.5,16c1.6,0,3.1-0.6,4.2-1.6l0.3,0.3v0.8l5,5l1.5-1.5L15.5,14zM9.5,14C7,14,5,12,5,9.5S7,5,9.5,5S14,7,14,9.5S12,14,9.5,14z",
    "menu": "M3,18h18v-2H3V18zM3,13h18v-2H3V13zM3,6v2h18V6H3z",
    "close": "M19,6.4L17.6,5L12,10.6L6.4,5L5,6.4L10.6,12L5,17.6L6.4,19L12,13.4L17.6,19L19,17.6L13.4,12z",
    "add": "M19,13h-6v6h-2v-6H5v-2h6V5h2v6h6V13z",
    "edit": "M3,17.2V21h3.8L17.8,9.9l-3.8-3.8L3,17.2zM20.7,7c0.4-0.4,0.4-1,0-1.4l-2.3-2.3c-0.4-0.4-1-0.4-1.4,0l-1.8,1.8l3.8,3.8L20.7,7z",
    "delete": "M6,19c0,1.1,0.9,2,2,2h8c1.1,0,2-0.9,2-2V7H6V19zM19,4h-3.5l-1-1h-5l-1,1H5v2h14V4z",
    "check": "M9,16.2L4.8,12l-1.4,1.4L9,19L21,7l-1.4-1.4L9,16.2z",
    "arrow_left": "M15.4,7.4L14,6l-6,6l6,6l1.4-1.4L10.8,12L15.4,7.4z",
    "arrow_right": "M8.6,7.4L10,6l6,6l-6,6L8.6,16.6L13.2,12L8.6,7.4z",
    "arrow_up": "M7.4,15.4L6,14l6-6l6,6l-1.4,1.4L12,10.8L7.4,15.4z",
    "arrow_down": "M7.4,8.6L6,10l6,6l6-6l-1.4-1.4L12,13.2L7.4,8.6z",
    "chevron_down": "M7.4,8.6L6,10l6,6l6-6l-1.4-1.4L12,13.2L7.4,8.6z",
    "chevron_up": "M7.4,15.4L6,14l6-6l6,6l-1.4,1.4L12,10.8L7.4,15.4z",
    "mail": "M20,4H4C2.9,4,2,4.9,2,6v12c0,1.1,0.9,2,2,2h16c1.1,0,2-0.9,2-2V6C22,4.9,21.1,4,20,4zM20,8l-8,5L4,8V6l8,5l8-5V8z",
    "calendar": "M19,4h-1V2h-2v2H8V2H6v2H5C3.9,4,3,4.9,3,6v14c0,1.1,0.9,2,2,2h14c1.1,0,2-0.9,2-2V6C21,4.9,20.1,4,19,4zM19,20H5V10h14V20z",
    "clock": "M12,2C6.5,2,2,6.5,2,12s4.5,10,10,10s10-4.5,10-10S17.5,2,12,2zM12,20c-4.4,0-8-3.6-8-8s3.6-8,8-8s8,3.6,8,8S16.4,20,12,20zM12.5,7H11v6l5.2,3.1l0.8-1.3l-4.5-2.7V7z",
    "lock": "M18,8h-1V6c0-2.8-2.2-5-5-5S7,3.2,7,6v2H6c-1.1,0-2,0.9-2,2v10c0,1.1,0.9,2,2,2h12c1.1,0,2-0.9,2-2V10C20,8.9,19.1,8,18,8zM9,6c0-1.7,1.3-3,3-3s3,1.3,3,3v2H9V6z",
    "unlock": "M12,17c1.1,0,2-0.9,2-2s-0.9-2-2-2s-2,0.9-2,2S10.9,17,12,17zM18,8h-1V6c0-2.8-1.7-5-5-5S6,3.2,6,6h2c0-1.7,1.3-3,3-3s3,1.3,3,3v2H6c-1.1,0-2,0.9-2,2v10c0,1.1,0.9,2,2,2h12c1.1,0,2-0.9,2-2V10C20,8.9,19.1,8,18,8z",
    "star": "M12,17.3l6.2,3.7l-1.6-7L22,9.2l-7.2-0.6L12,2L9.2,8.6L2,9.2l5.4,4.8l-1.6,7L12,17.3z",
    "heart": "M12,21.4l-1.1-1C6.1,15.4,3,12.4,3,8.5C3,5.4,5.4,3,8.5,3c1.7,0,3.4,0.8,4.5,2.1C14.1,3.8,15.8,3,17.5,3C20.6,3,23,5.4,23,8.5c0,3.9-3.1,6.9-7.9,11.7L12,21.4z",
    "bell": "M12,22c1.1,0,2-0.9,2-2h-4C10,21.1,10.9,22,12,22zM18,16v-5c0-3.1-2.1-5.7-5-6.3V4c0-0.6-0.4-1-1-1s-1,0.4-1,1v0.7C8.1,5.3,6,7.9,6,11v5l-2,2v1h16v-1L18,16z",
    "folder": "M10,4H4C2.9,4,2,4.9,2,6v12c0,1.1,0.9,2,2,2h16c1.1,0,2-0.9,2-2V8c0-1.1-0.9-2-2-2h-8L10,4z",
    "file": "M14,2H6C4.9,2,4,2.9,4,4v16c0,1.1,0.9,2,2,2h12c1.1,0,2-0.9,2-2V8L14,2zM16,18H8v-2h8V18zM16,14H8v-2h8V14zM13,9V3.5L18.5,9H13z",
    "image": "M21,19V5c0-1.1-0.9-2-2-2H5C3.9,3,3,3.9,3,5v14c0,1.1,0.9,2,2,2h14C20.1,21,21,20.1,21,19zM8.5,13.5l2.5,3l3.5-4.5l4.5,6H5L8.5,13.5z",
    "cloud": "M19.4,10c-0.7-3.4-3.7-6-7.4-6C9.1,4,6.6,5.3,5.1,7.3C3.6,7.6,2,9.1,2,11c0,2.2,1.8,4,4,4h12.5c1.9,0,3.5-1.6,3.5-3.5C22,11.8,20.8,10.4,19.4,10z",
    "database": "M12,3C7.6,3,4,4.2,4,5.8V18.2C4,19.8,7.6,21,12,21s8-1.2,8-2.8V5.8C20,4.2,16.4,3,12,3zM18,15.5c0,0.4-1.8,1.5-6,1.5s-6-1.1-6-1.5v-2.1c1.4,0.7,3.6,1.1,6,1.1s4.6-0.4,6-1.1V15.5zM18,10.8c0,0.4-1.8,1.5-6,1.5S6,11.2,6,10.8V8.7C7.4,9.4,9.6,9.8,12,9.8s4.6-0.4,6-1.1V10.8zM12,8.3c-4.2,0-6-1.1-6-1.5S7.8,5.3,12,5.3s6,1.1,6,1.5S16.2,8.3,12,8.3z",
    "play": "M8,5v14l11-7L8,5z",
    "pause": "M6,19h4V5H6V19zM14,5v14h4V5H14z",
    "stop": "M6,6h12v12H6V6z",
    "info": "M12,2C6.5,2,2,6.5,2,12s4.5,10,10,10s10-4.5,10-10S17.5,2,12,2zM13,17h-2v-6h2V17zM13,9h-2V7h2V9z",
    "warning": "M1,21h22L12,2L1,21zM13,18h-2v-2h2V18zM13,14h-2v-4h2V14z",
    "circle": "M12,2C6.5,2,2,6.5,2,12s4.5,10,10,10s10-4.5,10-10S17.5,2,12,2z",
    "plus": "M19,13h-6v6h-2v-6H5v-2h6V5h2v6h6V13z",
    "minus": "M19,13H5v-2h14V13z",
    "link": "M3.9,12C3.9,10.3,5.3,8.9,7,8.9h4V7H7C4.2,7,2,9.2,2,12s2.2,5,5,5h4v-1.9H7C5.3,16.1,3.9,14.7,3.9,12zM8,13h8v-2H8V13zM17,7h-4v1.9h4c1.7,0,3.1,1.4,3.1,3.1s-1.4,3.1-3.1,3.1h-4V17h4c2.8,0,5-2.2,5-5S19.8,7,17,7z",
    "refresh": "M17.6,6.4C16.2,4.9,14.2,4,12,4c-4.4,0-8,3.6-8,8s3.6,8,8,8c3.7,0,6.8-2.5,7.7-6h-2.1c-0.8,2.3-3,4-5.6,4c-3.3,0-6-2.7-6-6s2.7-6,6-6c1.7,0,3.1,0.7,4.2,1.8L13,11h7V4L17.6,6.4z",
    "download": "M19,9h-4V3H9v6H5l7,7L19,9zM5,18v2h14v-2H5z",
    "upload": "M9,16h6v-6h4l-7-7l-7,7h4V16zM5,18v2h14v-2H5z",
    "share": "M18,16.1c-0.8,0-1.5,0.3-2,0.8l-7-4.1C9.1,12.4,9,12.2,9,12s0.1-0.4,0.1-0.6l7-4.1c0.5,0.5,1.2,0.8,2,0.8c1.7,0,3-1.3,3-3s-1.3-3-3-3s-3,1.3-3,3c0,0.2,0.1,0.4,0.1,0.6l-7,4.1C7.5,9.8,6.8,9.5,6,9.5c-1.7,0-3,1.3-3,3s1.3,3,3,3c0.8,0,1.5-0.3,2-0.8l7,4.1c0,0.2-0.1,0.4-0.1,0.6c0,1.7,1.3,3,3,3s3-1.3,3-3S19.7,16.1,18,16.1z",
    "grid": "M4,8h4V4H4V8zM10,20h4v-4h-4V20zM4,20h4v-4H4V20zM4,14h4v-4H4V14zM10,14h4v-4h-4V14zM16,4v4h4V4H16zM10,8h4V4h-4V8zM16,14h4v-4h-4V14zM16,20h4v-4h-4V20z",
    "list": "M3,14h2v-2H3V14zM3,19h2v-2H3V19zM3,9h2V7H3V9zM7,14h14v-2H7V14zM7,19h14v-2H7V19zM7,7v2h14V7H7z",
    "phone": "M6.6,10.8c1.4,2.8,3.8,5.1,6.6,6.6l2.2-2.2c0.3-0.3,0.7-0.4,1-0.2c1.1,0.4,2.3,0.6,3.6,0.6c0.6,0,1,0.4,1,1V20c0,0.6-0.4,1-1,1C10.6,21,3,13.4,3,3.9C3,3.4,3.4,3,4,3h3.5c0.6,0,1,0.4,1,1c0,1.3,0.2,2.5,0.6,3.6c0.1,0.3,0,0.7-0.2,1L6.6,10.8z",
    "map": "M20.5,3l-0.2,0.1L15,5.1L9,3L3.4,4.9C3.2,5,3,5.1,3,5.4v15.1l0.2,0.1L9,18.9l6,2.1l5.6-1.9c0.2-0.1,0.4-0.3,0.4-0.5V3.5C21,3.2,20.8,3,20.5,3zM15,19l-6-2.1V5l6,2.1V19z",
    "camera": "M12,15.2c1.8,0,3.2-1.4,3.2-3.2S13.8,8.8,12,8.8S8.8,10.2,8.8,12S10.2,15.2,12,15.2zM9,2L7.2,4H4C2.9,4,2,4.9,2,6v12c0,1.1,0.9,2,2,2h16c1.1,0,2-0.9,2-2V6c0-1.1-0.9-2-2-2h-3.2L15,2H9z",
    "cart": "M7,18c-1.1,0-2,0.9-2,2s0.9,2,2,2s2-0.9,2-2S8.1,18,7,18zM1,2v2h2l3.6,7.6L5.2,14C5.1,14.3,5,14.6,5,15c0,1.1,0.9,2,2,2h12v-2H7.4c-0.1,0-0.2-0.1-0.2-0.2L7.4,14H17c0.8,0,1.5-0.4,1.9-1l3.6-6.5C22.9,6.3,23,6.2,23,6V4H5.2L4.3,2H1zM17,18c-1.1,0-2,0.9-2,2s0.9,2,2,2s2-0.9,2-2S18.1,18,17,18z",
    "credit_card": "M20,4H4C2.9,4,2,4.9,2,6v12c0,1.1,0.9,2,2,2h16c1.1,0,2-0.9,2-2V6C22,4.9,21.1,4,20,4zM20,18H4v-6h16V18zM20,8H4V6h16V8z",
    "wifi": "M12,18c1.1,0,2,0.9,2,2h-4C10,18.9,10.9,18,12,18zM8.6,14.6l1.4,1.4c1.2-1.2,3.1-1.2,4.2,0l1.4-1.4C13.3,12.3,10.7,12.3,8.6,14.6zM5.4,11.4L6.8,12.8c2.5-2.5,6.5-2.5,9,0l1.4-1.4C12.3,8.5,7.7,8.5,5.4,11.4zM2.1,8.2L3.5,9.6c3.8-3.8,9.9-3.8,13.7,0l1.4-1.4C13.1,3.8,6.9,3.8,2.1,8.2z",
    "bolt": "M11,21h-1l1-7H7.5c-0.6,0-0.4-0.3-0.4-0.4L12,2l1,1l-1,7h3.5c0.4,0,0.5,0.3,0.3,0.6L11,21z",
    "chart": "M11,21h-1l1-7H7.5c-0.6,0-0.4-0.3-0.4-0.4L12,2l1,1l-1,7h3.5c0.4,0,0.5,0.3,0.3,0.6L11,21z",
    "chat": "M20,2H4C2.9,2,2,2.9,2,4v18l4-4h14c1.1,0,2-0.9,2-2V4C22,2.9,21.1,2,20,2z",
    "terminal": "M20,4H4C2.9,4,2,4.9,2,6v12c0,1.1,0.9,2,2,2h16c1.1,0,2-0.9,2-2V6C22,4.9,21.1,4,20,4zM6,16l2.5-2.5L6,11l1.4-1.4L10.9,14L7.4,17.4L6,16zM16,17H11v-2h5V17z",
}

# Longest match wins: (substring, preset)
_PRESET_RULES: List[Tuple[str, str]] = sorted(
    [
        ("forward_mail", "mail"),
        ("next_track", "arrow_right"),
        ("back", "arrow_left"),
        ("previous_track", "arrow_left"),
        ("eye_off", "close"),
        ("credit_card", "credit_card"),
        ("dots_vertical", "menu"),
        ("external_link", "link"),
        ("import_icon", "download"),
        ("export_icon", "upload"),
        ("folder_open", "folder"),
        ("log_in", "arrow_right"),
        ("log_out", "arrow_left"),
        ("zoom_in", "search"),
        ("zoom_out", "search"),
        ("forward", "arrow_right"),
        ("backward", "arrow_left"),
        ("reply", "arrow_left"),
        ("send", "arrow_right"),
        ("inbox", "mail"),
        ("history", "refresh"),
        ("sync", "refresh"),
        ("undo", "arrow_left"),
        ("redo", "arrow_right"),
        ("template", "file"),
        ("workflow", "list"),
        ("webhook", "link"),
        ("api", "terminal"),
        ("building", "home"),
        ("megaphone", "bell"),
        ("notification", "bell"),
        ("dashboard", "grid"),
        ("activity", "bolt"),
        ("compass", "circle"),
        ("target", "circle"),
        ("award", "star"),
        ("gift", "heart"),
        ("puzzle", "grid"),
        ("brush", "edit"),
        ("crop", "image"),
        ("adjust", "settings"),
        ("layers", "grid"),
        ("layout", "grid"),
        ("graph", "chart"),
        ("chart", "bolt"),
        ("dollar", "credit_card"),
        ("shop", "cart"),
        ("bookmark", "star"),
        ("flag", "warning"),
        ("tag", "circle"),
        ("key", "lock"),
        ("unlock", "unlock"),
        ("print", "file"),
        ("document", "file"),
        ("note", "file"),
        ("pin", "star"),
        ("unpin", "close"),
        ("team", "users"),
        ("profile", "user"),
        ("message", "chat"),
        ("robot", "terminal"),
        ("sparkles", "star"),
        ("shield", "lock"),
        ("server", "database"),
        ("globe", "cloud"),
        ("code", "terminal"),
        ("italic", "edit"),
        ("bold", "edit"),
        ("archive", "folder"),
        ("attachment", "link"),
        ("trash", "delete"),
        ("expand", "arrow_down"),
        ("collapse", "arrow_up"),
        ("more", "menu"),
        ("question", "info"),
        ("error", "warning"),
        ("success", "check"),
        ("help", "info"),
        ("volume", "bell"),
        ("battery", "bolt"),
        ("bluetooth", "wifi"),
        ("tablet", "phone"),
        ("table", "grid"),
        ("mobile", "phone"),
        ("desktop", "grid"),
        ("sort", "list"),
        ("filter", "search"),
        ("copy", "file"),
        ("save", "check"),
        ("cancel", "close"),
        ("edit", "edit"),
        ("delete", "delete"),
        ("add", "plus"),
        ("close", "close"),
        ("menu", "menu"),
        ("search", "search"),
        ("settings", "settings"),
        ("users", "users"),
        ("user", "user"),
        ("home", "home"),
        ("mail", "mail"),
        ("phone", "phone"),
        ("map", "map"),
        ("location", "map"),
        ("camera", "camera"),
        ("image", "image"),
        ("file", "file"),
        ("folder", "folder"),
        ("calendar", "calendar"),
        ("clock", "clock"),
        ("lock", "lock"),
        ("star", "star"),
        ("heart", "heart"),
        ("bell", "bell"),
        ("cart", "cart"),
        ("play", "play"),
        ("pause", "pause"),
        ("stop", "stop"),
        ("info", "info"),
        ("warning", "warning"),
        ("check", "check"),
        ("plus", "plus"),
        ("minus", "minus"),
        ("link", "link"),
        ("refresh", "refresh"),
        ("download", "download"),
        ("upload", "upload"),
        ("share", "share"),
        ("grid", "grid"),
        ("list", "list"),
        ("wifi", "wifi"),
        ("cloud", "cloud"),
        ("database", "database"),
        ("chat", "chat"),
        ("terminal", "terminal"),
        ("arrow_up", "arrow_up"),
        ("arrow_down", "arrow_down"),
        ("arrow_left", "arrow_left"),
        ("arrow_right", "arrow_right"),
        ("chevron_up", "chevron_up"),
        ("chevron_down", "chevron_down"),
        ("plane", "map"),
        ("truck", "map"),
        ("car", "map"),
        ("coffee", "circle"),
        ("sun", "circle"),
        ("moon", "circle"),
        ("language", "cloud"),
    ],
    key=lambda x: -len(x[0]),
)


def preset_for_key(key: str) -> str:
    k = key.lower()
    for needle, preset in _PRESET_RULES:
        if needle in k:
            if preset in PRESET_PATHS:
                return preset
    return "circle"


def build_meta(key: str) -> Tuple[str, List[str]]:
    label = key.replace("_", " ").strip().title()
    preset = preset_for_key(key)
    desc = (
        f"{label} — global catalog glyph for Noolva apps (web, Android vector drawable, iOS/macOS SVG, "
        f"Windows PNG tile, Linux SVG). Semantic preset: {preset}."
    )
    words = re.split(r"[_\s]+", key.lower())
    kw = sorted(
        set(
            words
            + [key, key.replace("_", " "), label.lower(), "icon", "ui", "global", "noolva", preset]
        )
    )
    return desc, kw


def svg_web(path_d: str, key: str, fill: str, bg: str) -> str:
    esc = (
        key.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
    )
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" role="img" aria-label="{esc}">
  <rect width="24" height="24" rx="3" fill="{bg}"/>
  <path fill="{fill}" d="{path_d}"/>
</svg>
"""


def svg_ios(path_d: str, key: str) -> str:
    """SF-friendly: currentColor for template images."""
    esc = (
        key.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
    )
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" role="img" aria-label="{esc}">
  <path fill="currentColor" d="{path_d}"/>
</svg>
"""


def svg_macos(path_d: str, key: str) -> str:
    esc = (
        key.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
    )
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" role="img" aria-label="{esc}">
  <path fill="#1D1D1F" d="{path_d}"/>
</svg>
"""


def svg_linux(path_d: str, key: str) -> str:
    return svg_web(path_d, key, fill="#2E3440", bg="#ECEFF4")


def android_vector(path_d: str) -> str:
    return f"""<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24"
    android:tint="?attr/colorControlNormal">
    <path
        android:fillColor="#FF475569"
        android:pathData="{path_d}" />
</vector>
"""


def windows_png(preset: str) -> bytes:
    """32×32 PNG tile for WinUI / taskbar-style lists (filled silhouette per preset family)."""
    w, h = 32, 32
    im = Image.new("RGBA", (w, h), (248, 250, 252, 255))
    d = ImageDraw.Draw(im)
    fg = (71, 85, 105, 255)
    d.rounded_rectangle([2, 2, w - 3, h - 3], radius=5, outline=fg, width=2)
    cx, cy = 16, 16

    def circ(r):
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=fg)

    if preset in ("user", "users", "profile"):
        d.ellipse([cx - 5, cy - 10, cx + 5, cy - 2], fill=fg)
        d.pieslice([cx - 11, cy - 2, cx + 11, cy + 14], start=0, end=180, fill=fg)
    elif preset == "home":
        d.polygon([(16, 5), (6, 14), (26, 14)], fill=fg)
        d.rectangle([11, 14, 21, 27], fill=fg)
    elif preset in ("settings",):
        d.ellipse([cx - 8, cy - 8, cx + 8, cy + 8], outline=fg, width=2)
        circ(3)
    elif preset in ("search", "zoom_in", "zoom_out", "filter"):
        d.ellipse([6, 7, 20, 21], outline=fg, width=2)
        d.line([(19, 19), (27, 27)], fill=fg, width=3)
    elif preset in ("menu", "dots_vertical", "more"):
        d.ellipse([cx - 2, 6, cx + 2, 10], fill=fg)
        d.ellipse([cx - 2, 14, cx + 2, 18], fill=fg)
        d.ellipse([cx - 2, 22, cx + 2, 26], fill=fg)
    elif preset == "close":
        d.line([(9, 9), (23, 23)], fill=fg, width=2)
        d.line([(23, 9), (9, 23)], fill=fg, width=2)
    elif preset in ("add", "plus"):
        d.line([(8, 16), (24, 16)], fill=fg, width=2)
        d.line([(16, 8), (16, 24)], fill=fg, width=2)
    elif preset == "minus":
        d.line([(8, 16), (24, 16)], fill=fg, width=2)
    elif preset == "check":
        d.line([(8, 16), (13, 22)], fill=fg, width=2)
        d.line([(13, 22), (26, 9)], fill=fg, width=2)
    elif preset in ("arrow_left", "chevron_up", "previous_track", "undo", "reply"):
        d.polygon([(22, 8), (10, 16), (22, 24)], fill=fg)
    elif preset in ("arrow_right", "chevron_down", "next_track", "redo", "send", "log_in"):
        d.polygon([(10, 8), (22, 16), (10, 24)], fill=fg)
    elif preset in ("arrow_up",):
        d.polygon([(8, 22), (16, 10), (24, 22)], fill=fg)
    elif preset in ("arrow_down", "expand"):
        d.polygon([(8, 10), (16, 22), (24, 10)], fill=fg)
    elif preset in ("mail", "inbox"):
        d.rectangle([6, 10, 26, 24], outline=fg, width=2)
        d.line([(6, 10), (16, 18), (26, 10)], fill=fg, width=2)
    elif preset in ("lock", "shield"):
        d.rectangle([10, 14, 22, 26], fill=fg)
        d.arc([8, 6, 24, 18], start=0, end=180, fill=fg, width=2)
    elif preset == "unlock":
        d.rectangle([10, 14, 22, 26], fill=fg)
        d.arc([12, 6, 24, 16], start=0, end=120, fill=fg, width=2)
    elif preset in ("star", "award", "pin"):
        d.polygon([(16, 5), (19, 13), (27, 13), (21, 18), (23, 26), (16, 21), (9, 26), (11, 18), (5, 13), (13, 13)], fill=fg)
    elif preset == "heart":
        d.pieslice([6, 8, 16, 20], start=0, end=180, fill=fg)
        d.pieslice([16, 8, 26, 20], start=0, end=180, fill=fg)
        d.polygon([(6, 14), (16, 26), (26, 14)], fill=fg)
    elif preset in ("bell", "volume", "notification", "megaphone"):
        d.pieslice([10, 6, 22, 18], start=0, end=180, fill=fg)
        d.rectangle([13, 14, 19, 24], fill=fg)
    elif preset in ("folder", "archive", "folder_open"):
        d.polygon([(10, 8), (14, 8), (16, 10), (26, 10), (26, 26), (8, 26), (8, 10)], fill=fg)
    elif preset in ("file", "document", "note", "template"):
        d.polygon([(10, 6), (20, 6), (24, 10), (24, 26), (8, 26), (8, 10)], fill=fg)
    elif preset == "image":
        d.rectangle([6, 8, 26, 26], outline=fg, width=2)
        d.ellipse([10, 12, 18, 18], fill=fg)
    elif preset in ("play",):
        d.polygon([(10, 7), (10, 25), (24, 16)], fill=fg)
    elif preset in ("pause",):
        d.rectangle([9, 7, 13, 25], fill=fg)
        d.rectangle([19, 7, 23, 25], fill=fg)
    elif preset in ("stop",):
        d.rectangle([8, 8, 24, 24], fill=fg)
    elif preset in ("info", "question", "help"):
        circ(10)
        d.rectangle([13, 10, 19, 20], fill=(248, 250, 252, 255))
        d.line([(16, 14), (16, 18)], fill=fg, width=2)
        d.ellipse([14, 20, 18, 24], fill=fg)
    elif preset == "warning":
        d.polygon([(16, 6), (27, 26), (5, 26)], fill=fg)
    elif preset in ("calendar",):
        d.rectangle([7, 9, 25, 25], outline=fg, width=2)
        d.line([(7, 13), (25, 13)], fill=fg, width=2)
        d.rectangle([10, 5, 14, 11], fill=fg)
        d.rectangle([18, 5, 22, 11], fill=fg)
    elif preset == "clock":
        circ(9)
        d.line([(16, 16), (16, 10)], fill=(248, 250, 252, 255), width=2)
        d.line([(16, 16), (21, 19)], fill=(248, 250, 252, 255), width=2)
    elif preset in ("cart", "shop", "credit_card", "dollar"):
        d.rectangle([6, 10, 26, 22], outline=fg, width=2)
        d.line([(6, 12), (26, 12)], fill=fg, width=2)
    elif preset in ("phone", "mobile", "tablet"):
        d.rounded_rectangle([11, 6, 21, 26], radius=2, outline=fg, width=2)
    elif preset in ("map", "plane", "truck", "car"):
        d.polygon([(6, 22), (10, 12), (16, 8), (22, 12), (26, 22)], fill=fg)
    elif preset == "camera":
        d.rounded_rectangle([6, 10, 26, 22], radius=2, outline=fg, width=2)
        circ(4)
    elif preset in ("wifi", "bluetooth"):
        d.arc([4, 10, 28, 28], start=200, end=340, fill=fg, width=2)
        d.arc([8, 12, 24, 24], start=200, end=340, fill=fg, width=2)
    elif preset == "battery":
        d.rectangle([7, 10, 24, 22], outline=fg, width=2)
        d.rectangle([25, 14, 27, 18], fill=fg)
        d.rectangle([9, 12, 18, 20], fill=fg)
    elif preset in ("cloud", "database", "server"):
        d.ellipse([6, 14, 14, 22], fill=fg)
        d.ellipse([10, 10, 22, 20], fill=fg)
        d.ellipse([18, 14, 26, 22], fill=fg)
    elif preset in ("chat", "message"):
        d.rounded_rectangle([4, 8, 28, 22], radius=3, fill=fg)
        d.polygon([(10, 22), (14, 18), (8, 18)], fill=fg)
    elif preset == "terminal":
        d.rectangle([5, 7, 27, 25], outline=fg, width=2)
        d.line([(8, 12), (12, 16)], fill=fg, width=2)
        d.line([(8, 18), (20, 18)], fill=fg, width=2)
    elif preset in ("link", "share", "external_link", "webhook", "attachment"):
        d.arc([6, 6, 18, 18], start=45, end=270, fill=fg, width=2)
        d.arc([14, 14, 26, 26], start=225, end=450, fill=fg, width=2)
    elif preset in ("grid", "dashboard", "layout", "layers", "puzzle"):
        for i in range(3):
            for j in range(3):
                x, y = 7 + i * 6, 7 + j * 6
                d.rectangle([x, y, x + 4, y + 4], fill=fg)
    elif preset in ("list", "workflow"):
        for i in range(4):
            y = 8 + i * 4
            d.rectangle([8, y, 12, y + 2], fill=fg)
            d.rectangle([14, y, 24, y + 2], fill=fg)
    elif preset in ("refresh", "sync", "history"):
        d.arc([6, 6, 26, 26], start=45, end=270, fill=fg, width=2)
        d.polygon([(22, 8), (26, 4), (26, 12)], fill=fg)
    elif preset in ("download", "import_icon"):
        d.line([(16, 6), (16, 20)], fill=fg, width=2)
        d.polygon([(10, 14), (16, 22), (22, 14)], fill=fg)
    elif preset in ("upload", "export_icon"):
        d.line([(16, 10), (16, 24)], fill=fg, width=2)
        d.polygon([(10, 16), (16, 8), (22, 16)], fill=fg)
    elif preset in ("trash", "delete"):
        d.rectangle([10, 10, 22, 24], outline=fg, width=2)
        d.line([(8, 10), (24, 10)], fill=fg, width=2)
        d.line([(12, 6), (20, 6)], fill=fg, width=2)
    elif preset in ("edit", "brush", "crop", "bold", "italic", "code"):
        d.polygon([(22, 4), (26, 8), (11, 24), (7, 24), (7, 20)], fill=fg)
    elif preset in ("key",):
        d.polygon([(14, 6), (22, 14), (12, 24), (6, 18), (14, 10), (10, 6)], fill=fg)
        circ(2)
    elif preset in ("flag",):
        d.line([(10, 6), (10, 26)], fill=fg, width=2)
        d.polygon([(10, 8), (22, 12), (10, 16)], fill=fg)
    elif preset in ("bookmark",):
        d.polygon([(8, 6), (24, 6), (24, 26), (16, 18), (8, 26)], fill=fg)
    elif preset in ("tag",):
        d.polygon([(8, 10), (16, 4), (26, 14), (14, 26), (6, 18)], outline=fg, width=2)
    elif preset in ("bolt", "chart", "graph", "activity"):
        d.polygon([(16, 4), (12, 14), (16, 14), (10, 28), (20, 12), (15, 12)], fill=fg)
    elif preset in ("compass", "target", "circle"):
        circ(10)
        d.ellipse([cx - 3, cy - 3, cx + 3, cy + 3], fill=(248, 250, 252, 255))
    elif preset in ("coffee", "sun", "moon", "language"):
        circ(8)
    elif preset in ("robot", "sparkles", "api"):
        d.rectangle([8, 12, 24, 24], fill=fg)
        d.ellipse([11, 6, 21, 14], fill=fg)
    elif preset in ("building",):
        d.rectangle([8, 10, 12, 26], fill=fg)
        d.rectangle([13, 6, 19, 26], fill=fg)
        d.rectangle([20, 12, 24, 26], fill=fg)
    elif preset in ("eye",):
        d.pieslice([6, 10, 26, 22], start=0, end=180, fill=fg)
        d.ellipse([12, 14, 20, 20], fill=(248, 250, 252, 255))
    elif preset in ("eye_off",):
        d.line([(8, 10), (24, 22)], fill=fg, width=2)
        d.line([(24, 10), (8, 22)], fill=fg, width=2)
    elif preset in ("print",):
        d.rectangle([8, 8, 24, 18], fill=fg)
        d.rectangle([10, 18, 22, 26], outline=fg, width=2)
    elif preset in ("log_out",):
        d.rectangle([6, 8, 14, 24], outline=fg, width=2)
        d.polygon([(18, 12), (26, 16), (18, 20)], fill=fg)
    else:
        circ(7)

    buf = io.BytesIO()
    im.save(buf, format="PNG")
    return buf.getvalue()


def sql_escape(s: str) -> str:
    return s.replace("'", "''")


def sql_keywords_array(kw: Sequence[str]) -> str:
    inner = ",".join("'" + sql_escape(k) + "'" for k in kw)
    return f"ARRAY[{inner}]::text[]"
