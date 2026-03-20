"""
QueueManager: in-memory ready_queue (PriorityQueue), delayed_queue (heap), cron_registry.
Used by scheduler to move DB jobs into ready_queue and by workers to consume.
"""
import asyncio
import heapq
import logging
from typing import Any, Dict, Optional
from dataclasses import dataclass, field

logger = logging.getLogger("noolva_api.jobs")


@dataclass(order=True)
class QueuedJob:
    """Priority is (schedule_priority, created_at). Lower = higher priority."""
    priority: tuple
    job: Dict[str, Any] = field(compare=False)


class QueueManager:
    def __init__(self, max_size: int = 10000):
        self._max_size = max_size
        self._ready_queue: asyncio.PriorityQueue = asyncio.PriorityQueue(maxsize=max_size)
        self._delayed_heap: list = []  # (run_at_ts, QueuedJob)
        self._cron_registry: Dict[str, Dict[str, Any]] = {}

    def ready_put_nowait(self, job: Dict[str, Any], priority: Optional[int] = 0) -> bool:
        """Add job to ready queue. priority lower = run first. Returns False if queue full."""
        try:
            # priority tuple: (priority, timestamp for stable order)
            import time
            self._ready_queue.put_nowait(QueuedJob((priority, time.monotonic()), job))
            return True
        except asyncio.QueueFull:
            logger.warning("Ready queue full, dropping job %s", job.get("id"))
            return False

    async def ready_put(self, job: Dict[str, Any], priority: Optional[int] = 0) -> bool:
        """Async put; waits if queue full up to a short timeout."""
        import time
        try:
            await asyncio.wait_for(
                self._ready_queue.put(QueuedJob((priority, time.monotonic()), job)),
                timeout=5.0
            )
            return True
        except asyncio.TimeoutError:
            logger.warning("Ready queue put timeout, dropping job %s", job.get("id"))
            return False

    async def ready_get(self, timeout: Optional[float] = 1.0) -> Optional[Dict[str, Any]]:
        """Get next job from ready queue. Returns None on timeout."""
        try:
            qj = await asyncio.wait_for(self._ready_queue.get(), timeout=timeout)
            return qj.job
        except asyncio.TimeoutError:
            return None

    def ready_qsize(self) -> int:
        return self._ready_queue.qsize()

    def add_delayed(self, run_at_ts: float, job: Dict[str, Any], priority: int = 0):
        """Add to delayed heap. run_at_ts is Unix timestamp when job should run."""
        import time
        heapq.heappush(self._delayed_heap, (run_at_ts, priority, time.monotonic(), job))

    def pop_due_delayed(self, now_ts: float) -> list:
        """Pop all delayed jobs where run_at_ts <= now_ts. Returns list of jobs."""
        due = []
        while self._delayed_heap and self._delayed_heap[0][0] <= now_ts:
            _, pri, _, job = heapq.heappop(self._delayed_heap)
            due.append((pri, job))
        return due

    def cron_register(self, key: str, config: Dict[str, Any]):
        self._cron_registry[key] = config

    def cron_get_all(self) -> Dict[str, Dict[str, Any]]:
        return dict(self._cron_registry)

    @property
    def max_size(self) -> int:
        return self._max_size


# Singleton used by scheduler and workers
_queue_manager: Optional[QueueManager] = None


def get_queue_manager(max_size: Optional[int] = None) -> QueueManager:
    global _queue_manager
    if _queue_manager is None:
        import os
        _queue_manager = QueueManager(max_size=int(os.getenv("QUEUE_MAX_SIZE", "10000")))
    return _queue_manager
