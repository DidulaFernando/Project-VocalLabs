from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    app_name: str = "Speech Evaluation API"
    app_version: str = "1.0.0"
    upload_dir: str = "temp_uploads"
    allowed_extensions: list = ["wav", "mp3", "m4a", "ogg"]
    max_file_size: int = 20_000_000  # 20MB in bytes

settings = Settings()
