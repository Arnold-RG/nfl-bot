"""Smoke tests for the FastAPI app after the dependency upgrade."""

from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health() -> None:
    response = client.get("/health")
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok"
    assert body["service"] == "nflbot-api"
    assert body["version"]


def test_root() -> None:
    response = client.get("/")
    assert response.status_code == 200
    body = response.json()
    assert body["ok"] is True
    assert body["health"] == "/health"
    assert body["docs"] == "/docs"
    assert "auth" in body["modules"]


def test_openapi_docs() -> None:
    spec = client.get("/openapi.json")
    assert spec.status_code == 200
    assert spec.json()["info"]["title"]
    docs = client.get("/docs")
    assert docs.status_code == 200


def test_module_reads() -> None:
    gets = [
        "/users/me",
        "/nutrition/today",
        "/training/today",
        "/activity/today",
        "/recovery/today",
        "/ai/morning",
        "/social/friends",
        "/billing/plan",
    ]
    for path in gets:
        response = client.get(path)
        assert response.status_code == 200, path
        assert response.json()["ok"] is True, path

    logout = client.post("/auth/logout")
    assert logout.status_code == 200
    assert logout.json()["ok"] is True

    # Profile is the canonical model, not the stub envelope.
    profile = client.get("/users/me/profile")
    assert profile.status_code == 200
    assert profile.json()["user_id"] == "demo-user-001"


def test_json_post_with_content_type() -> None:
    response = client.post(
        "/auth/login",
        json={"email": "demo@nflbot.app", "password": "password123"},
    )
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["access_token"]
    assert data["email"] == "demo@nflbot.app"


def test_invalid_json_body_is_rejected() -> None:
    response = client.post("/nutrition/water", json={"ml": 0})
    assert response.status_code == 422
