"""AI orchestrator — routes intent to deterministic engines vs LLM stubs."""

from __future__ import annotations

from enum import Enum
from typing import Any, Optional

from pydantic import BaseModel, Field

from app.core.health_profile import HealthProfile, demo_health_profile
from app.core.safety import safety_gate_user_text, wrap_coach_reply


class Intent(str, Enum):
    food_vision = "food_vision"
    what_to_eat = "what_to_eat"
    training_prescription = "training_prescription"
    explain_progress = "explain_progress"
    what_now = "what_now"
    morning_brief = "morning_brief"
    general_chat = "general_chat"
    unknown = "unknown"


class OrchestrateRequest(BaseModel):
    user_id: str = "demo-user-001"
    text: Optional[str] = None
    intent_hint: Optional[Intent] = None
    context: dict[str, Any] = Field(default_factory=dict)


def classify_intent(text: str | None, hint: Intent | None) -> Intent:
    if hint:
        return hint
    t = (text or "").lower()
    if not t:
        return Intent.unknown
    if "what should i do now" in t or "what now" in t:
        return Intent.what_now
    if "in this food" in t or "what's in" in t or "photo" in t:
        return Intent.food_vision
    if "eat" in t or "meal" in t or "protein" in t:
        return Intent.what_to_eat
    if "bench" in t or "squat" in t or "next week" in t or "workout" in t:
        return Intent.training_prescription
    if "progress" in t or "explain" in t:
        return Intent.explain_progress
    if "morning" in t or "good morning" in t:
        return Intent.morning_brief
    return Intent.general_chat


def _profile(user_id: str) -> HealthProfile:
    return demo_health_profile(user_id)


def route(request: OrchestrateRequest) -> dict[str, Any]:
    gate = safety_gate_user_text(request.text or "")
    if not gate["allowed"]:
        return {
            "intent": Intent.general_chat.value,
            "handler": "safety",
            "deterministic": True,
            "result": wrap_coach_reply(gate["message"], include_disclaimer=True),
            "meta": {"stub": True, "safety": gate},
        }

    intent = classify_intent(request.text, request.intent_hint)
    profile = _profile(request.user_id)

    if intent == Intent.food_vision:
        return {
            "intent": intent.value,
            "handler": "vision+nutrition_db",
            "deterministic": False,
            "result": {
                "estimate": {
                    "calories": 520,
                    "protein_g": 32,
                    "carbs_g": 45,
                    "fat_g": 18,
                    "label": "Grilled chicken bowl (editable estimate)",
                },
                "note": "User must confirm quantities before diary commit.",
            },
            "meta": {"stub": True},
        }

    if intent == Intent.what_to_eat:
        allergies = profile.nutrition.allergies
        return {
            "intent": intent.value,
            "handler": "nutrition_engine+llm",
            "deterministic": False,
            "result": wrap_coach_reply(
                f"You're at {profile.nutrition.calories_consumed}/"
                f"{profile.nutrition.calories_target} kcal. "
                f"Aim for a high-protein meal (~40g). "
                f"Allergy constraints active: {', '.join(allergies) or 'none'}."
            ),
            "meta": {"stub": True},
        }

    if intent == Intent.training_prescription:
        recovery = profile.recovery.recovery_percent
        return {
            "intent": intent.value,
            "handler": "training_algorithm",
            "deterministic": True,
            "result": {
                "exercise": "bench_press",
                "prescription": "60 kg × 8–10",
                "rationale": f"Based on last RPE and recovery {recovery}% — not an LLM guess.",
                "adjustment": "hold" if recovery < 60 else "small_increase",
            },
            "meta": {"stub": True},
        }

    if intent == Intent.explain_progress:
        return {
            "intent": intent.value,
            "handler": "analytics+llm",
            "deterministic": False,
            "result": wrap_coach_reply(
                f"Steps {profile.activity.steps_today}/{profile.goals.step_goal}, "
                f"recovery {profile.recovery.recovery_percent}%, "
                f"protein {profile.nutrition.protein_g:.0f}g so far. "
                "Training load and sleep are the main drivers of today's readiness."
            ),
            "meta": {"stub": True},
        }

    if intent == Intent.what_now:
        return what_should_i_do_now(profile)

    if intent == Intent.morning_brief:
        return morning_brief(profile)

    return {
        "intent": intent.value,
        "handler": "llm_chat",
        "deterministic": False,
        "result": wrap_coach_reply(
            "I'm your NFL BOT coach. Ask what to do now, what to eat, or how to train today."
        ),
        "meta": {"stub": True},
    }


def what_should_i_do_now(profile: HealthProfile | None = None) -> dict[str, Any]:
    profile = profile or demo_health_profile()
    protein_gap = max(0, 160 - profile.nutrition.protein_g)
    steps_left = max(0, profile.goals.step_goal - profile.activity.steps_today)
    msg = (
        f"Recovery {profile.recovery.recovery_percent}%. "
        f"Protein still short by ~{protein_gap:.0f}g. "
        f"About {steps_left} steps left. "
        "If you have 45+ minutes, start today's strength session; otherwise walk 10 minutes and eat protein."
    )
    return {
        "intent": Intent.what_now.value,
        "handler": "orchestrator_day_state",
        "deterministic": True,
        "result": wrap_coach_reply(msg),
        "meta": {"stub": True},
    }


def morning_brief(profile: HealthProfile | None = None) -> dict[str, Any]:
    profile = profile or demo_health_profile()
    return {
        "intent": Intent.morning_brief.value,
        "handler": "morning_ai",
        "deterministic": True,
        "result": {
            "title": "Good morning",
            "recovery_percent": profile.recovery.recovery_percent,
            "training_focus": "Upper body",
            "calories": profile.nutrition.calories_target,
            "protein_g": 170,
            "steps": profile.goals.step_goal,
            "sleep": profile.recovery.sleep_hours,
            "coach_line": (
                f"Recovery looks solid ({profile.recovery.recovery_percent}%). "
                "Train upper body ~50 minutes. Calorie target is moderate for expected activity."
            ),
            "disclaimer": (
                "NFL BOT provides wellness and fitness guidance and is not a substitute for "
                "professional medical advice, diagnosis, or treatment."
            ),
        },
        "meta": {"stub": True},
    }
