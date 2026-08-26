from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime

class MedicationBase(BaseModel):
    name: str
    category: str

class MedicationCreate(MedicationBase):
    pass

class MedicationResponse(MedicationBase):
    id: int
    user_id: int
    updated_at: datetime

    class Config:
        from_attributes = True

class UserProfileBase(BaseModel):
    menstrual_cycle_duration: Optional[int] = Field(28, ge=1, le=42, description="Días entre periodos")
    menstruation_duration: Optional[int] = Field(5, ge=1, le=10, description="Días de sangrado")
    collection_product: Optional[str] = "toalla_femenina"
    contraceptive: Optional[str] = None
    age: Optional[int] = Field(None, ge=1, le=100)
    weight: Optional[float] = None
    weight_unit: Optional[str] = "kg"
    breast_exam_reminder: Optional[bool] = False
    privacy_policy_accepted: Optional[bool] = False

class UserProfileCreate(UserProfileBase):
    pass

class UserProfileResponse(UserProfileBase):
    id: int
    updated_at: datetime
    medications: List[MedicationResponse] = []

    class Config:
        from_attributes = True

class DailyLogBase(BaseModel):
    date: str
    period_start: Optional[bool] = False
    period_end: Optional[bool] = False
    sexual_intercourse: Optional[bool] = False
    bleeding_intensity: Optional[str] = None
    notes: Optional[str] = None

class DailyLogCreate(DailyLogBase):
    pass

class DailyLogResponse(DailyLogBase):
    id: int
    user_id: int
    updated_at: datetime

    class Config:
        from_attributes = True
