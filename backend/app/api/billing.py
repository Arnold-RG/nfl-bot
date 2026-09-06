from fastapi import APIRouter
from pydantic import BaseModel

from app.api import stub

router = APIRouter()


class CheckoutRequest(BaseModel):
    plan: str = "pro_monthly"
    currency: str = "PLN"


@router.get("/plan")
def plan() -> dict:
    return stub(
        {
            "plan": "free",
            "display_name": "Free",
            "note": "Core health data is never paywalled.",
        }
    )


@router.post("/checkout")
def checkout(body: CheckoutRequest) -> dict:
    return stub(
        {
            "checkout_url": None,
            "plan": body.plan,
            "currency": body.currency,
            "status": "stub_not_configured",
        }
    )


@router.post("/webhook")
def webhook() -> dict:
    return stub({"received": True})


@router.get("/entitlements")
def entitlements() -> dict:
    """Free keeps ownership of core data; Pro gates advanced intelligence."""
    return stub(
        {
            "plan": "free",
            "always_available": [
                "steps",
                "meal_diary",
                "workouts",
                "weight_history",
                "basic_progress",
                "basic_ai_questions",
            ],
            "pro": [
                "unlimited_ai",
                "ai_food_scanner",
                "advanced_workouts",
                "progressive_overload",
                "deep_recovery_analytics",
                "recipes",
                "advanced_personalization",
            ],
        }
    )
