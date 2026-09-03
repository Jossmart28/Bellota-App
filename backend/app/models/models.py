"""Modelos ORM de SQLAlchemy para la API Bellota."""
from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Float, DateTime, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base


class User(Base):
    """
    Modelo de usuario con soporte RBAC.

    Roles disponibles: 'admin', 'usuario', 'auditor'.
    """
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=False)
    role = Column(String, default="usuario")  # 'admin' | 'usuario' | 'auditor'
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=func.now())

    profile = relationship("UserProfile", back_populates="user", uselist=False)
    audit_logs = relationship("AuditLog", back_populates="actor", foreign_keys="AuditLog.user_id")


class AuditLog(Base):
    """
    Registro de auditoría que almacena todas las acciones del sistema.

    Usado por el rol Auditor para revisar el historial de actividad.
    """
    __tablename__ = "audit_logs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    action = Column(String, nullable=False, index=True)
    target_type = Column(String, nullable=True)   # 'user', 'profile', 'daily_log', etc.
    target_id = Column(Integer, nullable=True)
    details = Column(Text, nullable=True)          # JSON string con contexto adicional
    ip_address = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), default=func.now())

    actor = relationship("User", back_populates="audit_logs", foreign_keys=[user_id])


class UserProfile(Base):
    """Perfil extendido del usuario con datos de salud menstrual."""
    __tablename__ = "user_profiles"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=True)
    menstrual_cycle_duration = Column(Integer, default=28)
    menstruation_duration = Column(Integer, default=5)
    collection_product = Column(String, default="toalla_femenina")
    contraceptive = Column(String, nullable=True)
    age = Column(Integer, nullable=True)
    weight = Column(Float, nullable=True)
    weight_unit = Column(String, default="kg")
    breast_exam_reminder = Column(Boolean, default=False)
    privacy_policy_accepted = Column(Boolean, default=False)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now(), default=func.now())

    user = relationship("User", back_populates="profile")
    medications = relationship("AdditionalMedication", back_populates="user")


class AdditionalMedication(Base):
    """Medicamentos adicionales del usuario."""
    __tablename__ = "additional_medications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("user_profiles.id"))
    name = Column(String, index=True)
    category = Column(String, index=True)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now(), default=func.now())

    user = relationship("UserProfile", back_populates="medications")


class DailyLog(Base):
    """Registro diario de síntomas y datos del ciclo menstrual."""
    __tablename__ = "daily_logs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("user_profiles.id"))
    date = Column(String, index=True)  # YYYY-MM-DD
    period_start = Column(Boolean, default=False)
    period_end = Column(Boolean, default=False)
    sexual_intercourse = Column(Boolean, default=False)
    bleeding_intensity = Column(String, nullable=True)  # light, medium, heavy
    notes = Column(String, nullable=True)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now(), default=func.now())

    user = relationship("UserProfile")
