import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class AuthService {
  static const bool useSimulation = false;

  // Registrar nuevo usuario
  static Future<User> registerUser({
    required String username,
    required String email,
    required String password,
    required int phone,
  }) async {
    if (useSimulation) {
      print('🎭 MODO SIMULACIÓN - Registrando usuario: $username');
      await Future.delayed(Duration(seconds: 2));
      
      // Simula registro exitoso
      return User(
        id: DateTime.now().millisecondsSinceEpoch,
        username: username,
        email: email,
        phone: phone,
      );
    } else {
      // CÓDIGO REAL - MEJORADO
      try {
        print('🔐 Intentando registrar usuario: $username');
        
        final response = await http.post(
          Uri.parse('http://10.1.113.219:8000/auth/register'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode({
            'username': username,
            'email': email,
            'password': password,
            'phone': phone,
          }),
        ).timeout(Duration(seconds: 10));

        print('📡 Respuesta del servidor: ${response.statusCode}');
        print('📦 Body de respuesta: ${response.body}');

        // Manejar diferentes códigos de respuesta
        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          print('✅ Usuario registrado exitosamente: ${responseData['username']}');
          return User.fromJson(responseData);
        } else if (response.statusCode == 400) {
          // Error de validación del servidor
          final errorData = json.decode(response.body);
          throw Exception(errorData['detail'] ?? 'Error en el registro');
        } else if (response.statusCode == 500) {
          // Error interno del servidor
          final errorData = json.decode(response.body);
          throw Exception(errorData['detail'] ?? 'Error interno del servidor');
        } else {
          // Otros errores
          throw Exception('Error ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        print('❌ Error en registro: $e');
        if (e is http.ClientException) {
          throw Exception('Error de conexión: Verifica que el servidor esté ejecutándose');
        } else if (e is Exception) {
          rethrow; // Ya tenemos un mensaje específico
        } else {
          throw Exception('Error desconocido: $e');
        }
      }
    }
  }

  // Login de usuario
  static Future<User> loginUser({
    required String username,
    required String password,
  }) async {
    if (useSimulation) {
      print('🎭 MODO SIMULACIÓN - Login usuario: $username');
      await Future.delayed(Duration(seconds: 2));
      
      // Simulación
      return User(
        id: 1,
        username: username,
        email: '$username@ejemplo.com',
        phone: 123456789,
      );
    } else {
      // CÓDIGO REAL - MEJORADO
      try {
        print('🔐 Intentando login usuario: $username');
        
        final response = await http.post(
          Uri.parse('http://10.1.113.219:8000/auth/login'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode({
            'username': username,
            'password': password,
          }),
        ).timeout(Duration(seconds: 10));

        print('📡 Respuesta del servidor: ${response.statusCode}');
        print('📦 Body de respuesta: ${response.body}');

        // Manejar diferentes códigos de respuesta
        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          print('✅ Login exitoso: ${responseData['username']}');
          return User.fromJson(responseData);
        } else if (response.statusCode == 401) {
          throw Exception('Credenciales incorrectas');
        } else if (response.statusCode == 400 || response.statusCode == 500) {
          final errorData = json.decode(response.body);
          throw Exception(errorData['detail'] ?? 'Error en el login');
        } else {
          throw Exception('Error ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        print('❌ Error en login: $e');
        if (e is http.ClientException) {
          throw Exception('Error de conexión: Verifica que el servidor esté ejecutándose');
        } else if (e is Exception) {
          rethrow;
        } else {
          throw Exception('Error desconocido: $e');
        }
      }
    }
  }
}