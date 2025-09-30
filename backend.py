from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List
import uuid

app = FastAPI(title="Recetas API")

# CORS para Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class Recipe(BaseModel):
    id: str
    title: str
    description: str
    ingredients: List[str]
    steps: List[str]

# Datos de ejemplo
recipes_db = [
    {
        "id": "1",
        "title": "Pasta al Pesto",
        "description": "Pasta con salsa pesto casera",
        "ingredients": ["200g de pasta", "2 tazas de albahaca", "1/2 taza de piñones", "1/2 taza de queso parmesano", "2 dientes de ajo", "1/2 taza de aceite de oliva"],
        "steps": ["Cocinar la pasta según las instrucciones", "Preparar la salsa pesto en licuadora", "Mezclar pasta con pesto y servir"]
    },
    {
        "id": "2", 
        "title": "Ensalada Mediterránea",
        "description": "Ensalada fresca con ingredientes del mediterráneo",
        "ingredients": ["Tomate", "Pepino", "Aceitunas", "Queso feta", "Cebolla roja", "Aceite de oliva", "Limón"],
        "steps": ["Cortar tomate y pepino en cubos", "Picar cebolla roja finamente", "Mezclar todos los ingredientes", "Aliñar con aceite y limón"]
    }
]

@app.get("/")
def read_root():
    return {"message": "Recetas API funcionando"}

@app.get("/api/recetas/")
def get_recetas():
    return recipes_db

@app.post("/api/recetas/")
def create_receta(recipe: Recipe):
    new_recipe = recipe.dict()
    new_recipe["id"] = str(uuid.uuid4())  # Generar ID único
    recipes_db.append(new_recipe)
    return new_recipe

@app.delete("/api/recetas/{recipe_id}")
def delete_receta(recipe_id: str):
    global recipes_db
    recipes_db = [r for r in recipes_db if r["id"] != recipe_id]
    return {"message": "Receta eliminada"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)