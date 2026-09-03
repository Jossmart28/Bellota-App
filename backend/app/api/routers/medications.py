from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.crud import crud
from app.schemas import schemas
from app.core.database import get_db
from app.core.auth import get_current_active_user
from app.models import models
from app.api.routers.profile import check_ownership_or_admin

router = APIRouter(
    prefix="/medications",
    tags=["medications"],
)

@router.get("/{user_id}", response_model=List[schemas.MedicationResponse])
def read_medications(
    user_id: int, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    check_ownership_or_admin(user_id, current_user, allow_auditor=True)
    
    db_profile = crud.get_profile(db, user_id=user_id)
    if db_profile is None:
        raise HTTPException(status_code=404, detail="Profile not found")
    
    return crud.get_medications(db, user_id=user_id)

@router.post("/{user_id}", response_model=schemas.MedicationResponse)
def add_medication(
    user_id: int, 
    medication: schemas.MedicationCreate, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    check_ownership_or_admin(user_id, current_user, allow_auditor=False)
    
    db_profile = crud.get_profile(db, user_id=user_id)
    if db_profile is None:
        raise HTTPException(status_code=404, detail="Profile not found")
    
    db_med = crud.add_medication(db=db, user_id=user_id, medication=medication)
    
    crud.create_audit_log(
        db,
        user_id=current_user.id,
        action="medication_add",
        target_type="medication",
        target_id=db_med.id
    )
    
    return db_med

@router.delete("/{med_id}")
def remove_medication(
    med_id: int, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    # Need to check ownership first
    db_med = db.query(models.AdditionalMedication).filter(models.AdditionalMedication.id == med_id).first()
    if not db_med:
        raise HTTPException(status_code=404, detail="Medication not found")
    
    # db_med.user_id is actually the user_profile.id, which maps to users.id
    check_ownership_or_admin(db_med.user_id, current_user, allow_auditor=False)
    
    success = crud.delete_medication(db=db, med_id=med_id)
    if not success:
        raise HTTPException(status_code=404, detail="Medication not found")
        
    crud.create_audit_log(
        db,
        user_id=current_user.id,
        action="medication_delete",
        target_type="medication",
        target_id=med_id
    )
    
    return {"message": "Medication deleted successfully"}
