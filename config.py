"""
Application settings, loaded from environment variables only.
Never hardcode API keys or secrets here -- see .env.example.
"""
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # Core
    app_name: str = "AI Music App API"
    environment: str = "development"

    # Database
    database_url: str = "sqlite:///./app.db"

    # Auth
    jwt_secret_key: str = "change-me-in-.env"  # override in real deployments
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 14

    # Third-party APIs (never exposed to the mobile client)
    openai_api_key: str = ""
    modelslab_api_key: str = ""
    audio_id_api_key: str = ""  # ACRCloud / AudD

    # Rate limiting
    generation_requests_per_hour: int = 10
    recognition_requests_per_hour: int = 30


settings = Settings()
