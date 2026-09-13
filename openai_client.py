"""
Wraps the OpenAI call used to turn a rough user prompt into a well-formed
music-generation prompt. Kept in its own module so it's trivial to mock
in tests and swap providers later without touching route logic.
"""
import httpx
from app.core.config import settings

OPENAI_URL = "https://api.openai.com/v1/chat/completions"


async def refine_music_prompt(raw_prompt: str) -> str:
    if not settings.openai_api_key:
        # No key configured (e.g. local dev) -- fall back to the raw prompt
        # rather than failing the whole request.
        return raw_prompt

    system_msg = (
        "You turn a short, casual description of desired music into a single, "
        "detailed prompt for an AI music generation model. Include genre, mood, "
        "tempo, and key instruments. Respond with the prompt text only."
    )
    payload = {
        "model": "gpt-4",
        "messages": [
            {"role": "system", "content": system_msg},
            {"role": "user", "content": raw_prompt},
        ],
        "max_tokens": 200,
        "temperature": 0.7,
    }
    headers = {"Authorization": f"Bearer {settings.openai_api_key}"}

    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.post(OPENAI_URL, json=payload, headers=headers)
        resp.raise_for_status()
        data = resp.json()
        return data["choices"][0]["message"]["content"].strip()
