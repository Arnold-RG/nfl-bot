"""Medical boundary and safety helpers for AI / coaching responses."""

from __future__ import annotations

import re
from typing import Iterable

MEDICAL_DISCLAIMER = (
    "NFL BOT provides wellness and fitness guidance and is not a substitute for "
    "professional medical advice, diagnosis, or treatment."
)

# Conservative symptom / crisis cues — expand with clinical review before production.
_SERIOUS_SYMPTOM_PATTERNS = [
    r"\bchest pain\b",
    r"\bcan'?t breathe\b",
    r"\bdifficulty breathing\b",
    r"\bsuicidal\b",
    r"\bself[- ]harm\b",
    r"\bstroke\b",
    r"\bheart attack\b",
    r"\bunconscious\b",
    r"\bsevere allergic\b",
    r"\banaphylaxis\b",
]

_COMPILED = [re.compile(p, re.IGNORECASE) for p in _SERIOUS_SYMPTOM_PATTERNS]


def contains_serious_symptom_language(text: str) -> bool:
    return any(p.search(text or "") for p in _COMPILED)


def medical_redirect_message() -> str:
    return (
        f"{MEDICAL_DISCLAIMER} If you may be experiencing a medical emergency or "
        "serious symptoms, seek emergency services or contact a qualified clinician. "
        "NFL BOT cannot diagnose or treat medical conditions."
    )


def allergy_conflict(ingredients: Iterable[str], allergies: Iterable[str]) -> list[str]:
    """Programmatic allergy check — do not rely on the LLM alone."""
    allergy_set = {a.strip().lower() for a in allergies if a and a.strip()}
    hits: list[str] = []
    for item in ingredients:
        low = (item or "").strip().lower()
        for allergy in allergy_set:
            if allergy and allergy in low:
                hits.append(item)
                break
    return hits


def wrap_coach_reply(reply: str, *, include_disclaimer: bool = False) -> dict:
    payload = {
        "reply": reply,
        "is_medical_advice": False,
        "safety": {"passed": True, "flags": []},
    }
    if include_disclaimer:
        payload["disclaimer"] = MEDICAL_DISCLAIMER
    return payload


def safety_gate_user_text(text: str) -> dict:
    """Pre-LLM / pre-engine gate for user utterances."""
    if contains_serious_symptom_language(text):
        return {
            "allowed": False,
            "action": "medical_redirect",
            "message": medical_redirect_message(),
            "disclaimer": MEDICAL_DISCLAIMER,
        }
    return {
        "allowed": True,
        "action": "continue",
        "disclaimer": MEDICAL_DISCLAIMER,
    }
