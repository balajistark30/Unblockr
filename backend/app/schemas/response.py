from pydantic import BaseModel
from typing import List, Optional


class FinalReportResponse(BaseModel):
    success: bool
    is_blocked: bool
    confidence: float
    blocked_vehicle: Optional[str]
    blocking_vehicles: List[str]
    issue_type: Optional[str] = None
    selected_vehicle: Optional[str] = None
    entered_plates: List[str]
    image_count: int