from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.models import models
from app.core.database import engine
from app.api.routers import profile, medications, logs, auth, admin, audit

# Create database tables
models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Bellota Backend API",
    description="API para la aplicación Bellota, con soporte RBAC completo (Admin, Usuario, Auditor).",
    version="2.0.0"
)

# Configuración de CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Permitir desde cualquier origen para desarrollo
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routers de autenticación y RBAC
app.include_router(auth.router)
app.include_router(admin.router)
app.include_router(audit.router)

# Routers de negocio
app.include_router(profile.router)
app.include_router(medications.router)
app.include_router(logs.router)

@app.get("/")
def read_root():
    return {"message": "Welcome to Bellota Backend API. Go to /docs for the API documentation."}
