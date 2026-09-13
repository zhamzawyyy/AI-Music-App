from datetime import datetime
from typing import Optional
from pydantic import BaseModel, EmailStr, Field


# ---- Auth ----
class RegisterRequest(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class UserOut(BaseModel):
    id: str
    name: str
    email: EmailStr

    class Config:
        from_attributes = True


# ---- Generation ----
class GenerationRequest(BaseModel):
    prompt: str = Field(min_length=3, max_length=500)


class GenerationJobOut(BaseModel):
    id: str
    status: str
    raw_prompt: str
    refined_prompt: Optional[str] = None
    result_track_id: Optional[str] = None
    error_message: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


# ---- Library ----
class TrackOut(BaseModel):
    id: str
    title: str
    prompt: Optional[str] = None
    is_ai_generated: bool
    audio_url: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True
