"""NFL BOT FastAPI application — modular monolith entrypoint."""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.router import api_router
from app.config import get_settings

settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description=(
        "NFL BOT Health Data Platform API (modular monolith). "
        "Member app ~:8080 · Creator SOC ~:9090 (URL/API only) · this API :8000."
    ),
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router)


@app.get("/health")
def health() -> dict:
    return {
        "status": "ok",
        "service": "nflbot-api",
        "version": settings.app_version,
        "environment": settings.environment,
    }


@app.get("/")
def root() -> dict:
    return {
        "ok": True,
        "service": settings.app_name,
        "version": settings.app_version,
        "docs": "/docs",
        "health": "/health",
        "member_app_url": settings.member_app_url,
        "creator_soc_url": settings.creator_soc_url,
        "modules": [
            "auth",
            "users",
            "nutrition",
            "training",
            "activity",
            "recovery",
            "ai",
            "social",
            "billing",
        ],
    }
