from fastapi import FastAPI
from app.models import models
from app.core.database import engine
from app.api.routers import profile, medications, logs

# Create database tables
models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Bellota Backend API",
    description="API para la aplicación Bellota, gestionando perfil de usuario y configuraciones de salud.",
    version="1.0.0"
)

app.include_router(profile.router)
app.include_router(medications.router)
app.include_router(logs.router)

@app.get("/")
def read_root():
    return {"message": "Welcome to Bellota Backend API. Go to /docs for the API documentation."}
