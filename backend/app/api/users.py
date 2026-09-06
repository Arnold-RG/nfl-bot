from fastapi import APIRouter
from pydantic import BaseModel

from app.api import stub
from app.core.health_profile import GoalsBlock, HealthProfile, demo_health_profile

router = APIRouter()


class Consents(BaseModel):
    account: bool = True
    body_metrics: bool = True
    activity: bool = False
    nutrition: bool = False
    training: bool = False
    recovery_vitals: bool = False
    ai_interactions: bool = False
    social: bool = False
    analytics: bool = False
    location_gps: bool = False


@router.get("/me")
def me() -> dict:
    return stub(
        {
            "user_id": "demo-user-001",
            "email": "demo@nflbot.app",
            "display_name": "Alex",
            "plan": "free",
        }
    )


@router.get("/me/profile")
def get_profile() -> HealthProfile:
    return demo_health_profile()


@router.put("/me/profile")
def put_profile(profile: HealthProfile) -> dict:
    return stub(profile.model_dump())


@router.patch("/me/goals")
def patch_goals(goals: GoalsBlock) -> dict:
    profile = demo_health_profile()
    profile.goals = goals
    return stub({"goals": goals.model_dump(), "user_id": profile.user_id})


@router.get("/me/consents")
def get_consents() -> dict:
    return stub(Consents().model_dump())


@router.put("/me/consents")
def put_consents(consents: Consents) -> dict:
    return stub(consents.model_dump())


@router.delete("/me")
def delete_me() -> dict:
    return stub({"deletion_requested": True, "status": "pending"})
