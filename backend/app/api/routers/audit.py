from typing import List, Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.auth import require_role
from app.crud import crud
from app.schemas import schemas
from app.models import models

router = APIRouter(
    prefix="/audit",
    tags=["Auditoría"],
    dependencies=[Depends(require_role("admin", "auditor"))],
)

@router.get("/logs", response_model=List[schemas.AuditLogResponse])
def get_audit_logs(
    user_id: Optional[int] = Query(None, description="Filtrar por ID de usuario"),
    action: Optional[str] = Query(None, description="Filtrar por tipo de acción"),
    target_type: Optional[str] = Query(None, description="Filtrar por recurso afectado"),
    start_date: Optional[str] = Query(None, description="Formato YYYY-MM-DD"),
    end_date: Optional[str] = Query(None, description="Formato YYYY-MM-DD"),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=1000),
    db: Session = Depends(get_db)
):
    """Consulta el historial de logs de auditoría."""
    return crud.get_audit_logs(
        db,
        user_id=user_id,
        action=action,
        target_type=target_type,
        start_date=start_date,
        end_date=end_date,
        skip=skip,
        limit=limit,
    )

@router.get("/stats", response_model=schemas.AuditStatsResponse)
def get_audit_stats(db: Session = Depends(get_db)):
    """Obtiene estadísticas generales de auditoría (para dashboards)."""
    return crud.get_audit_stats(db)
