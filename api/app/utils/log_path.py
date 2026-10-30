"""Centralized logging configuration helpers.

Both ``main.py`` and ``cli.py`` import these helpers so the file path and
rotation behavior stay in lock-step.

Env vars (all optional):

- ``LOG_PATH``           : full file path. Wins over ``LOG_DIR``.
- ``LOG_DIR``            : directory (default ``logs``). File name is
                           always ``noolva.log`` inside this dir.
- ``LOG_ROTATE_TIME_UTC``: ``HH:MM`` (24h) UTC clock time at which the file
                           rolls over once per day. Default ``18:30``
                           (which is ``00:00`` IST).
- ``LOG_ROTATE_BACKUP_COUNT`` : number of historical files to keep.
                                Default ``14``.
"""
from __future__ import annotations

import logging
import os
from datetime import time
from logging.handlers import TimedRotatingFileHandler
from typing import Optional


def resolve_log_file() -> str:
    """Return the absolute log file path.

    ``LOG_PATH`` (a full file path) takes precedence. Otherwise the legacy
    ``LOG_DIR`` env (default ``logs``) is used and the file is
    ``<LOG_DIR>/noolva.log``. Parent directory is created if missing.
    """
    explicit = os.getenv("LOG_PATH")
    if explicit:
        parent = os.path.dirname(explicit)
        if parent:
            os.makedirs(parent, exist_ok=True)
        return explicit

    log_dir = os.getenv("LOG_DIR", "logs")
    os.makedirs(log_dir, exist_ok=True)
    return os.path.join(log_dir, "noolva.log")


def _parse_utc_time(value: str) -> time:
    """Parse ``HH:MM`` (24h, UTC). Falls back to 18:30 on malformed input."""
    try:
        hh_str, mm_str = value.strip().split(":", 1)
        hh = int(hh_str)
        mm = int(mm_str)
        if not (0 <= hh < 24 and 0 <= mm < 60):
            raise ValueError("hour/minute out of range")
        return time(hour=hh, minute=mm)
    except Exception:
        return time(hour=18, minute=30)


def build_rotating_handler(
    formatter: Optional[logging.Formatter] = None,
) -> TimedRotatingFileHandler:
    """Build a daily-rotating file handler.

    Rolls over once per day at ``LOG_ROTATE_TIME_UTC`` (default ``18:30``
    UTC) and keeps the last ``LOG_ROTATE_BACKUP_COUNT`` files (default 14).
    Rotated files use a date suffix, e.g. ``noolva.log.2026-05-06``.
    """
    log_file = resolve_log_file()
    rotate_at = _parse_utc_time(os.getenv("LOG_ROTATE_TIME_UTC", "18:30"))

    try:
        backup_count = int(os.getenv("LOG_ROTATE_BACKUP_COUNT", "14"))
    except ValueError:
        backup_count = 14

    handler = TimedRotatingFileHandler(
        log_file,
        when="midnight",
        interval=1,
        backupCount=backup_count,
        utc=True,
        atTime=rotate_at,
        encoding="utf-8",
        delay=False,
    )
    handler.suffix = "%Y-%m-%d"
    if formatter is not None:
        handler.setFormatter(formatter)
    return handler
