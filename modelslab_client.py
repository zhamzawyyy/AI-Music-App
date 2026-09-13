"""
Wraps the ModelsLab music generation API call. Isolated from route logic
so it's easy to mock in tests and swap providers later.
"""
import httpx
from app.core.config import settings

MODELSLAB_URL = "https://modelslab.com/api/v6/voice/music_gen"


class GenerationError(Exception):
    pass


async def generate_music(prompt: str) -> str:
    """Returns a URL to the generated audio file."""
    if not settings.modelslab_api_key:
        raise GenerationError(
            "ModelsLab API key is not configured. Set MODELSLAB_API_KEY in your .env file."
        )

    payload = {
        "key": settings.modelslab_api_key,
        "prompt": prompt,
        "init_audio": None,
    }

    async with httpx.AsyncClient(timeout=120) as client:
        resp = await client.post(MODELSLAB_URL, json=payload)
        resp.raise_for_status()
        data = resp.json()

    if data.get("status") == "error":
        raise GenerationError(data.get("message", "Unknown ModelsLab error"))

    audio_url = (data.get("output") or [None])[0]
    if not audio_url:
        raise GenerationError("ModelsLab did not return an audio file.")
    return audio_url
