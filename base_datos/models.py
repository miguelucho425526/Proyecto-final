from sqlalchemy import Column, Integer, String, Text, ForeignKey
from sqlalchemy.orm import relationship
from database import Base

# Modelos SQLAlchemy
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