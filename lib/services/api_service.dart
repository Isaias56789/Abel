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
  required String fecha,
  int? idHorario,
  int? idMaestro,
}) async {
  try {
    // Validar parámetro fecha
    if (fecha.isEmpty) {
      throw ApiException('La fecha es requerida');
    }

    // Construir parámetros de consulta
    final queryParams = <String, String>{
      'fecha': fecha,
      if (idHorario != null) 'id_horario': idHorario.toString(),
      if (idMaestro != null) 'id_maestro': idMaestro.toString(),
    };

    final uri = Uri.parse('$_baseUrl/asistencias').replace(
      queryParameters: queryParams,
    );

    // Log para depuración
    debugPrint('Solicitando asistencias: ${uri.toString()}');

    final response = await _client.get(
      uri,
      headers: _buildHeaders(token),
    );

    // Verificar el código de estado
    if (response.statusCode != 200) {
      final errorBody = _tryParseResponse(response.body);
      throw ApiException(
        'Error en la solicitud (${response.statusCode}): ${errorBody['message'] ?? 'Error desconocido'}',
      );
    }

    // Parsear y validar la respuesta
    
    final responseBody = _tryParseResponse(response.body);
    
    if (responseBody is! Map<String, dynamic>) {
      throw ApiException('Formato de respuesta inválido. Se esperaba un mapa JSON');
    }

    if (!responseBody.containsKey('success')) {
      throw ApiException('La respuesta no indica éxito/fallo');
    }

    if (responseBody['success'] == false) {
      throw ApiException(responseBody['message'] ?? 'Error al obtener asistencias');
    }

    if (!responseBody.containsKey('data')) {
      throw ApiException('La respuesta no contiene datos de asistencia');
    }

    return responseBody;
  } on ApiException {
    rethrow;
  } catch (e) {
    throw ApiException('Error inesperado obteniendo asistencias: ${e.toString()}');
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
    // Validación exhaustiva de parámetros
    if (idHorario <= 0) {
      throw ApiException('ID de horario inválido');
    }

    if (idEstado < 1 || idEstado > 3) {
      throw ApiException('Estado de asistencia inválido. Valores permitidos: 1 (Presente), 2 (Ausente), 3 (Retardo)');
    }

    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(fechaAsistencia)) {
      throw ApiException('Formato de fecha inválido. Use YYYY-MM-DD');
    }

    if (!RegExp(r'^\d{2}:\d{2}:\d{2}$').hasMatch(horaAsistencia)) {
      throw ApiException('Formato de hora inválido. Use HH:MM:SS');
    }

    final url = Uri.parse('$_baseUrl/asistencias');
    final body = {
      'id_horario': idHorario,
      'id_estado': idEstado,
      'fecha_asistencia': fechaAsistencia,
      'hora_asistencia': horaAsistencia,
    };

    // Log para depuración
    debugPrint('Creando asistencia: ${url.toString()}');
    debugPrint('Datos: ${json.encode(body)}');

    final response = await _client.post(
      url,
      headers: _buildHeaders(token),
      body: json.encode(body),
    );

    // Verificar el código de estado
    if (response.statusCode != 201) {
      final errorBody = _tryParseResponse(response.body);
      throw ApiException(
        'Error al crear asistencia (${response.statusCode}): ${errorBody['message'] ?? 'Error desconocido'}',
      );
    }

    final responseBody = _tryParseResponse(response.body);

if (responseBody == null || responseBody['success'] != true) {
  throw ApiException(responseBody?['message'] ?? 'Error al actualizar asistencia');
}

    return Asistencia.fromJson(responseBody['data']);
  } on ApiException {
    rethrow;
  } catch (e) {
    throw ApiException('Error inesperado creando asistencia: ${e.toString()}');
  }
}

Future<Asistencia> updateAsistencia({
  required String token,
  required int idAsistencia,
  required int idEstado,
  required String horaAsistencia,
}) async {
  try {
    // Validación de parámetros
    if (idAsistencia <= 0) {
      throw ApiException('ID de asistencia inválido');
    }

    if (idEstado < 1 || idEstado > 3) {
      throw ApiException('Estado de asistencia inválido. Valores permitidos: 1 (Presente), 2 (Ausente), 3 (Retardo)');
    }

    if (!RegExp(r'^\d{2}:\d{2}:\d{2}$').hasMatch(horaAsistencia)) {
      throw ApiException('Formato de hora inválido. Use HH:MM:SS');
    }

    final url = Uri.parse('$_baseUrl/asistencias/$idAsistencia');
    final body = {
      'id_estado': idEstado,
      'hora_asistencia': horaAsistencia,
    };

    // Log para depuración
    debugPrint('Actualizando asistencia: ${url.toString()}');
    debugPrint('Datos: ${json.encode(body)}');

    final response = await _client.put(
      url,
      headers: _buildHeaders(token),
      body: json.encode(body),
    );

    // Verificar el código de estado
    if (response.statusCode != 200) {
      final errorBody = _tryParseResponse(response.body);
      throw ApiException(
        'Error al actualizar asistencia (${response.statusCode}): ${errorBody['message'] ?? 'Error desconocido'}',
      );
    }

    final responseBody = _tryParseResponse(response.body);

if (responseBody == null || responseBody['success'] != true) {
  throw ApiException(responseBody?['message'] ?? 'Error al actualizar asistencia');
}

final data = responseBody['data'];
if (data == null) {
  throw ApiException('Datos de asistencia no encontrados');
}
   return Asistencia.fromJson(responseBody['data']);
  } on ApiException {
    rethrow;
  } catch (e) {
    throw ApiException('Error inesperado actualizando asistencia: ${e.toString()}');
  }
}

// =============== FUNCIONES AUXILIARES ===============
dynamic _tryParseResponse(String body) {
  try {
    return json.decode(body);
  } catch (e) {
    if (body.toLowerCase().contains('<html>')) {
      throw ApiException('El servidor devolvió una página HTML. Posible error en el endpoint');
    }
    throw ApiException('Formato de respuesta inválido: ${body.length > 100 ? body.substring(0, 100) + '...' : body}');
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

  void debugPrint(String message) {
    // Puedes implementar tu propio sistema de logging aquí
    print('[DEBUG] $message');
  }

}

