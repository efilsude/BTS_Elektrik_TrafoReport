import os
import secrets
from typing import List, Optional
from pydantic_settings import BaseSettings, SettingsConfigDict

# SECRET_KEY must come from the environment in any real deployment. There is
# intentionally NO hardcoded fallback value here: a fixed default that ships
# in the repo (and in .env.example) would let anyone forge valid JWTs against
# any deployment that forgot to set SECRET_KEY. If it's missing, we generate
# a random key for this process only — good enough for local/dev/test runs
# (tokens just won't survive a restart), but it forces production deployments
# to set a real, persistent SECRET_KEY or accept that every deploy invalidates
# all sessions.
_SECRET_KEY_ENV = os.getenv("SECRET_KEY")
if not _SECRET_KEY_ENV:
    import warnings
    warnings.warn(
        "SECRET_KEY ortam değişkeni ayarlanmamış! Bu süreç için rastgele "
        "geçici bir anahtar üretildi (sunucu her yeniden başladığında tüm "
        "JWT'ler geçersiz olur). Üretimde .env dosyasında sabit bir "
        "SECRET_KEY MUTLAKA ayarlanmalıdır.",
        RuntimeWarning,
        stacklevel=2,
    )
    _SECRET_KEY_ENV = secrets.token_hex(32)

class Settings(BaseSettings):
    PROJECT_NAME: str = "TrafoReport API"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    SECRET_KEY: str = _SECRET_KEY_ENV
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 1 day access token
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7  # 7 days refresh token
    
    INVITE_CODE_TTL_MINUTES: int = 15
    VERIFICATION_CODE_TTL_MINUTES: int = 10
    
    # SMTP & Email settings
    SMTP_HOST: str = os.getenv("SMTP_HOST", "localhost")
    SMTP_PORT: int = int(os.getenv("SMTP_PORT", "587"))
    SMTP_USER: Optional[str] = os.getenv("SMTP_USER", None)
    SMTP_PASSWORD: Optional[str] = os.getenv("SMTP_PASSWORD", None)
    SMTP_FROM: str = os.getenv("SMTP_FROM", "TrafoReport <noreply@btselektrik.com>")
    SMTP_USE_TLS: bool = os.getenv("SMTP_USE_TLS", "true").lower() in ("true", "1", "yes")
    ADMIN_NOTIFY_EMAILS: Optional[str] = os.getenv("ADMIN_NOTIFY_EMAILS", None)
    EMAIL_ENABLED: bool = os.getenv("EMAIL_ENABLED", "false").lower() in ("true", "1", "yes")


    # SQLite fallback for local testing if DATABASE_URL is not provided
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL", "sqlite:///./traforeport.db"
    )
    
    # Virgülle ayrılmış origin listesi, örn: "https://app.btselektrik.com,https://admin.btselektrik.com"
    # Ortam değişkeni verilmezse dahili/dev kullanım için "*" varsayılanına düşer.
    # Üretimde MUTLAKA spesifik origin(ler) ile daraltılmalıdır.
    BACKEND_CORS_ORIGINS: List[str] = (
        [o.strip() for o in os.getenv("BACKEND_CORS_ORIGINS", "*").split(",") if o.strip()]
    )
    
    UPLOAD_DIR: str = os.getenv("UPLOAD_DIR", "uploads")

    # Kesinleştirilen (finalize) raporların üretilen .xlsx dosyalarının
    # kaydedildiği dizin. docs/API_CONTRACT.md ve docs/DECISIONS.md'de
    # "uploads/reports/" olarak dokümante edilmiştir (fotoğraf/şablon
    # yükleme dizinleriyle aynı UPLOAD_DIR kökü altında). Önceden bu alan
    # burada tanımlı değildi; app/services/excel_engine.py doğrudan
    # settings.EXPORT_DIR'a erişiyordu ve bu, her finalize/download
    # çağrısında AttributeError ile başarısız oluyordu.
    EXPORT_DIR: str = os.getenv(
        "EXPORT_DIR", os.path.join(os.getenv("UPLOAD_DIR", "uploads"), "reports")
    )
    
    model_config = SettingsConfigDict(case_sensitive=True)

settings = Settings()
