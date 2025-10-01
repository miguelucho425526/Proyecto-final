import 'dart:convert';
import 'package:http/http.dart' as http;

void testConnection() async {
  print('🔍 Probando conexión al servidor...');
  
  final urlsToTest = [
    'http://10.1.113.219:8000/health',
    'http://10.0.2.2:8000/health',
    'http://localhost:8000/health',
  ];
  
  for (var url in urlsToTest) {
    try {
      print('🔄 Probando: $url');
      final response = await http.get(Uri.parse(url)).timeout(Duration(seconds: 5));
      print('✅ CONEXIÓN EXITOSA: $url - Status: ${response.statusCode}');
    } catch (e) {
      print('❌ FALLÓ: $url - Error: $e');
    }
  }
}