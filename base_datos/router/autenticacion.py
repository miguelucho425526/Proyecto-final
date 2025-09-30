from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from base_datos.database import get_db
from base_datos import models
from pydantic import BaseModel
from passlib.context import CryptContext

router = APIRouter(prefix="/auth", tags=["authentication"])
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Modelos Pydantic
class UserRegister(BaseModel):
    username: str
    email: str
    password: str
    phone: int

class UserLogin(BaseModel):
    username: str
    password: str

class UserResponse(BaseModel):
    id: int
    username: str
    email: str
    phone: int

    class Config:
        orm_mode = True

# Helper functions
def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

# Registrar usuario
@router.post("/register", response_model=UserResponse)
def register_user(user: UserRegister, db: Session = Depends(get_db)):
    try:
        # Verificar si el usuario ya existe
        existing_user = db.query(models.Usuario).filter(
            (models.Usuario.username == user.username) | 
            (models.Usuario.email == user.email)
        ).first()
        
        if existing_user:
            raise HTTPException(
                status_code=400, 
                detail="El usuario o email ya existe"
            )
        
        # Crear nuevo usuario
        new_user = models.Usuario(
            username=user.username,
            email=user.email,
            password=get_password_hash(user.password),
            phone=user.phone
        )
        
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        
        return new_user
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error al registrar usuario: {str(e)}")

# Login de usuario
@router.post("/login", response_model=UserResponse)
def login_user(user: UserLogin, db: Session = Depends(get_db)):
    try:
        # Buscar usuario
        db_user = db.query(models.Usuario).filter(
            models.Usuario.username == user.username
        ).first()
        
        if not db_user or not verify_password(user.password, db_user.password):
            raise HTTPException(
                status_code=401, 
                detail="Credenciales incorrectas"
            )
        
        return db_user
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error en el login: {str(e)}")