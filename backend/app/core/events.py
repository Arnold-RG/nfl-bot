"""Health events, source priority, and dedupe stubs for the Health Data Platform."""

from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Any, Optional

from pydantic import BaseModel, Field


class HealthSource(str, Enum):
    """Lower enum order is not priority — use SOURCE_PRIORITY list."""

    apple_watch = "apple_watch"
    wear_os = "wear_os"
    garmin = "garmin"
    healthkit = "healthkit"
    health_connect = "health_connect"
    gps_in_app = "gps_in_app"
    manual = "manual"
    estimate = "estimate"
    strava = "strava"
    other = "other"


# Highest priority first (tune per metric in production).
SOURCE_PRIORITY: list[HealthSource] = [
    HealthSource.apple_watch,
    HealthSource.wear_os,
    HealthSource.garmin,
    HealthSource.healthkit,
    HealthSource.health_connect,
    HealthSource.gps_in_app,
    HealthSource.strava,
    HealthSource.manual,
    HealthSource.estimate,
    HealthSource.other,
]


class ProcessingStatus(str, Enum):
    pending = "pending"
    verified = "verified"
    merged = "merged"
    rejected = "rejected"


class HealthEvent(BaseModel):
    event_id: Optional[str] = None
    client_event_id: Optional[str] = None
    user_id: str
    event_type: str  # steps | workout | meal | sleep | hr | hrv | gps_session | …
    source: HealthSource = HealthSource.manual
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    confidence: float = Field(default=0.8, ge=0.0, le=1.0)
    processing_status: ProcessingStatus = ProcessingStatus.pending
    payload: dict[str, Any] = Field(default_factory=dict)


def source_rank(source: HealthSource) -> int:
    try:
        return SOURCE_PRIORITY.index(source)
    except ValueError:
        return len(SOURCE_PRIORITY)


def prefer_event(a: HealthEvent, b: HealthEvent) -> HealthEvent:
    """Return the higher-priority event; break ties with newer timestamp + confidence."""
    ra, rb = source_rank(a.source), source_rank(b.source)
    if ra != rb:
        return a if ra < rb else b
    if a.timestamp != b.timestamp:
        return a if a.timestamp > b.timestamp else b
    return a if a.confidence >= b.confidence else b


def maybe_same_activity(a: HealthEvent, b: HealthEvent, window_seconds: int = 900) -> bool:
    """Heuristic stub: same type within time window — production should also match distance/HR."""
    if a.event_type != b.event_type:
        return False
    if a.user_id != b.user_id:
        return False
    delta = abs((a.timestamp - b.timestamp).total_seconds())
    return delta <= window_seconds
