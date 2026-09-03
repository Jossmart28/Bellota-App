from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.auth import (
    create_access_token,
    get_current_active_user,
)
from app.crud import crud
from app.schemas import schemas
from app.models import models

router = APIRouter(prefix="/auth", tags=["Autenticación"])


@router.post("/register", response_model=schemas.UserResponse, status_code=status.HTTP_201_CREATED)
def register(user_in: schemas.UserCreate, db: Session = Depends(get_db)):
    """Registra un nuevo usuario."""
    if crud.get_user_by_email(db, email=user_in.email):
        raise HTTPException(
            status_code=400,
            detail="El correo electrónico ya está registrado.",
        )
    user = crud.create_user(db, user_data=user_in)
    crud.create_audit_log(db, user_id=user.id, action="register", target_type="user", target_id=user.id)
    return user


@router.post("/login", response_model=schemas.TokenResponse)
def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    """
    Inicia sesión obteniendo un token JWT.
    El campo 'username' del form debe contener el correo electrónico.
    """
    user = crud.authenticate_user(db, email=form_data.username, password=form_data.password)
    if not user:
        crud.create_audit_log(
            db, user_id=None, action="login_failed", details={"email": form_data.username}
        )
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Correo electrónico o contraseña incorrectos.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cuenta suspendida.",
        )
    
    access_token = create_access_token(data={"sub": user.email})
    crud.create_audit_log(db, user_id=user.id, action="login")
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "role": user.role,
        "user_id": user.id,
        "name": user.name,
    }


@router.get("/me", response_model=schemas.UserResponse)
def get_me(current_user: models.User = Depends(get_current_active_user)):
    """Devuelve los datos del usuario actual autenticado."""
    return current_user


@router.post("/seed-admin", response_model=schemas.UserResponse)
def seed_admin(user_in: schemas.UserCreate, db: Session = Depends(get_db)):
    """
    Punto de entrada inicial para crear el primer administrador.
    Sólo funciona si no existe ningún usuario con rol 'admin' en el sistema.
    """
    if crud.has_admin_user(db):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Ya existe un administrador en el sistema. No se puede usar el seeder.",
        )
    
    if crud.get_user_by_email(db, email=user_in.email):
        raise HTTPException(
            status_code=400,
            detail="El correo electrónico ya está registrado.",
        )
    
    user_in.role = "admin"
    user = crud.create_user(db, user_data=user_in)
    crud.create_audit_log(db, user_id=user.id, action="register", target_type="user", target_id=user.id, details={"method": "seed-admin"})
    return user
