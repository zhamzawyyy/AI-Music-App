from fastapi import APIRouter, Depends, UploadFile, File, HTTPException

from app.core.rate_limit import enforce_rate_limit
from app.core.config import settings
from app.api.deps import get_current_user
from app.models.models import User
from app.services.audio_id_client import identify_audio_clip, RecognitionError

router = APIRouter(prefix="/recognition", tags=["recognition"])

MAX_CLIP_BYTES = 5 * 1024 * 1024  # 5 MB cap -- short clips only


@router.post("/identify")
async def identify(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
):
    enforce_rate_limit(f"recognition:{current_user.id}", settings.recognition_requests_per_hour)

    audio_bytes = await file.read()
    if len(audio_bytes) > MAX_CLIP_BYTES:
        raise HTTPException(status_code=413, detail="Clip too large. Keep identification clips short.")

    try:
        result = await identify_audio_clip(audio_bytes)
    except RecognitionError as e:
        raise HTTPException(status_code=502, detail=str(e))

    return result
