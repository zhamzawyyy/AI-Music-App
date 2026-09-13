from fastapi import APIRouter, Depends, BackgroundTasks
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.rate_limit import enforce_rate_limit
from app.core.config import settings
from app.api.deps import get_current_user
from app.models.models import User, GenerationJob, JobStatus, Track, TrackSource
from app.schemas.schemas import GenerationRequest, GenerationJobOut
from app.services.openai_client import refine_music_prompt
from app.services.modelslab_client import generate_music, GenerationError

router = APIRouter(prefix="/generation", tags=["generation"])


async def _run_generation_job(job_id: str, db_factory):
    """Background task: refine the prompt, call ModelsLab, store the result."""
    db = db_factory()
    try:
        job = db.get(GenerationJob, job_id)
        if not job:
            return
        job.status = JobStatus.running
        db.commit()

        try:
            refined = await refine_music_prompt(job.raw_prompt)
            job.refined_prompt = refined
            db.commit()

            audio_url = await generate_music(refined)

            track = Track(
                owner_id=job.user_id,
                title=job.raw_prompt[:60],
                prompt=refined,
                source=TrackSource.ai_generated,
                is_ai_generated=True,
                audio_url=audio_url,
            )
            db.add(track)
            db.commit()
            db.refresh(track)

            job.status = JobStatus.completed
            job.result_track_id = track.id
            db.commit()

        except GenerationError as e:
            job.status = JobStatus.failed
            job.error_message = str(e)
            db.commit()
    finally:
        db.close()


@router.post("", response_model=GenerationJobOut)
def start_generation(
    payload: GenerationRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_rate_limit(f"generation:{current_user.id}", settings.generation_requests_per_hour)

    job = GenerationJob(user_id=current_user.id, raw_prompt=payload.prompt, status=JobStatus.pending)
    db.add(job)
    db.commit()
    db.refresh(job)

    from app.core.database import SessionLocal
    background_tasks.add_task(_run_generation_job, job.id, SessionLocal)

    return job


@router.get("/{job_id}", response_model=GenerationJobOut)
def get_generation_status(
    job_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    from fastapi import HTTPException
    job = db.get(GenerationJob, job_id)
    if not job or job.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Generation job not found.")
    return job
