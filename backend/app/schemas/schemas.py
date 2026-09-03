"""Esquemas Pydantic para la API Bellota."""
from pydantic import BaseModel, Field, EmailStr
from typing import List, Optional, Literal, Any, Dict
from datetime import datetime

# ── Auth ───────────────────────────────────────────────────────────────────────

class UserCreate(BaseModel):
    """Datos para registrar un nuevo usuario."""
    name: str = Field(..., min_length=2, max_length=100)
    email: str = Field(..., min_length=5)
    password: str = Field(..., min_length=6)
    role: Optional[Literal["usuario", "admin", "auditor"]] = "usuario"


class UserLogin(BaseModel):
    """Credenciales para inicio de sesión."""
    email: str
    password: str


class UserResponse(BaseModel):
    """Datos públicos del usuario (sin contraseña)."""
    id: int
    name: str
    email: str
    role: str
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


class TokenResponse(BaseModel):
    """Respuesta del endpoint de login."""
    access_token: str
    token_type: str = "bearer"
    role: str
    user_id: int
    name: str


class RoleUpdate(BaseModel):
    """Payload para cambiar el rol de un usuario."""
    role: Literal["usuario", "admin", "auditor"]


class StatusUpdate(BaseModel):
    """Payload para suspender/reactivar un usuario."""
    is_active: bool


# ── Audit Logs ─────────────────────────────────────────────────────────────────

class AuditLogCreate(BaseModel):
    """Datos para crear un registro de auditoría."""
    action: str
    target_type: Optional[str] = None
    target_id: Optional[int] = None
    details: Optional[Dict[str, Any]] = None
    ip_address: Optional[str] = None


class AuditLogResponse(BaseModel):
    """Respuesta de un registro de auditoría."""
    id: int
    user_id: Optional[int]
    action: str
    target_type: Optional[str]
    target_id: Optional[int]
    details: Optional[str]
    ip_address: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True


class AuditStatsResponse(BaseModel):
    """Estadísticas de auditoría."""
    total_logs: int
    today_logs: int
    failed_logins: int
    role_changes: int
    suspensions: int
    deletions: int


# ── Medicamentos ───────────────────────────────────────────────────────────────

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


# ── Perfil de usuario ──────────────────────────────────────────────────────────

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


# ── Registro diario ────────────────────────────────────────────────────────────

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
