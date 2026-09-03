from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.auth import require_role
from app.crud import crud
from app.schemas import schemas
from app.models import models

router = APIRouter(
    prefix="/admin",
    tags=["Administración"],
    dependencies=[Depends(require_role("admin"))],
)

@router.get("/users", response_model=List[schemas.UserResponse])
def get_users(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Lista todos los usuarios (requiere rol admin)."""
    return crud.get_all_users(db, skip=skip, limit=limit)

@router.get("/users/{user_id}", response_model=schemas.UserResponse)
def get_user(user_id: int, db: Session = Depends(get_db)):
    """Obtiene detalles de un usuario específico."""
    user = crud.get_user_by_id(db, user_id=user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    return user

@router.put("/users/{user_id}/role", response_model=schemas.UserResponse)
def update_user_role(
    user_id: int,
    role_update: schemas.RoleUpdate,
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(require_role("admin"))
):
    """Cambia el rol de un usuario."""
    user = crud.update_user_role(db, user_id=user_id, new_role=role_update.role)
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    
    crud.create_audit_log(
        db,
        user_id=current_admin.id,
        action="role_change",
        target_type="user",
        target_id=user_id,
        details={"new_role": role_update.role}
    )
    return user

@router.put("/users/{user_id}/status", response_model=schemas.UserResponse)
def update_user_status(
    user_id: int,
    status_update: schemas.StatusUpdate,
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(require_role("admin"))
):
    """Activa o suspende un usuario."""
    if user_id == current_admin.id and not status_update.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No puedes suspender tu propia cuenta."
        )
        
    user = crud.toggle_user_active(db, user_id=user_id, is_active=status_update.is_active)
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
        
    action = "user_reactivate" if status_update.is_active else "user_suspend"
    crud.create_audit_log(
        db,
        user_id=current_admin.id,
        action=action,
        target_type="user",
        target_id=user_id,
    )
    return user

@router.delete("/users/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(require_role("admin"))
):
    """Elimina permanentemente un usuario."""
    if user_id == current_admin.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No puedes eliminar tu propia cuenta."
        )
        
    success = crud.delete_user(db, user_id=user_id)
    if not success:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
        
    crud.create_audit_log(
        db,
        user_id=current_admin.id,
        action="user_delete",
        target_type="user",
        target_id=user_id,
    )
