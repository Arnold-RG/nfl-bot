from fastapi import APIRouter
from pydantic import BaseModel, Field

from app.api import stub
from app.core.safety import safety_gate_user_text, wrap_coach_reply
from app.services import orchestrator
from app.services.orchestrator import Intent, OrchestrateRequest

router = APIRouter()


class ChatRequest(BaseModel):
    user_id: str = "demo-user-001"
    text: str = Field(..., min_length=1, max_length=4000)


class NowRequest(BaseModel):
    user_id: str = "demo-user-001"
    local_hour: int | None = Field(default=None, ge=0, le=23)


@router.post("/orchestrate")
def orchestrate(body: OrchestrateRequest) -> dict:
    return stub(orchestrator.route(body))


@router.get("/morning")
def morning(user_id: str = "demo-user-001") -> dict:
    return stub(orchestrator.morning_brief())


@router.post("/now")
def now(body: NowRequest) -> dict:
    result = orchestrator.what_should_i_do_now()
    if body.local_hour is not None:
        result["local_hour"] = body.local_hour
    return stub(result)


@router.get("/daily-plan")
def daily_plan() -> dict:
    return stub(
        {
            "blocks": [
                {"time": "08:00", "item": "Breakfast"},
                {"time": "12:30", "item": "Lunch"},
                {"time": "17:30", "item": "Workout"},
                {"time": "19:00", "item": "Dinner"},
                {"time": "21:30", "item": "Recovery / wind down"},
            ]
        }
    )


@router.post("/chat")
def chat(body: ChatRequest) -> dict:
    gate = safety_gate_user_text(body.text)
    if not gate["allowed"]:
        return stub(wrap_coach_reply(gate["message"], include_disclaimer=True))
    routed = orchestrator.route(
        OrchestrateRequest(user_id=body.user_id, text=body.text, intent_hint=Intent.general_chat)
    )
    return stub(routed)


@router.get("/weekly-review")
def weekly_review() -> dict:
    return stub(
        {
            "headline": "Solid consistency — recovery dipped mid-week",
            "wins": ["4 workouts logged", "Protein average 140g"],
            "focus_next_week": "Add 1,500 steps on rest days; protect sleep before heavy lower body.",
        }
    )
