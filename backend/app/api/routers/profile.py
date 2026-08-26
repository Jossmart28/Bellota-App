from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.crud import crud
from app.schemas import schemas
from app.core.database import get_db

router = APIRouter(
    prefix="/profile",
    tags=["profile"],
)

@router.get("/{user_id}", response_model=schemas.UserProfileResponse)
def read_profile(user_id: int, db: Session = Depends(get_db)):
    db_profile = crud.get_profile(db, user_id=user_id)
    if db_profile is None:
        raise HTTPException(status_code=404, detail="Profile not found")
    return db_profile

@router.post("/", response_model=schemas.UserProfileResponse)
def create_profile(profile: schemas.UserProfileCreate, db: Session = Depends(get_db)):
    return crud.create_profile(db=db, profile=profile)

@router.put("/{user_id}", response_model=schemas.UserProfileResponse)
def update_profile(user_id: int, profile: schemas.UserProfileCreate, db: Session = Depends(get_db)):
    db_profile = crud.update_profile(db=db, user_id=user_id, profile=profile)
    if db_profile is None:
        raise HTTPException(status_code=404, detail="Profile not found")
    return db_profile
