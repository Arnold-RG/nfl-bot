from fastapi import APIRouter
from pydantic import BaseModel, Field

from app.api import stub

router = APIRouter()


class SleepIngest(BaseModel):
    hours: float = Field(..., ge=0, le=24)
    quality: str | None = None
    source: str = "manual"


class VitalsIngest(BaseModel):
    resting_hr: int | None = None
    hrv_ms: float | None = None
    source: str = "manual"


@router.get("/today")
def today() -> dict:
    return stub(
        {
            "recovery_percent": 84,
            "readiness_percent": 78,
            "sleep_hours": 7.7,
            "training_load": 0.62,
            "note": "Wellness estimate — not a medical diagnosis.",
        }
    )


@router.post("/sleep")
def sleep(body: SleepIngest) -> dict:
    return stub({"accepted": True, **body.model_dump()})


@router.get("/muscle-map")
def muscle_map() -> dict:
    return stub(
        {
            "muscles": {
                "chest": 72,
                "back": 65,
                "legs": 40,
                "shoulders": 70,
                "arms": 68,
                "core": 80,
            },
            "unit": "recovery_percent",
        }
    )


@router.post("/vitals")
def vitals(body: VitalsIngest) -> dict:
    return stub({"accepted": True, **body.model_dump()})
