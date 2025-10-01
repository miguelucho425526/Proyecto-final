import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class UserService {
  static const String baseUrl = "http://localhost:8000";

  // Obtener usuario por ID
  static Future<User> getUserById(int userId) async {
    try {
      print('🔍 Obteniendo usuario con ID: $userId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/usuarios/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 10));

      print('📡 Respuesta: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('✅ Usuario obtenido: ${responseData['username']}');
        return User.fromJson(responseData);
      } else if (response.statusCode == 404) {
        throw Exception('Usuario no encontrado');
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error obteniendo usuario: $e');
      throw Exception('Error al cargar perfil: $e');
    }
  }

  // Obtener todos los usuarios (opcional)
  static Future<List<User>> getAllUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/usuarios/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener usuarios');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Actualizar usuario (opcional para futuras funcionalidades)
  static Future<User> updateUser(User user) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/usuarios/${user.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(user.toJson()),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return User.fromJson(responseData);
      } else {
        throw Exception('Error al actualizar usuario');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}