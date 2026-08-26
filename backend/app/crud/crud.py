from sqlalchemy.orm import Session
from app.models import models
from app.schemas import schemas

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

def get_medications(db: Session, user_id: int):
    return db.query(models.AdditionalMedication).filter(models.AdditionalMedication.user_id == user_id).all()

def add_medication(db: Session, user_id: int, medication: schemas.MedicationCreate):
    db_med = models.AdditionalMedication(**medication.model_dump(), user_id=user_id)
    db.add(db_med)
    db.commit()
    db.refresh(db_med)
    return db_med

def delete_medication(db: Session, med_id: int):
    db_med = db.query(models.AdditionalMedication).filter(models.AdditionalMedication.id == med_id).first()
    if db_med:
        db.delete(db_med)
        db.commit()
        return True
    return False

def get_daily_log(db: Session, user_id: int, date: str):
    return db.query(models.DailyLog).filter(models.DailyLog.user_id == user_id, models.DailyLog.date == date).first()

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
