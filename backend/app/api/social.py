from fastapi import APIRouter
from pydantic import BaseModel

from app.api import stub

router = APIRouter()


class FriendRequest(BaseModel):
    handle: str


class ShareCardRequest(BaseModel):
    kind: str = "pr"  # pr | streak | challenge
    title: str = "NEW PERSONAL RECORD"
    subtitle: str = "BENCH PRESS"
    value: str = "80 KG"
    delta: str | None = "+5 KG"


@router.get("/friends")
def friends() -> dict:
    return stub({"friends": []})


@router.post("/friends/request")
def friend_request(body: FriendRequest) -> dict:
    return stub({"requested": body.handle, "status": "pending"})


@router.get("/challenges")
def challenges() -> dict:
    return stub(
        {
            "challenges": [
                {"id": "ch-1", "title": "10k steps × 7 days", "joined": False},
            ]
        }
    )


@router.post("/challenges/{challenge_id}/join")
def join_challenge(challenge_id: str) -> dict:
    return stub({"challenge_id": challenge_id, "joined": True})


@router.post("/share-cards")
def share_cards(body: ShareCardRequest) -> dict:
    lines = [
        "NFL BOT",
        body.title,
        body.subtitle,
        body.value,
    ]
    if body.delta:
        lines.append(body.delta)
    lines.append("KEEP BUILDING.")
    return stub({"kind": body.kind, "lines": lines, "render": "minimal_premium_card"})
