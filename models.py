import uuid
from datetime import datetime, timezone

from sqlalchemy import Column, String, DateTime, ForeignKey, Text, Boolean, Enum
from sqlalchemy.orm import relationship
import enum

from app.core.database import Base


def _uuid():
    return str(uuid.uuid4())


class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, default=_uuid)
    name = Column(String, nullable=False)
    email = Column(String, unique=True, nullable=False, index=True)
    password_hash = Column(String, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    tracks = relationship("Track", back_populates="owner")
    jobs = relationship("GenerationJob", back_populates="user")


class TrackSource(str, enum.Enum):
    ai_generated = "ai_generated"
    uploaded = "uploaded"


class Track(Base):
    __tablename__ = "tracks"

    id = Column(String, primary_key=True, default=_uuid)
    owner_id = Column(String, ForeignKey("users.id"), nullable=False)
    title = Column(String, nullable=False)
    prompt = Column(Text, nullable=True)  # original prompt, if AI-generated
    source = Column(Enum(TrackSource), default=TrackSource.ai_generated)
    audio_url = Column(String, nullable=True)
    duration_seconds = Column(String, nullable=True)
    is_ai_generated = Column(Boolean, default=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    owner = relationship("User", back_populates="tracks")


class JobStatus(str, enum.Enum):
    pending = "pending"
    running = "running"
    completed = "completed"
    failed = "failed"


class GenerationJob(Base):
    __tablename__ = "generation_jobs"

    id = Column(String, primary_key=True, default=_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    raw_prompt = Column(Text, nullable=False)
    refined_prompt = Column(Text, nullable=True)
    status = Column(Enum(JobStatus), default=JobStatus.pending)
    result_track_id = Column(String, ForeignKey("tracks.id"), nullable=True)
    error_message = Column(Text, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="jobs")
