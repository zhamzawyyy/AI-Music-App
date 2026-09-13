"""
Quick smoke test: exercises the real FastAPI app with SQLite, mocking only
the outbound calls to OpenAI/ModelsLab (no real API keys in this sandbox).
Run with: python smoke_test.py
"""
import asyncio
import os
import time

os.environ["DATABASE_URL"] = "sqlite:///./smoke_test.db"

from fastapi.testclient import TestClient
from unittest.mock import patch

from app.main import app

client = TestClient(app)


def run():
    # health check
    r = client.get("/health")
    assert r.status_code == 200, r.text
    print("health check OK:", r.json())

    # register
    r = client.post("/auth/register", json={
        "name": "Ziad Test", "email": "ziad.test@example.com", "password": "password123"
    })
    assert r.status_code == 201, r.text
    print("register OK:", r.json())

    # duplicate register should fail
    r = client.post("/auth/register", json={
        "name": "Ziad Test", "email": "ziad.test@example.com", "password": "password123"
    })
    assert r.status_code == 400, r.text
    print("duplicate register correctly rejected")

    # login
    r = client.post("/auth/login", json={"email": "ziad.test@example.com", "password": "password123"})
    assert r.status_code == 200, r.text
    tokens = r.json()
    print("login OK, got tokens")

    headers = {"Authorization": f"Bearer {tokens['access_token']}"}

    # wrong password
    r = client.post("/auth/login", json={"email": "ziad.test@example.com", "password": "wrong"})
    assert r.status_code == 401
    print("wrong password correctly rejected")

    # empty library
    r = client.get("/library", headers=headers)
    assert r.status_code == 200 and r.json() == [], r.text
    print("empty library OK")

    # mock the external calls for generation
    async def fake_refine(prompt):
        return f"refined: {prompt}"

    async def fake_generate(prompt):
        return "https://example.com/fake-generated-track.mp3"

    with patch("app.api.generation.refine_music_prompt", fake_refine), \
         patch("app.api.generation.generate_music", fake_generate):

        r = client.post("/generation", json={"prompt": "chill lofi beat for studying"}, headers=headers)
        assert r.status_code == 200, r.text
        job = r.json()
        print("generation job started:", job["id"], job["status"])

        # background task runs in-process for TestClient; give it a moment
        for _ in range(20):
            r = client.get(f"/generation/{job['id']}", headers=headers)
            job = r.json()
            if job["status"] in ("completed", "failed"):
                break
            time.sleep(0.1)

        assert job["status"] == "completed", job
        print("generation completed:", job)

    # library should now have one track
    r = client.get("/library", headers=headers)
    tracks = r.json()
    assert len(tracks) == 1, tracks
    print("library after generation OK:", tracks[0]["title"])

    # unauthenticated request should be rejected
    r = client.get("/library")
    assert r.status_code == 401
    print("unauthenticated request correctly rejected")

    print("\nALL SMOKE TESTS PASSED")


if __name__ == "__main__":
    run()
