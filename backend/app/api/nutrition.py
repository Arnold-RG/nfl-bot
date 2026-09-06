from fastapi import APIRouter, Query
from pydantic import BaseModel, Field

from app.api import stub
from app.core.safety import allergy_conflict

router = APIRouter()


class MealCreate(BaseModel):
    name: str
    calories: int = 0
    protein_g: float = 0
    carbs_g: float = 0
    fat_g: float = 0
    ingredients: list[str] = Field(default_factory=list)
    source: str = "manual"


class WaterAdd(BaseModel):
    ml: int = Field(..., gt=0)


class VisionRequest(BaseModel):
    image_url: str | None = None
    image_base64_len: int | None = None  # stub: avoid large payloads in skeleton


@router.get("/today")
def today() -> dict:
    return stub(
        {
            "date": "2026-09-06",
            "calories": 1450,
            "protein_g": 110,
            "carbs_g": 180,
            "fat_g": 55,
            "water_ml": 1500,
        }
    )


@router.get("/diary")
def diary(date: str = Query(..., description="YYYY-MM-DD")) -> dict:
    return stub({"date": date, "meals": [], "water_ml": 0})


@router.post("/meals")
def create_meal(meal: MealCreate) -> dict:
    conflicts = allergy_conflict(meal.ingredients, ["peanuts"])  # demo allergies
    return stub(
        {
            "meal_id": "meal-stub-001",
            **meal.model_dump(),
            "allergy_warnings": conflicts,
        }
    )


@router.patch("/meals/{meal_id}")
def patch_meal(meal_id: str, meal: MealCreate) -> dict:
    return stub({"meal_id": meal_id, **meal.model_dump()})


@router.delete("/meals/{meal_id}")
def delete_meal(meal_id: str) -> dict:
    return stub({"meal_id": meal_id, "deleted": True})


@router.post("/water")
def add_water(body: WaterAdd) -> dict:
    return stub({"added_ml": body.ml, "total_ml_today": 1500 + body.ml})


@router.get("/targets")
def targets() -> dict:
    return stub(
        {
            "calories": 2550,
            "protein_g": 170,
            "carbs_g": 260,
            "fat_g": 70,
            "water_ml": 3000,
        }
    )


@router.post("/vision")
def vision(body: VisionRequest) -> dict:
    return stub(
        {
            "estimate": {
                "label": "Mixed plate (editable)",
                "calories": 520,
                "protein_g": 32,
                "carbs_g": 45,
                "fat_g": 18,
            },
            "received_image_url": body.image_url,
            "note": "Estimates must be user-confirmed before logging.",
        }
    )


@router.get("/foods/search")
def food_search(q: str = Query(..., min_length=1)) -> dict:
    return stub(
        {
            "query": q,
            "results": [
                {"id": "food-1", "name": f"{q} (generic)", "calories_per_100g": 120},
            ],
        }
    )


@router.get("/barcode/{code}")
def barcode(code: str) -> dict:
    return stub(
        {
            "code": code,
            "found": False,
            "product": None,
            "note": "Barcode DB not connected in skeleton.",
        }
    )
