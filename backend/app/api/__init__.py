"""Shared API helpers."""

from typing import Any, Optional


def stub(data: Any, **extra_meta: Any) -> dict:
    meta = {"stub": True, **extra_meta}
    return {"ok": True, "data": data, "meta": meta}


def err(code: str, message: str, status_hint: Optional[int] = None) -> dict:
    body: dict[str, Any] = {"ok": False, "error": {"code": code, "message": message}}
    if status_hint is not None:
        body["error"]["status_hint"] = status_hint
    return body
