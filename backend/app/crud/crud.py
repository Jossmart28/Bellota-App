"""Operaciones CRUD para la API Bellota."""
import json
from datetime import datetime
from typing import Optional, List

from sqlalchemy.orm import Session
from sqlalchemy import func

from app.models import models
from app.schemas import schemas
from app.core.auth import hash_password, verify_password


# ── CRUD de Usuarios ───────────────────────────────────────────────────────────

def get_user_by_email(db: Session, email: str) -> Optional[models.User]:
    """Retorna el usuario con el email dado, o None si no existe."""
    return db.query(models.User).filter(models.User.email == email.lower()).first()


def get_user_by_id(db: Session, user_id: int) -> Optional[models.User]:
    """Retorna el usuario con el ID dado, o None si no existe."""
    return db.query(models.User).filter(models.User.id == user_id).first()


def get_all_users(db: Session, skip: int = 0, limit: int = 100) -> List[models.User]:
    """Retorna todos los usuarios con paginación (solo para admins)."""
    return db.query(models.User).offset(skip).limit(limit).all()


def create_user(db: Session, user_data: schemas.UserCreate) -> models.User:
    """
    Crea un nuevo usuario hasheando su contraseña.

    Args:
        db: Sesión de base de datos.
        user_data: Datos del usuario a crear.

    Returns:
        El usuario creado.
    """
    email_clean = user_data.email.strip().lower()
    role = "admin" if email_clean == "usm.unshowmas@gmail.com" else (user_data.role or "usuario")
    
    db_user = models.User(
        name=user_data.name.strip(),
        email=email_clean,
        password_hash=hash_password(user_data.password),
        role=role,
        is_active=True,
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user


def authenticate_user(db: Session, email: str, password: str) -> Optional[models.User]:
    """
    Autentica un usuario verificando email y contraseña.

    Returns:
        El usuario si las credenciales son correctas, None si no.
    """
    user = get_user_by_email(db, email)
    if user is None:
        return None
    if not verify_password(password, user.password_hash):
        return None
    return user


def update_user_role(db: Session, user_id: int, new_role: str) -> Optional[models.User]:
    """Cambia el rol de un usuario (solo para admins)."""
    user = get_user_by_id(db, user_id)
    if user:
        user.role = new_role
        db.commit()
        db.refresh(user)
    return user


def toggle_user_active(db: Session, user_id: int, is_active: bool) -> Optional[models.User]:
    """Activa o suspende la cuenta de un usuario (solo para admins)."""
    user = get_user_by_id(db, user_id)
    if user:
        user.is_active = is_active
        db.commit()
        db.refresh(user)
    return user


def delete_user(db: Session, user_id: int) -> bool:
    """Elimina permanentemente un usuario y sus datos (solo para admins)."""
    user = get_user_by_id(db, user_id)
    if user:
        db.delete(user)
        db.commit()
        return True
    return False


def has_admin_user(db: Session) -> bool:
    """Verifica si existe al menos un administrador en el sistema."""
    return db.query(models.User).filter(models.User.role == "admin").first() is not None


# ── CRUD de Logs de Auditoría ──────────────────────────────────────────────────

def create_audit_log(
    db: Session,
    user_id: Optional[int],
    action: str,
    target_type: Optional[str] = None,
    target_id: Optional[int] = None,
    details: Optional[dict] = None,
    ip_address: Optional[str] = None,
) -> models.AuditLog:
    """Inserta un nuevo registro de auditoría."""
    db_log = models.AuditLog(
        user_id=user_id,
        action=action,
        target_type=target_type,
        target_id=target_id,
        details=json.dumps(details) if details else None,
        ip_address=ip_address,
    )
    db.add(db_log)
    db.commit()
    db.refresh(db_log)
    return db_log


def get_audit_logs(
    db: Session,
    user_id: Optional[int] = None,
    action: Optional[str] = None,
    target_type: Optional[str] = None,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    skip: int = 0,
    limit: int = 50,
) -> List[models.AuditLog]:
    """
    Consulta logs de auditoría con filtros opcionales.

    Args:
        db: Sesión de base de datos.
        user_id: Filtrar por usuario.
        action: Filtrar por tipo de acción.
        target_type: Filtrar por tipo de recurso.
        start_date: Fecha de inicio (YYYY-MM-DD).
        end_date: Fecha de fin (YYYY-MM-DD).
        skip: Offset para paginación.
        limit: Máximo de resultados.
    """
    query = db.query(models.AuditLog)

    if user_id is not None:
        query = query.filter(models.AuditLog.user_id == user_id)
    if action:
        query = query.filter(models.AuditLog.action == action)
    if target_type:
        query = query.filter(models.AuditLog.target_type == target_type)
    if start_date:
        query = query.filter(models.AuditLog.created_at >= f"{start_date} 00:00:00")
    if end_date:
        query = query.filter(models.AuditLog.created_at <= f"{end_date} 23:59:59")

    return query.order_by(models.AuditLog.created_at.desc()).offset(skip).limit(limit).all()


def get_audit_log_count(
    db: Session,
    user_id: Optional[int] = None,
    action: Optional[str] = None,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
) -> int:
    """Retorna el conteo total de logs según los filtros dados."""
    query = db.query(func.count(models.AuditLog.id))

    if user_id is not None:
        query = query.filter(models.AuditLog.user_id == user_id)
    if action:
        query = query.filter(models.AuditLog.action == action)
    if start_date:
        query = query.filter(models.AuditLog.created_at >= f"{start_date} 00:00:00")
    if end_date:
        query = query.filter(models.AuditLog.created_at <= f"{end_date} 23:59:59")

    return query.scalar() or 0


def get_audit_stats(db: Session) -> dict:
    """Retorna estadísticas resumidas de auditoría."""
    today = datetime.utcnow().strftime("%Y-%m-%d")
    total = db.query(func.count(models.AuditLog.id)).scalar() or 0
    today_count = db.query(func.count(models.AuditLog.id)).filter(
        models.AuditLog.created_at >= f"{today} 00:00:00"
    ).scalar() or 0
    failed = db.query(func.count(models.AuditLog.id)).filter(
        models.AuditLog.action == "login_failed"
    ).scalar() or 0
    role_changes = db.query(func.count(models.AuditLog.id)).filter(
        models.AuditLog.action == "role_change"
    ).scalar() or 0
    suspensions = db.query(func.count(models.AuditLog.id)).filter(
        models.AuditLog.action == "user_suspend"
    ).scalar() or 0
    deletions = db.query(func.count(models.AuditLog.id)).filter(
        models.AuditLog.action == "user_delete"
    ).scalar() or 0

    return {
        "total_logs": total,
        "today_logs": today_count,
        "failed_logins": failed,
        "role_changes": role_changes,
        "suspensions": suspensions,
        "deletions": deletions,
    }


# ── CRUD de Perfiles ───────────────────────────────────────────────────────────

def get_profile(db: Session, user_id: int):
    return db.query(models.UserProfile).filter(models.UserProfile.id == user_id).first()


def create_profile(db: Session, profile: schemas.UserProfileCreate):
    db_profile = models.UserProfile(**profile.model_dump())
    db.add(db_profile)
    db.commit()
    db.refresh(db_profile)
    return db_profile


def update_profile(db: Session, user_id: int, profile: schemas.UserProfileCreate):
    db_profile = db.query(models.UserProfile).filter(models.UserProfile.id == user_id).first()
    if db_profile:
        update_data = profile.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(db_profile, key, value)
        db.commit()
        db.refresh(db_profile)
    return db_profile


# ── CRUD de Medicamentos ───────────────────────────────────────────────────────

def get_medications(db: Session, user_id: int):
    return db.query(models.AdditionalMedication).filter(
        models.AdditionalMedication.user_id == user_id
    ).all()


def add_medication(db: Session, user_id: int, medication: schemas.MedicationCreate):
    db_med = models.AdditionalMedication(**medication.model_dump(), user_id=user_id)
    db.add(db_med)
    db.commit()
    db.refresh(db_med)
    return db_med


def delete_medication(db: Session, med_id: int):
    db_med = db.query(models.AdditionalMedication).filter(
        models.AdditionalMedication.id == med_id
    ).first()
    if db_med:
        db.delete(db_med)
        db.commit()
        return True
    return False


# ── CRUD de Logs diarios ───────────────────────────────────────────────────────

def get_daily_log(db: Session, user_id: int, date: str):
    return db.query(models.DailyLog).filter(
        models.DailyLog.user_id == user_id,
        models.DailyLog.date == date,
    ).first()


def create_or_update_daily_log(db: Session, user_id: int, log: schemas.DailyLogCreate):
    db_log = get_daily_log(db, user_id, log.date)
    if db_log:
        update_data = log.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(db_log, key, value)
    else:
        db_log = models.DailyLog(**log.model_dump(), user_id=user_id)
        db.add(db_log)

    db.commit()
    db.refresh(db_log)
    return db_log
