"""
Wraps a Shazam-style audio identification API call. Written against AudD's
simple REST API as the default since it's the fastest to integrate; swap
the implementation for ACRCloud if you need its larger catalog later.

AudD docs: https://docs.audd.io/
"""
import httpx
from app.core.config import settings

AUDD_URL = "https://api.audd.io/"


class RecognitionError(Exception):
    pass


async def identify_audio_clip(audio_bytes: bytes) -> dict:
    if not settings.audio_id_api_key:
        raise RecognitionError(
            "Audio ID API key is not configured. Set AUDIO_ID_API_KEY in your .env file."
        )

    files = {"file": ("clip.m4a", audio_bytes)}
    data = {"api_token": settings.audio_id_api_key, "return": "spotify"}

    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.post(AUDD_URL, data=data, files=files)
        resp.raise_for_status()
        result = resp.json()

    if result.get("status") != "success":
        raise RecognitionError(result.get("error", {}).get("error_message", "Recognition failed"))

    match = result.get("result")
    if not match:
        return {"matched": False}

    return {
        "matched": True,
        "title": match.get("title"),
        "artist": match.get("artist"),
        "album": match.get("album"),
    }
