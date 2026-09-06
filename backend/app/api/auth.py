from fastapi import APIRouter
from pydantic import BaseModel, Field

from app.api import stub

router = APIRouter()


class RegisterRequest(BaseModel):
    email: str = Field(..., min_length=4)
    password: str = Field(..., min_length=8)


class LoginRequest(BaseModel):
    email: str
    password: str


class RefreshRequest(BaseModel):
    refresh_token: str


class OAuthRequest(BaseModel):
    code: str | None = None
    id_token: str | None = None


@router.post("/register")
def register(payload: RegisterRequest) -> dict:
    return stub(
        {
            "user_id": "demo-user-001",
            "email": payload.email,
            "access_token": "stub-access-token",
            "refresh_token": "stub-refresh-token",
        }
    )


@router.post("/login")
def login(payload: LoginRequest) -> dict:
    return stub(
        {
            "user_id": "demo-user-001",
            "email": payload.email,
            "access_token": "stub-access-token",
            "refresh_token": "stub-refresh-token",
        }
    )


@router.post("/refresh")
def refresh(payload: RefreshRequest) -> dict:
    return stub(
        {
            "access_token": "stub-access-token-refreshed",
            "refresh_token": payload.refresh_token,
        }
    )


@router.post("/logout")
def logout() -> dict:
    return stub({"logged_out": True})


@router.post("/oauth/{provider}")
def oauth(provider: str, payload: OAuthRequest) -> dict:
    return stub(
        {
            "provider": provider,
            "user_id": "demo-user-001",
            "access_token": "stub-oauth-access",
            "refresh_token": "stub-oauth-refresh",
            "received_code": bool(payload.code or payload.id_token),
        }
    )
