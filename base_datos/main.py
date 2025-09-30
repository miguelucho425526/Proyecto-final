from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import Column, Integer, String, Text, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from pydantic import BaseModel
import hashlib
from typing import List

# ==================== CONFIGURACIÓN BASE DE DATOS ====================
SQLITE_DATABASE_URL = "sqlite:///./recetas.db"

engine = create_engine(
    SQLITE_DATABASE_URL, connect_args={"check_same_thread": False}
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# ==================== MODELOS SQLALCHEMY ====================
class Usuario(Base):
    __tablename__ = "usuarios"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    password = Column(String)
    phone = Column(Integer)
    email = Column(String, unique=True, index=True)

    recetas = relationship("Receta", back_populates="autor")

class Receta(Base):
    __tablename__ = "recetas"

    id = Column(Integer, primary_key=True, index=True)
    titulo = Column(String, index=True)
    descripcion = Column(Text)
    ingredientes = Column(Text)
    pasos_preparacion = Column(Text)
    autor_id = Column(Integer, ForeignKey("usuarios.id"))

    autor = relationship("Usuario", back_populates="recetas")

# ==================== MODELOS PYDANTIC ====================
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
        from_attributes = True

class RecetaResponse(BaseModel):
    id: int
    titulo: str
    descripcion: str
    ingredientes: str
    pasos_preparacion: str
    autor_id: int

    class Config:
        from_attributes = True

# ==================== FUNCIONES DE SEGURIDAD ====================
def get_password_hash(password: str) -> str:
    """Hash de contraseña usando SHA256"""
    salt = "recetas_app_salt_2024"
    return hashlib.sha256((password + salt).encode()).hexdigest()

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verificar contraseña"""
    return get_password_hash(plain_password) == hashed_password

# ==================== APLICACIÓN FASTAPI ====================
# Crear las tablas en la base de datos
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="API Recetas con SQLite",
    description="API para gestionar recetas de cocina", 
    version="1.0.0"
)

# Configurar CORS para Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_credentials=True,
    allow_methods=["*"], 
    allow_headers=["*"],  
)

# ==================== DATOS DE EJEMPLO ====================
def crear_datos_ejemplo():
    """Crear datos de ejemplo si no existen"""
    db = SessionLocal()
    try:
        # Verificar si ya existe el usuario
        usuario = db.query(Usuario).first()
        if not usuario:
            # Crear usuario de ejemplo con contraseña hasheada
            nuevo_usuario = Usuario(
                username="admin",
                password=get_password_hash("admin123"),
                phone=123456789,
                email="admin@recetas.com"
            )
            db.add(nuevo_usuario)
            db.commit()
            print("✅ Usuario por defecto creado")
        
        # Verificar si ya existen recetas
        recetas = db.query(Receta).first()
        if not recetas:
            # Crear recetas de ejemplo
            receta1 = Receta(
                titulo="Pasta al Pesto",
                descripcion="Pasta con salsa pesto casera",
                ingredientes="Pasta, Albahaca, Ajo, Piñones, Aceite de oliva, Queso parmesano",
                pasos_preparacion="1. Cocer la pasta al dente\n2. Preparar el pesto mezclando albahaca, ajo, piñones y aceite\n3. Mezclar la pasta con el pesto y servir con queso parmesano",
                autor_id=1
            )
            
            receta2 = Receta(
                titulo="Ensalada Mediterránea", 
                descripcion="Ensalada fresca con ingredientes del mediterráneo",
                ingredientes="Tomate, Pepino, Aceitunas, Queso feta, Cebolla roja, Aceite de oliva, Limón",
                pasos_preparacion="1. Cortar tomate y pepino en cubos\n2. Picar cebolla roja finamente\n3. Mezclar todos los ingredientes\n4. Aliñar con aceite de oliva y jugo de limón",
                autor_id=1
            )
            
            db.add(receta1)
            db.add(receta2)
            db.commit()
            print("✅ Recetas de ejemplo creadas")
            
    except Exception as e:
        print(f"❌ Error creando datos: {e}")
        db.rollback()
    finally:
        db.close()

# Crear datos de ejemplo
crear_datos_ejemplo()

# ==================== ENDPOINTS DE AUTENTICACIÓN ====================
@app.post("/auth/register", response_model=UserResponse)
def register_user(user: UserRegister, db: Session = Depends(get_db)):
    try:
        # Verificar si el usuario ya existe
        existing_user = db.query(Usuario).filter(
            (Usuario.username == user.username) | 
            (Usuario.email == user.email)
        ).first()
        
        if existing_user:
            raise HTTPException(
                status_code=400, 
                detail="El usuario o email ya existe"
            )
        
        # Crear nuevo usuario
        new_user = Usuario(
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

@app.post("/auth/login", response_model=UserResponse)
def login_user(user: UserLogin, db: Session = Depends(get_db)):
    try:
        # Buscar usuario
        db_user = db.query(Usuario).filter(
            Usuario.username == user.username
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

# ==================== ENDPOINTS DE USUARIOS ====================
@app.get("/usuarios/", response_model=List[UserResponse])
def get_usuarios(db: Session = Depends(get_db)):
    """Obtener todos los usuarios"""
    try:
        usuarios = db.query(Usuario).all()
        return usuarios
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al obtener usuarios: {str(e)}")

@app.get("/usuarios/{usuario_id}", response_model=UserResponse)
def get_usuario(usuario_id: int, db: Session = Depends(get_db)):
    """Obtener un usuario específico por ID"""
    try:
        usuario = db.query(Usuario).filter(Usuario.id == usuario_id).first()
        if not usuario:
            raise HTTPException(status_code=404, detail="Usuario no encontrado")
        return usuario
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al obtener usuario: {str(e)}")

# ==================== ENDPOINTS DE RECETAS ====================
@app.get("/")
def root():
    return {
        "mensaje": "Bienvenido a la API de Recetas con SQLite",
        "version": "1.0.0",
        "endpoints": {
            "recetas": "/api/recetas/",
            "usuarios": "/usuarios/",
            "autenticación": "/auth/",
            "documentación": "/docs"
        }
    }

@app.get("/api/recetas/", response_model=List[RecetaResponse])
def get_recetas(db: Session = Depends(get_db)):
    try:
        recetas = db.query(Receta).all()
        return recetas
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al obtener recetas: {str(e)}")

@app.get("/api/recetas/{receta_id}", response_model=RecetaResponse)
def get_receta(receta_id: int, db: Session = Depends(get_db)):
    try:
        receta = db.query(Receta).filter(Receta.id == receta_id).first()
        if not receta:
            raise HTTPException(status_code=404, detail="Receta no encontrada")
        return receta
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al obtener receta: {str(e)}")

@app.post("/api/recetas/", response_model=RecetaResponse)
def crear_receta(receta_data: dict, db: Session = Depends(get_db)):
    try:
        nueva_receta = Receta(
            titulo=receta_data.get("titulo", ""),
            descripcion=receta_data.get("descripcion", ""),
            ingredientes=receta_data.get("ingredientes", ""),
            pasos_preparacion=receta_data.get("pasos_preparacion", ""),
            autor_id=receta_data.get("autor_id", 1)
        )
        db.add(nueva_receta)
        db.commit()
        db.refresh(nueva_receta)
        return nueva_receta
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"No se pudo crear la receta: {str(e)}")

@app.put("/api/recetas/{receta_id}", response_model=RecetaResponse)
def actualizar_receta(receta_id: int, receta_data: dict, db: Session = Depends(get_db)):
    try:
        receta_db = db.query(Receta).filter(Receta.id == receta_id).first()
        if not receta_db:
            raise HTTPException(status_code=404, detail="Receta no encontrada")
        
        receta_db.titulo = receta_data.get("titulo", receta_db.titulo)
        receta_db.descripcion = receta_data.get("descripcion", receta_db.descripcion)
        receta_db.ingredientes = receta_data.get("ingredientes", receta_db.ingredientes)
        receta_db.pasos_preparacion = receta_data.get("pasos_preparacion", receta_db.pasos_preparacion)
        
        db.commit()
        db.refresh(receta_db)
        return receta_db
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"No se pudo actualizar la receta: {str(e)}")

@app.delete("/api/recetas/{receta_id}")
def eliminar_receta(receta_id: int, db: Session = Depends(get_db)):
    try:
        receta = db.query(Receta).filter(Receta.id == receta_id).first()
        if not receta:
            raise HTTPException(status_code=404, detail="Receta no encontrada")
        
        db.delete(receta)
        db.commit()
        return {"mensaje": f"Receta '{receta.titulo}' eliminada correctamente"}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"No se pudo eliminar la receta: {str(e)}")

# ==================== ENDPOINTS DE SALUD ====================
@app.get("/health")
def health_check():
    return {"status": "healthy", "service": "Recetas API"}

@app.get("/api/info")
def api_info():
    return {
        "nombre": "API Recetas",
        "descripcion": "Sistema de gestión de recetas de cocina",
        "tecnologias": ["FastAPI", "SQLite", "SQLAlchemy"],
        "desarrollado_por": "Tu equipo de desarrollo"
    }

# ==================== INICIO DEL SERVIDOR ====================
if __name__ == "__main__":
    import uvicorn
    print("🚀 Servidor FastAPI iniciado!")
    print("📍 URL local: http://localhost:8000")
    print("📍 URL red: http://0.0.0.0:8000") 
    print("📚 Docs: http://localhost:8000/docs")
    print("👥 Usuarios: http://localhost:8000/usuarios/")
    print("⏹️  Presiona CTRL+C para detener")
    
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)