from fastapi import APIRouter

from app.api import (
    activity,
    ai,
    auth,
    billing,
    nutrition,
    recovery,
    social,
    training,
    users,
)

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(nutrition.router, prefix="/nutrition", tags=["nutrition"])
api_router.include_router(training.router, prefix="/training", tags=["training"])
api_router.include_router(activity.router, prefix="/activity", tags=["activity"])
api_router.include_router(recovery.router, prefix="/recovery", tags=["recovery"])
api_router.include_router(ai.router, prefix="/ai", tags=["ai"])
api_router.include_router(social.router, prefix="/social", tags=["social"])
api_router.include_router(billing.router, prefix="/billing", tags=["billing"])
