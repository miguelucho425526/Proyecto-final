import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class AuthService {
  static const bool useSimulation = true; // ✅ MODO SIMULACIÓN ACTIVADO

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
      // Código real (desactiva useSimulation cuando la API funcione)
      try {
        final response = await http.post(
          Uri.parse('http://10.1.113.219:8000/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'username': username,
            'email': email,
            'password': password,
            'phone': phone,
          }),
        ).timeout(Duration(seconds: 10));

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          return User.fromJson(responseData);
        } else {
          throw Exception('Error en el registro');
        }
      } catch (e) {
        throw Exception('Error de conexión: $e');
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
      
      // ✅ PARA PRUEBAS - ACEPTA CUALQUIER USUARIO/CONTRASEÑA
      // Esto te permitirá probar el flujo completo
      return User(
        id: 1,
        username: username,
        email: '$username@ejemplo.com',
        phone: 123456789,
      );
      
      /* 
      // O si quieres credenciales específicas, usa esto:
      if (username == 'admin' && password == 'admin123') {
        return User(
          id: 1,
          username: 'admin',
          email: 'admin@recetas.com',
          phone: 123456789,
        );
      } else {
        throw Exception('Credenciales incorrectas. Usa: admin / admin123');
      }
      */
    } else {
      // Código real
      try {
        final response = await http.post(
          Uri.parse('http://10.1.113.219:8000/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'username': username,
            'password': password,
          }),
        ).timeout(Duration(seconds: 10));

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          return User.fromJson(responseData);
        } else {
          throw Exception('Error en el login');
        }
      } catch (e) {
        throw Exception('Error de conexión: $e');
      }
    }
  }
}