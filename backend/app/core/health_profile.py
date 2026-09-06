"""Central user health profile — the NFL BOT Health Data Platform brain schema."""

from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field


class BiologicalSex(str, Enum):
    male = "male"
    female = "female"
    other = "other"
    unspecified = "unspecified"


class PrimaryGoal(str, Enum):
    lose_fat = "lose_fat"
    build_muscle = "build_muscle"
    get_stronger = "get_stronger"
    become_healthier = "become_healthier"
    improve_fitness = "improve_fitness"
    maintain = "maintain"


class PersonalBlock(BaseModel):
    age: Optional[int] = Field(default=None, ge=13, le=120)
    sex: BiologicalSex = BiologicalSex.unspecified
    height_cm: Optional[float] = Field(default=None, gt=0)
    weight_kg: Optional[float] = Field(default=None, gt=0)
    locale: Optional[str] = None
    timezone: Optional[str] = None


class GoalsBlock(BaseModel):
    primary: PrimaryGoal = PrimaryGoal.become_healthier
    secondary: list[PrimaryGoal] = Field(default_factory=list)
    target_weight_kg: Optional[float] = None
    weekly_workout_days: Optional[int] = Field(default=None, ge=0, le=7)
    step_goal: int = 10000


class ActivityBlock(BaseModel):
    steps_today: int = 0
    distance_km_today: float = 0.0
    calories_burned_est: int = 0
    last_activity_type: Optional[str] = None
    last_activity_at: Optional[datetime] = None


class NutritionBlock(BaseModel):
    calories_consumed: int = 0
    calories_target: int = 2000
    protein_g: float = 0.0
    carbs_g: float = 0.0
    fat_g: float = 0.0
    water_ml: int = 0
    allergies: list[str] = Field(default_factory=list)
    dietary_preferences: list[str] = Field(default_factory=list)


class TrainingBlock(BaseModel):
    experience_level: str = "beginner"  # beginner | intermediate | advanced
    equipment: list[str] = Field(default_factory=list)
    last_session_summary: Optional[str] = None
    last_rpe: Optional[float] = Field(default=None, ge=0, le=10)
    focus_muscles: list[str] = Field(default_factory=list)


class RecoveryBlock(BaseModel):
    sleep_hours: Optional[float] = None
    resting_hr: Optional[int] = None
    hrv_ms: Optional[float] = None
    training_load: Optional[float] = None
    recovery_percent: int = Field(default=70, ge=0, le=100)
    readiness_percent: int = Field(default=70, ge=0, le=100)


class AIProfileBlock(BaseModel):
    coaching_tone: str = "supportive"
    preferences: list[str] = Field(default_factory=list)
    behavior_notes: list[str] = Field(default_factory=list)
    last_recommendation: Optional[str] = None
    feedback_scores: dict[str, float] = Field(default_factory=dict)


class HealthProfile(BaseModel):
    """Canonical per-user health brain used by all engines."""

    user_id: str
    personal: PersonalBlock = Field(default_factory=PersonalBlock)
    goals: GoalsBlock = Field(default_factory=GoalsBlock)
    activity: ActivityBlock = Field(default_factory=ActivityBlock)
    nutrition: NutritionBlock = Field(default_factory=NutritionBlock)
    training: TrainingBlock = Field(default_factory=TrainingBlock)
    recovery: RecoveryBlock = Field(default_factory=RecoveryBlock)
    ai_profile: AIProfileBlock = Field(default_factory=AIProfileBlock)
    updated_at: datetime = Field(default_factory=datetime.utcnow)


def demo_health_profile(user_id: str = "demo-user-001") -> HealthProfile:
    return HealthProfile(
        user_id=user_id,
        personal=PersonalBlock(
            age=30,
            sex=BiologicalSex.male,
            height_cm=175,
            weight_kg=75,
            locale="en",
            timezone="Europe/Warsaw",
        ),
        goals=GoalsBlock(
            primary=PrimaryGoal.build_muscle,
            secondary=[PrimaryGoal.improve_fitness],
            target_weight_kg=78,
            weekly_workout_days=4,
            step_goal=10000,
        ),
        activity=ActivityBlock(
            steps_today=8700,
            distance_km_today=6.2,
            calories_burned_est=420,
            last_activity_type="walk",
        ),
        nutrition=NutritionBlock(
            calories_consumed=1450,
            calories_target=2550,
            protein_g=110,
            carbs_g=180,
            fat_g=55,
            water_ml=1500,
            allergies=["peanuts"],
        ),
        training=TrainingBlock(
            experience_level="intermediate",
            equipment=["barbell", "dumbbells", "cables"],
            last_session_summary="Upper body · 48 min",
            last_rpe=7.5,
            focus_muscles=["chest", "back", "shoulders"],
        ),
        recovery=RecoveryBlock(
            sleep_hours=7.7,
            resting_hr=58,
            hrv_ms=62,
            training_load=0.62,
            recovery_percent=84,
            readiness_percent=78,
        ),
        ai_profile=AIProfileBlock(
            coaching_tone="direct",
            last_recommendation="Train upper body ~50 min; prioritize protein at lunch.",
        ),
    )
