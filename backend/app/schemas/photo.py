from datetime import datetime
from pydantic import BaseModel, ConfigDict

class PhotoResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    report_id: int
    photo_type: str
    file_path: str
    created_at: datetime
