from datetime import datetime

from fastapi import APIRouter
from pydantic import BaseModel, Field

from app.api import stub
from app.core.events import HealthEvent, HealthSource, maybe_same_activity, prefer_event

router = APIRouter()


class StepsIngest(BaseModel):
    steps: int = Field(..., ge=0)
    source: HealthSource = HealthSource.manual
    timestamp: datetime | None = None


class ActivitySession(BaseModel):
    activity_type: str = "walk"
    duration_min: int = 30
    distance_km: float = 0
    source: HealthSource = HealthSource.gps_in_app
    calories_est: int = 0


class EventBatch(BaseModel):
    events: list[HealthEvent]


class DedupePreview(BaseModel):
    event_a: HealthEvent
    event_b: HealthEvent


@router.get("/today")
def today() -> dict:
    return stub(
        {
            "steps": 8700,
            "step_goal": 10000,
            "distance_km": 6.2,
            "calories_est": 420,
        }
    )


@router.post("/steps")
def ingest_steps(body: StepsIngest) -> dict:
    return stub(
        {
            "accepted": True,
            "steps": body.steps,
            "source": body.source,
            "timestamp": body.timestamp or datetime.utcnow(),
        }
    )


@router.post("/sessions")
def create_session(body: ActivitySession) -> dict:
    return stub({"session_id": "act-session-001", **body.model_dump()})


@router.get("/sessions")
def list_sessions() -> dict:
    return stub({"sessions": []})


@router.post("/events")
def ingest_events(batch: EventBatch) -> dict:
    return stub({"accepted": len(batch.events), "processing_status": "pending"})


@router.post("/dedupe/preview")
def dedupe_preview(body: DedupePreview) -> dict:
    same = maybe_same_activity(body.event_a, body.event_b)
    winner = prefer_event(body.event_a, body.event_b) if same else None
    return stub(
        {
            "likely_duplicate": same,
            "preferred_source": winner.source if winner else None,
            "preferred_event": winner.model_dump() if winner else None,
        }
    )
