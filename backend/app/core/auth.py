"""
Módulo de autenticación JWT para la API Bellota.

Gestiona la creación y verificación de tokens de acceso,
el hash de contraseñas y las dependencias de autorización por rol.
"""
from datetime import datetime, timedelta
from typing import Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session

from app.core.database import get_db

# ── Configuración ──────────────────────────────────────────────────────────────
# En producción, leer desde variables de entorno.
SECRET_KEY = "bellota-secret-key-change-in-production-2024"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60

# ── Contexto de hashing de contraseñas ───────────────────────────────────────
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# ── Esquema OAuth2 ─────────────────────────────────────────────────────────────
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


# ── Utilidades de contraseña ───────────────────────────────────────────────────

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verifica si una contraseña en texto plano coincide con su hash."""
    return pwd_context.verify(plain_password, hashed_password)


def hash_password(password: str) -> str:
    """Genera el hash bcrypt de una contraseña."""
    return pwd_context.hash(password)


# ── Utilidades de JWT ──────────────────────────────────────────────────────────

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """
    Crea un JWT firmado con los datos proporcionados.

    Args:
        data: Payload del token (debe incluir 'sub' con el email del usuario).
        expires_delta: Tiempo de expiración del token.

    Returns:
        Token JWT firmado como string.
    """
    to_encode = data.copy()
    expire = datetime.utcnow() + (
        expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def decode_token(token: str) -> dict:
    """
    Decodifica y valida un JWT.

    Raises:
        HTTPException 401 si el token es inválido o ha expirado.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Token inválido o expirado.",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
        return payload
    except JWTError:
        raise credentials_exception


# ── Dependencias FastAPI ───────────────────────────────────────────────────────

def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
):
    """
    Dependencia FastAPI: decodifica el JWT y retorna el usuario actual.

    Raises:
        HTTPException 401 si el token es inválido.
        HTTPException 404 si el usuario no existe.
    """
    from app.crud.crud import get_user_by_email  # import local para evitar circular

    payload = decode_token(token)
    email: str = payload.get("sub")
    user = get_user_by_email(db, email)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuario no encontrado.",
        )
    return user


def get_current_active_user(current_user=Depends(get_current_user)):
    """
    Dependencia FastAPI: verifica que la cuenta del usuario esté activa.

    Raises:
        HTTPException 403 si la cuenta está suspendida.
    """
    if not current_user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cuenta suspendida. Contacta al administrador.",
        )
    return current_user


def require_role(*roles: str):
    """
    Fábrica de dependencias para proteger rutas por rol.

    Uso:
        @router.get("/admin", dependencies=[Depends(require_role("admin"))])

    Args:
        roles: Uno o más roles permitidos (ej: 'admin', 'auditor').

    Returns:
        Dependencia que valida el rol del usuario actual.
    """
    def _check_role(current_user=Depends(get_current_active_user)):
        if current_user.role not in roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Acceso denegado. Se requiere uno de los roles: {', '.join(roles)}.",
            )
        return current_user

    return _check_role
