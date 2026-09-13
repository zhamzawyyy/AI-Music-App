from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.models import User, Track
from app.schemas.schemas import TrackOut

router = APIRouter(prefix="/library", tags=["library"])


@router.get("", response_model=list[TrackOut])
def list_my_tracks(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return (
        db.query(Track)
        .filter(Track.owner_id == current_user.id)
        .order_by(Track.created_at.desc())
        .all()
    )


@router.delete("/{track_id}", status_code=204)
def delete_track(track_id: str, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    track = db.get(Track, track_id)
    if not track or track.owner_id != current_user.id:
        raise HTTPException(status_code=404, detail="Track not found.")
    db.delete(track)
    db.commit()
