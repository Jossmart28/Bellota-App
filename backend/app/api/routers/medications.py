from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.crud import crud
from app.schemas import schemas
from app.core.database import get_db

router = APIRouter(
    prefix="/medications",
    tags=["medications"],
)

@router.get("/{user_id}", response_model=List[schemas.MedicationResponse])
def read_medications(user_id: int, db: Session = Depends(get_db)):
    # Verify if user exists first
    db_profile = crud.get_profile(db, user_id=user_id)
    if db_profile is None:
        raise HTTPException(status_code=404, detail="Profile not found")
    
    return crud.get_medications(db, user_id=user_id)

@router.post("/{user_id}", response_model=schemas.MedicationResponse)
def add_medication(user_id: int, medication: schemas.MedicationCreate, db: Session = Depends(get_db)):
    db_profile = crud.get_profile(db, user_id=user_id)
    if db_profile is None:
        raise HTTPException(status_code=404, detail="Profile not found")
    
    return crud.add_medication(db=db, user_id=user_id, medication=medication)

@router.delete("/{med_id}")
def remove_medication(med_id: int, db: Session = Depends(get_db)):
    success = crud.delete_medication(db=db, med_id=med_id)
    if not success:
        raise HTTPException(status_code=404, detail="Medication not found")
    return {"message": "Medication deleted successfully"}
