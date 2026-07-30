from datetime import datetime
from pydantic import BaseModel, ConfigDict

class TemplateResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    report_type: str
    file_path: str
    version: str
    uploaded_at: datetime
