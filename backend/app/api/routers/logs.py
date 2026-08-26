from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.crud import crud
from app.schemas import schemas
from app.core.database import get_db

router = APIRouter(
    prefix="/logs",
    tags=["logs"],
)

@router.get("/{user_id}/{date}", response_model=schemas.DailyLogResponse)
def read_daily_log(user_id: int, date: str, db: Session = Depends(get_db)):
    # Verify if user exists
    db_profile = crud.get_profile(db, user_id=user_id)
    if db_profile is None:
        raise HTTPException(status_code=404, detail="Profile not found")
    
    db_log = crud.get_daily_log(db, user_id=user_id, date=date)
    if db_log is None:
        raise HTTPException(status_code=404, detail="Log not found for this date")
    return db_log

@router.post("/{user_id}", response_model=schemas.DailyLogResponse)
def save_daily_log(user_id: int, log: schemas.DailyLogCreate, db: Session = Depends(get_db)):
    db_profile = crud.get_profile(db, user_id=user_id)
    if db_profile is None:
        raise HTTPException(status_code=404, detail="Profile not found")
    
    return crud.create_or_update_daily_log(db=db, user_id=user_id, log=log)
