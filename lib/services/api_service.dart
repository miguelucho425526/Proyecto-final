import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';

class ApiService {
  static const String baseUrl = "http://10.1.113.219:8000/api/recetas";

  static const Map<String, String> headers = {
    "Content-Type": "application/json",
  };

  // Obtener todas las recetas
  static Future<List<Recipe>> getRecetas() async {
    try {
      print("🔄 Conectando a: $baseUrl/");
      
      final response = await http.get(
        Uri.parse("$baseUrl/"),
        headers: headers,
      ).timeout(Duration(seconds: 10));

      print("📡 Código de respuesta: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        print("✅ Recetas obtenidas: ${jsonList.length}");
        return jsonList.map((json) => _fromBackendJson(json)).toList();
      } else {
        throw Exception("Error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      print("❌ Error de conexión: $e");
      throw Exception("Error de conexión: $e");
    }
  }

  // Crear receta
  static Future<Recipe> crearReceta(Recipe recipe) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/"),
        headers: headers,
        body: jsonEncode(_toBackendJson(recipe)),
      );

      if (response.statusCode == 200) {
        return _fromBackendJson(jsonDecode(response.body));
      } else {
        throw Exception("Error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error de conexión: $e");
    }
  }

  // Obtener receta por ID
  static Future<Recipe> getRecetaById(String id) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/$id"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return _fromBackendJson(jsonDecode(response.body));
      } else {
        throw Exception("Error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error de conexión: $e");
    }
  }

  // Eliminar receta
  static Future<void> eliminarReceta(String id) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/$id"),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception("Error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error de conexión: $e");
    }
  }

  // Convertir JSON del backend a Recipe
  static Recipe _fromBackendJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'].toString(),
      title: json['titulo'] ?? 'Sin título',
      description: json['descripcion'] ?? 'Sin descripción',
      ingredients: _parseIngredients(json['ingredientes'] ?? ''),
      steps: json['pasos_preparacion'] ?? 'Sin pasos',
      imageUrl: '',
      isFavorite: false,
    );
  }

  // Convertir Recipe a JSON para el backend
  static Map<String, dynamic> _toBackendJson(Recipe recipe) {
    return {
      'titulo': recipe.title,
      'descripcion': recipe.description,
      'ingredientes': _formatIngredients(recipe.ingredients),
      'pasos_preparacion': recipe.steps,
      'autor_id': 1,
    };
  }

  // Parsear ingredientes
  static List<String> _parseIngredients(String ingredientes) {
    if (ingredientes.isEmpty) return ['Sin ingredientes'];
    return ingredientes.split(',').map((ing) => ing.trim()).toList();
  }

  // Formatear ingredientes
  static String _formatIngredients(List<String> ingredients) {
    return ingredients.join(', ');
  }
}