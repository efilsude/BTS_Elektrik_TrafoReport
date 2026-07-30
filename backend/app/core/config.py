import os
from typing import List, Optional
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    PROJECT_NAME: str = "TrafoReport API"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    SECRET_KEY: str = os.getenv("SECRET_KEY", "b3a726f1c8e94a52d0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 1 day access token
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7  # 7 days refresh token
    
    INVITE_CODE_TTL_MINUTES: int = 15
    
    # SQLite fallback for local testing if DATABASE_URL is not provided
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL", "sqlite:///./traforeport.db"
    )
    
    BACKEND_CORS_ORIGINS: List[str] = ["*"]
    
    UPLOAD_DIR: str = os.getenv("UPLOAD_DIR", "uploads")
    
    model_config = SettingsConfigDict(case_sensitive=True)

settings = Settings()

