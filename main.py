from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.core.database import Base, engine
from app.models import models  # noqa: F401 -- ensures models are registered before create_all
from app.api import auth, generation, library, recognition

Base.metadata.create_all(bind=engine)

app = FastAPI(title=settings.app_name)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # tighten this to your app's origin(s) in production
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(generation.router)
app.include_router(library.router)
app.include_router(recognition.router)


@app.get("/health")
def health_check():
    return {"status": "ok", "app": settings.app_name}
