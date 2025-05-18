import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:prefectura_1/models/asistencia_model.dart';
import 'package:prefectura_1/exceptions/api_exception.dart';

class ApiService {
  static const String _baseUrl = 'https://primera-versi-n-de-mi-api-flask-production.up.railway.app';
  static const Duration _timeoutDuration = Duration(seconds: 30);
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<dynamic> _handleRequest(Future<http.Response> request) async {
    try {
      final response = await request.timeout(_timeoutDuration);
      final body = json.decode(utf8.decode(response.bodyBytes));
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return body;
      } else {
        throw ApiException(
          body['message'] ?? 'Error en la solicitud',
          response.statusCode,
        );
      }
    } on SocketException {
      throw ApiException('No hay conexión a internet');
    } on TimeoutException {
      throw ApiException('Tiempo de espera agotado');
    } on FormatException catch (e) {
      throw ApiException('Error en el formato de respuesta: ${e.message}');
    } catch (e) {
      throw ApiException('Error inesperado: ${e.toString()}');
    }
  }

  Map<String, String> _buildHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ==================== AUTHENTICATION ====================
  Future<String?> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['token'];
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> getUserProfile(String token) async {
    final url = Uri.parse('$_baseUrl/user/profile');
    try {
      final response = await http.get(
        url,
        headers: _buildHeaders(token),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener el perfil');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ==================== MAESTROS ====================
  Future<List<dynamic>> getMaestros(String token) async {
    final url = Uri.parse('$_baseUrl/maestros');
    try {
      final response = await http.get(
        url,
        headers: _buildHeaders(token),
      );

      return _processResponse(response);
    } catch (e) {
      throw Exception('Error obteniendo maestros: $e');
    }
  }

  Future<bool> createMaestro(String token, Map<String, dynamic> maestro) async {
    final url = Uri.parse('$_baseUrl/maestros');
    try {
      final response = await http.post(
        url,
        headers: _buildHeaders(token),
        body: json.encode(maestro),
      );

      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // ==================== ASIGNATURAS ====================
  Future<List<dynamic>> getAsignaturas(String token) async {
    final url = Uri.parse('$_baseUrl/asignaturas');
    try {
      final response = await http.get(
        url,
        headers: _buildHeaders(token),
      );

      return _processResponse(response);
    } catch (e) {
      throw Exception('Error obteniendo asignaturas: $e');
    }
  }

  Future<bool> createAsignatura(String token, Map<String, dynamic> asignatura) async {
    final url = Uri.parse('$_baseUrl/asignaturas');
    try {
      final response = await http.post(
        url,
        headers: _buildHeaders(token),
        body: json.encode(asignatura),
      );

      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // ==================== AULAS ====================
  Future<List<dynamic>> getAulas(String token) async {
    final url = Uri.parse('$_baseUrl/aulas');
    try {
      final response = await http.get(
        url,
        headers: _buildHeaders(token),
      );

      return _processResponse(response);
    } catch (e) {
      throw Exception('Error obteniendo aulas: $e');
    }
  }

  // ==================== CARRERAS ====================
  Future<List<dynamic>> getCarreras(String token) async {
    final url = Uri.parse('$_baseUrl/carreras');
    try {
      final response = await http.get(
        url,
        headers: _buildHeaders(token),
      );

      return _processResponse(response);
    } catch (e) {
      throw Exception('Error obteniendo carreras: $e');
    }
  }

  // ==================== GRUPOS ====================
  Future<List<dynamic>> getGrupos(String token) async {
    final url = Uri.parse('$_baseUrl/grupos');
    try {
      final response = await http.get(
        url,
        headers: _buildHeaders(token),
      );

      return _processResponse(response);
    } catch (e) {
      throw Exception('Error obteniendo grupos: $e');
    }
  }

  // ==================== HORARIOS ====================
  Future<List<dynamic>> getHorarios(String token) async {
    final url = Uri.parse('$_baseUrl/horarios');
    try {
      final response = await http.get(
        url,
        headers: _buildHeaders(token),
      );

      return _processResponse(response);
    } catch (e) {
      throw Exception('Error obteniendo horarios: $e');
    }
  }

  Future<bool> createHorario(String token, Map<String, dynamic> horario) async {
    final url = Uri.parse('$_baseUrl/horarios');
    try {
      final response = await http.post(
        url,
        headers: _buildHeaders(token),
        body: json.encode(horario),
      );

      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // ==================== ASISTENCIAS ====================

    Future<Map<String, dynamic>> getAsistencias({
    required String token,
    String? fecha,
    int? idHorario,
    int? idMaestro,
  }) async {
    try {
      final queryParams = <String, String>{
        if (fecha != null) 'fecha': fecha,
        if (idHorario != null) 'id_horario': idHorario.toString(),
        if (idMaestro != null) 'id_maestro': idMaestro.toString(),
      };

      final uri = Uri.parse('$_baseUrl/asistencias').replace(
        queryParameters: queryParams,
      );

      final response = await _handleRequest(
        _client.get(uri, headers: _buildHeaders(token)),
      );

      if (response is! Map<String, dynamic>) {
        throw ApiException('La respuesta no es un mapa válido');
      }

      return response;
    } on ApiException catch (e) {
      throw ApiException('Error obteniendo asistencias: ${e.message}');
    }
  }

Future<Asistencia> createAsistencia({
  required String token,
  required int idHorario,
  required int idEstado,
  required String fechaAsistencia,
  required String horaAsistencia,
}) async {
  try {
    if (idEstado != 1 && idEstado != 2) {
      throw ApiException('Estado de asistencia inválido');
    }

    final url = Uri.parse('$_baseUrl/asistencias');
    final body = {
      'id_horario': idHorario,
      'id_estado': idEstado,
      'fecha_asistencia': fechaAsistencia,
      'hora_asistencia': horaAsistencia,
    };

    final response = await _handleRequest(
      _client.post(
        url,
        headers: _buildHeaders(token),
        body: json.encode(body),
      ),
    );

    if (response is! Map<String, dynamic>) {
      throw ApiException('Respuesta inválida al crear asistencia');
    }

    // Ensure required fields exist in response
    if (response['id_asistencia'] == null || 
        response['id_horario'] == null || 
        response['id_estado'] == null) {
      throw ApiException('Datos incompletos en la respuesta del servidor');
    }

    return Asistencia.fromJson(response);
  } on FormatException catch (e) {
    throw ApiException('Error de formato: ${e.message}');
  } catch (e) {
    throw ApiException('Error creando asistencia: ${e.toString()}');
  }
}

  // ==================== ESTADOS ====================
  Future<List<dynamic>> getEstados(String token) async {
    final url = Uri.parse('$_baseUrl/estados');
    try {
      final response = await http.get(
        url,
        headers: _buildHeaders(token),
      );

      return _processResponse(response);
    } catch (e) {
      throw Exception('Error obteniendo estados: $e');
    }
  }

  

  // ==================== USUARIOS ====================
  Future<List<dynamic>> getUsuarios(String token) async {
    final url = Uri.parse('$_baseUrl/usuarios');
    try {
      final response = await http.get(
        url,
        headers: _buildHeaders(token),
      );

      return _processResponse(response);
    } catch (e) {
      throw Exception('Error obteniendo usuarios: $e');
    }
  }

  // ==================== HELPER METHODS ====================


  dynamic _processResponse(http.Response response) {
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }
}

