# AI Music App — Backend

FastAPI backend covering auth, AI music generation (OpenAI + ModelsLab), a
personal library, and Shazam-style audio identification (AudD/ACRCloud).

## Setup

```bash
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env
# edit .env and add your real OPENAI_API_KEY / MODELSLAB_API_KEY / AUDIO_ID_API_KEY
```

## Run

```bash
uvicorn app.main:app --reload
```

The API will be live at `http://localhost:8000`. Interactive docs at
`http://localhost:8000/docs`.

## Verify it works

```bash
python smoke_test.py
```

This runs a full flow (register → login → start a generation job → confirm
it completes → check the library) against a local SQLite database, with the
external OpenAI/ModelsLab calls mocked out. It does **not** require real API
keys to run and should print `ALL SMOKE TESTS PASSED`.

## Endpoints

| Method | Path | Auth? | Purpose |
|---|---|---|---|
| POST | `/auth/register` | No | Create a student/user account |
| POST | `/auth/login` | No | Get access + refresh tokens |
| POST | `/auth/refresh` | No (needs refresh token) | Get a new access token |
| POST | `/generation` | Yes | Start an AI music generation job |
| GET | `/generation/{job_id}` | Yes | Poll a generation job's status |
| GET | `/library` | Yes | List your tracks |
| DELETE | `/library/{track_id}` | Yes | Delete a track |
| POST | `/recognition/identify` | Yes | Identify a recorded audio clip |
| GET | `/health` | No | Health check |

## Notes

- Without `MODELSLAB_API_KEY` set, generation jobs will fail gracefully
  (status `failed` with a clear error message) rather than crashing.
- Without `OPENAI_API_KEY` set, prompts are used as-is (no GPT-4 refinement)
  rather than blocking generation entirely.
- Rate limiting is in-memory (per process) — fine for local dev; swap
  `app/core/rate_limit.py` for a Redis-backed version before deploying
  multiple backend instances.
- Switch `DATABASE_URL` in `.env` to a real Postgres URL for anything beyond
  local development (`postgresql://user:pass@host:5432/dbname`).
