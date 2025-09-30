from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from database import Base, engine, SessionLocal
import models
from pydantic import BaseModel
import hashlib
from typing import List  # 👈 AGREGA ESTE IMPORT

# 👇 FUNCIONES DE PASSWORD
def get_password_hash(password: str) -> str:
    salt = "recetas_app_salt_2024"
    return hashlib.sha256((password + salt).encode()).hexdigest()

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return get_password_hash(plain_password) == hashed_password

# Modelos Pydantic para autenticación
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

# 👇 NUEVO: Modelo para usuarios
class UsuarioResponse(BaseModel):
    id: int
    username: str
    email: str
    phone: int

    class Config:
        from_attributes = True

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Crear las tablas
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="API Recetas con SQLite",
    description="API para gestionar recetas de cocina", 
    version="1.0.0"
)

# Configurar CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_credentials=True,
    allow_methods=["*"], 
    allow_headers=["*"],  
)

def crear_datos_ejemplo():
    db = SessionLocal()
    try:
        usuario = db.query(models.Usuario).first()
        if not usuario:
            nuevo_usuario = models.Usuario(
                username="admin",
                password=get_password_hash("admin123"),
                phone=123456789,
                email="admin@recetas.com"
            )
            db.add(nuevo_usuario)
            db.commit()
            print("✅ Usuario por defecto creado")
        
        recetas = db.query(models.Receta).first()
        if not recetas:
            receta1 = models.Receta(
                titulo="Pasta al Pesto",
                descripcion="Pasta con salsa pesto casera",
                ingredientes="Pasta, Albahaca, Ajo, Piñones, Aceite de oliva, Queso parmesano",
                pasos_preparacion="1. Cocer la pasta al dente\n2. Preparar el pesto mezclando albahaca, ajo, piñones y aceite\n3. Mezclar la pasta con el pesto y servir con queso parmesano",
                autor_id=1
            )
            
            receta2 = models.Receta(
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

crear_datos_ejemplo()

# 👇 ENDPOINTS DE AUTENTICACIÓN
@app.post("/auth/register", response_model=UserResponse)
def register_user(user: UserRegister, db: Session = Depends(get_db)):
    try:
        existing_user = db.query(models.Usuario).filter(
            (models.Usuario.username == user.username) | 
            (models.Usuario.email == user.email)
        ).first()
        
        if existing_user:
            raise HTTPException(status_code=400, detail="El usuario o email ya existe")
        
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

@app.post("/auth/login", response_model=UserResponse)
def login_user(user: UserLogin, db: Session = Depends(get_db)):
    try:
        db_user = db.query(models.Usuario).filter(
            models.Usuario.username == user.username
        ).first()
        
        if not db_user or not verify_password(user.password, db_user.password):
            raise HTTPException(status_code=401, detail="Credenciales incorrectas")
        
        return db_user
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error en el login: {str(e)}")

# 👇 NUEVO: ENDPOINTS PARA USUARIOS
@app.get("/usuarios/", response_model=List[UsuarioResponse])
def get_usuarios(db: Session = Depends(get_db)):
    try:
        usuarios = db.query(models.Usuario).all()
        return usuarios
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al obtener usuarios: {str(e)}")

@app.get("/usuarios/{usuario_id}", response_model=UsuarioResponse)
def get_usuario(usuario_id: int, db: Session = Depends(get_db)):
    try:
        usuario = db.query(models.Usuario).filter(models.Usuario.id == usuario_id).first()
        if not usuario:
            raise HTTPException(status_code=404, detail="Usuario no encontrado")
        return usuario
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al obtener usuario: {str(e)}")

# 👇 ENDPOINTS EXISTENTES DE RECETAS
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

@app.get("/api/recetas/")
def get_recetas():
    db = SessionLocal()
    try:
        recetas = db.query(models.Receta).all()
        return recetas
    finally:
        db.close()

@app.get("/api/recetas/{receta_id}")
def get_receta(receta_id: int):
    db = SessionLocal()
    try:
        receta = db.query(models.Receta).filter(models.Receta.id == receta_id).first()
        if not receta:
            return {"error": "Receta no encontrada"}
        return receta
    finally:
        db.close()

@app.post("/api/recetas/")
def crear_receta(receta: dict):
    db = SessionLocal()
    try:
        nueva_receta = models.Receta(
            titulo=receta.get("titulo", ""),
            descripcion=receta.get("descripcion", ""),
            ingredientes=receta.get("ingredientes", ""),
            pasos_preparacion=receta.get("pasos_preparacion", ""),
            autor_id=receta.get("autor_id", 1)
        )
        db.add(nueva_receta)
        db.commit()
        db.refresh(nueva_receta)
        return nueva_receta
    except Exception as e:
        db.rollback()
        return {"error": f"No se pudo crear la receta: {str(e)}"}
    finally:
        db.close()

@app.put("/api/recetas/{receta_id}")
def actualizar_receta(receta_id: int, receta: dict):
    db = SessionLocal()
    try:
        receta_db = db.query(models.Receta).filter(models.Receta.id == receta_id).first()
        if not receta_db:
            return {"error": "Receta no encontrada"}
        
        receta_db.titulo = receta.get("titulo", receta_db.titulo)
        receta_db.descripcion = receta.get("descripcion", receta_db.descripcion)
        receta_db.ingredientes = receta.get("ingredientes", receta_db.ingredientes)
        receta_db.pasos_preparacion = receta.get("pasos_preparacion", receta_db.pasos_preparacion)
        
        db.commit()
        return receta_db
    except Exception as e:
        db.rollback()
        return {"error": f"No se pudo actualizar la receta: {str(e)}"}
    finally:
        db.close()

@app.delete("/api/recetas/{receta_id}")
def eliminar_receta(receta_id: int):
    db = SessionLocal()
    try:
        receta = db.query(models.Receta).filter(models.Receta.id == receta_id).first()
        if not receta:
            return {"error": "Receta no encontrada"}
        
        db.delete(receta)
        db.commit()
        return {"mensaje": f"Receta '{receta.titulo}' eliminada"}
    except Exception as e:
        db.rollback()
        return {"error": f"No se pudo eliminar la receta: {str(e)}"}
    finally:
        db.close()

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

if __name__ == "__main__":
    import uvicorn
    print("🚀 Servidor FastAPI iniciado!")
    print("📍 URL local: http://localhost:8000")
    print("📍 URL red: http://0.0.0.0:8000") 
    print("📚 Docs: http://localhost:8000/docs")
    print("👥 Usuarios: http://localhost:8000/usuarios/")
    print("⏹️  Presiona CTRL+C para detener")
    
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)