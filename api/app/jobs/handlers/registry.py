"""
Registry of core_function handlers. Maps handler_function_name -> async callable(payload) -> result dict.
"""
import asyncio
import logging
from typing import Any, Callable, Dict, Optional

logger = logging.getLogger("noolva_api.jobs.handlers")

_REGISTRY: Dict[str, Callable] = {}


def register_handler(name: str, fn: Callable):
    _REGISTRY[name] = fn


def get_handler(name: str) -> Optional[Callable]:
    return _REGISTRY.get(name)


async def run_core_function(handler_function_name: str, payload: Dict[str, Any]) -> Dict[str, Any]:
    fn = get_handler(handler_function_name)
    if fn is None:
        raise ValueError(f"Unknown handler: {handler_function_name}")
    if asyncio.iscoroutinefunction(fn):
        return await fn(payload)
    return fn(payload)


def _register_builtins():
    from . import send_email as _se, generate_report as _gr, notification_push as _np, auto_crud as _ac, custom_query as _cq  # noqa: F401
    # Handlers self-register on import


# Lazy: handlers register on first import of handlers package
def ensure_handlers_loaded():
    from . import send_email  # noqa: F401
    from . import generate_report  # noqa: F401
    from . import notification_push  # noqa: F401
    from . import auto_crud  # noqa: F401
    from . import custom_query  # noqa: F401
    from . import create_jobs_from_records  # noqa: F401
    from . import process_alarm  # noqa: F401
