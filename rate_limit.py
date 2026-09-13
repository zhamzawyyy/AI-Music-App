"""
Minimal in-memory sliding-window rate limiter, keyed per user per endpoint.

This is fine for local development and a single-process deployment. For
production with multiple backend instances, swap the in-memory dict for
Redis (INCR + EXPIRE) so limits are shared across processes.
"""
import time
from collections import defaultdict
from fastapi import HTTPException, status

_hits: dict[str, list[float]] = defaultdict(list)


def enforce_rate_limit(key: str, max_per_hour: int):
    now = time.time()
    window_start = now - 3600
    _hits[key] = [t for t in _hits[key] if t > window_start]
    if len(_hits[key]) >= max_per_hour:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=f"Rate limit exceeded ({max_per_hour} requests/hour). Try again later.",
        )
    _hits[key].append(now)
