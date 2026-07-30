from typing import Dict, List
from pydantic import BaseModel

class UserReportCount(BaseModel):
    creator_display_name: str
    count: int

class AdminStatsResponse(BaseModel):
    total_reports: int
    draft_reports: int
    final_reports: int
    reports_by_type: Dict[str, int]
    reports_by_user: List[UserReportCount]
    total_active_users: int
    active_invite_codes: int
