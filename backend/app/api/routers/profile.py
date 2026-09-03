from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.crud import crud
from app.schemas import schemas
from app.core.database import get_db
from app.core.auth import get_current_active_user
from app.models import models

router = APIRouter(
    prefix="/profile",
    tags=["profile"],
)

def check_ownership_or_admin(user_id: int, current_user: models.User, allow_auditor: bool = False):
    """Verifica si el usuario tiene permiso para acceder a este recurso."""
    if current_user.id == user_id:
        return True
    if current_user.role == "admin":
        return True
    if allow_auditor and current_user.role == "auditor":
        return True
    
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail="No tienes permiso para acceder a este perfil."
    )

@router.get("/{user_id}", response_model=schemas.UserProfileResponse)
def read_profile(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    check_ownership_or_admin(user_id, current_user, allow_auditor=True)
    db_profile = crud.get_profile(db, user_id=user_id)
    if db_profile is None:
        raise HTTPException(status_code=404, detail="Profile not found")
    return db_profile

@router.put("/{user_id}", response_model=schemas.UserProfileResponse)
def update_profile(
    user_id: int,
    profile: schemas.UserProfileCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    check_ownership_or_admin(user_id, current_user, allow_auditor=False)
    db_profile = crud.update_profile(db=db, user_id=user_id, profile=profile)
    if db_profile is None:
        raise HTTPException(status_code=404, detail="Profile not found")
    
    crud.create_audit_log(
        db,
        user_id=current_user.id,
        action="profile_update",
        target_type="profile",
        target_id=db_profile.id
    )
    return db_profile
