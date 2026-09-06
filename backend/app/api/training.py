from fastapi import APIRouter
from pydantic import BaseModel, Field

from app.api import stub

router = APIRouter()


class SessionPayload(BaseModel):
    name: str = "Strength session"
    duration_min: int = 45
    exercises: list[dict] = Field(default_factory=list)
    completed: bool = False


class OverloadRequest(BaseModel):
    exercise: str
    last_weight_kg: float
    last_reps: int
    last_rpe: float = Field(..., ge=0, le=10)
    recovery_percent: int = Field(..., ge=0, le=100)


class SubstituteRequest(BaseModel):
    exercise: str
    reason: str = "equipment"
    available_equipment: list[str] = Field(default_factory=list)


@router.get("/today")
def today() -> dict:
    return stub(
        {
            "plan": "Upper body strength",
            "duration_min": 50,
            "focus": ["chest", "back", "shoulders"],
            "status": "ready",
        }
    )


@router.post("/sessions")
def create_session(body: SessionPayload) -> dict:
    return stub({"session_id": "session-stub-001", **body.model_dump()})


@router.get("/sessions")
def list_sessions() -> dict:
    return stub({"sessions": []})


@router.get("/sessions/{session_id}")
def get_session(session_id: str) -> dict:
    return stub({"session_id": session_id, "status": "not_found_stub"})


@router.post("/overload")
def overload(body: OverloadRequest) -> dict:
    # Deterministic stub mirroring product rule: low recovery → hold/reduce
    if body.recovery_percent < 45:
        next_kg = round(body.last_weight_kg * 0.9, 1)
        action = "reduce"
    elif body.last_rpe <= 7 and body.last_reps >= 8 and body.recovery_percent >= 70:
        next_kg = body.last_weight_kg + 2.5
        action = "increase"
    else:
        next_kg = body.last_weight_kg
        action = "hold"
    return stub(
        {
            "exercise": body.exercise,
            "next_weight_kg": next_kg,
            "action": action,
            "deterministic": True,
        }
    )


@router.get("/prs")
def prs() -> dict:
    return stub({"prs": [{"exercise": "bench_press", "weight_kg": 80, "reps": 5}]})


@router.post("/substitute")
def substitute(body: SubstituteRequest) -> dict:
    return stub(
        {
            "original": body.exercise,
            "suggestion": "dumbbell_press",
            "reason": body.reason,
            "equipment": body.available_equipment,
        }
    )
