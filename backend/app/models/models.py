from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Float, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base

class UserProfile(Base):
    __tablename__ = "user_profiles"

    id = Column(Integer, primary_key=True, index=True)
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

    medications = relationship("AdditionalMedication", back_populates="user")

class AdditionalMedication(Base):
    __tablename__ = "additional_medications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("user_profiles.id"))
    name = Column(String, index=True)
    category = Column(String, index=True)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now(), default=func.now())

    user = relationship("UserProfile", back_populates="medications")

class DailyLog(Base):
    __tablename__ = "daily_logs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("user_profiles.id"))
    date = Column(String, index=True) # YYYY-MM-DD
    period_start = Column(Boolean, default=False)
    period_end = Column(Boolean, default=False)
    sexual_intercourse = Column(Boolean, default=False)
    bleeding_intensity = Column(String, nullable=True) # light, medium, heavy
    notes = Column(String, nullable=True)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now(), default=func.now())

    user = relationship("UserProfile")
