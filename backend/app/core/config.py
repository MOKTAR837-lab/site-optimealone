from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field, AliasChoices

class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
        case_sensitive=False,
    )

    database_url: str = Field(validation_alias=AliasChoices("DB_DSN", "DATABASE_URL"))
    cors_origins: str = Field(
        default="http://localhost:4321,http://127.0.0.1:4321",
        validation_alias=AliasChoices("CORS_ORIGINS"),
    )

    redis_url: str | None = Field(default=None, validation_alias=AliasChoices("REDIS_URL"))
    supabase_url: str | None = Field(default=None, validation_alias=AliasChoices("SUPABASE_URL"))
    supabase_service_role_key: str | None = Field(default=None, validation_alias=AliasChoices("SUPABASE_SERVICE_ROLE_KEY"))
    supabase_jwt_secret: str | None = Field(default=None, validation_alias=AliasChoices("SUPABASE_JWT_SECRET"))
    ollama_url: str | None = Field(default=None, validation_alias=AliasChoices("OLLAMA_URL"))
    api_secret_key: str | None = Field(default=None, validation_alias=AliasChoices("API_SECRET_KEY"))

settings = Settings()
