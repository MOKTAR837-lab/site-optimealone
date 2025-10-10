from __future__ import annotations
import json
from typing import List, Optional

from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import field_validator

class Settings(BaseSettings):
    # Projet / API
    PROJECT_NAME: str = "OptimealHealth"
    API_V1: str = "/api/v1"

    # Base de données (ASYNC !)
    # valeur par défaut cohérente avec ton docker-compose (postgres/postgres)
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@db:5432/optimeal"

    # Sécurité & Auth
    API_KEY: Optional[str] = None
    JWT_SECRET: str = "change-me"
    JWT_ALG: str = "HS256"
    JWT_EXPIRE_MIN: int = 60

    # CORS
    # Accepte: liste Python, JSON string '["*","http://localhost:4321"]' ou '*,http://localhost:4321'
    ALLOW_ORIGINS: List[str] = ["*"]

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    @field_validator("ALLOW_ORIGINS", mode="before")
    @classmethod
    def _parse_allow_origins(cls, v):
        if v is None or v == "":
            return ["*"]
        if isinstance(v, str):
            s = v.strip()
            if s.startswith("["):  # JSON list
                try:
                    data = json.loads(s)
                    if isinstance(data, list):
                        return [str(x) for x in data]
                except Exception:
                    pass
            return [part.strip() for part in s.split(",") if part.strip()]
        return v

settings = Settings()