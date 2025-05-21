import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prefectura_1/models/horario_model.dart';
import 'package:prefectura_1/services/api_service.dart';
import 'package:prefectura_1/exceptions/api_exception.dart';

class PrefectoHomeScreen extends StatefulWidget {
  final String token;
  
  const PrefectoHomeScreen({super.key, required this.token});

  @override
  State<PrefectoHomeScreen> createState() => _PrefectoHomeScreenState();
}

class _PrefectoHomeScreenState extends State<PrefectoHomeScreen> {
  final ApiService _apiService = ApiService();
  List<Horario> _horariosHoy = [];
  bool _isLoading = true;
  bool _hasError = false;
  DateTime _fechaSeleccionada = DateTime.now();

  final Map<int, String> _estadosAsistencia = {
    1: 'PRESENTE',
    2: 'AUSENTE',
  
  };

  final Map<int, Color> _coloresEstado = {
    1: Colors.green,
    2: Colors.red,
    
  };

  final Map<int, IconData> _iconosEstado = {
    1: Icons.check_circle,
    2: Icons.cancel,
    3: Icons.access_time
  };

  @override
  void initState() {
    super.initState();
    _cargarHorariosDelDia();
  }

  int _parseToInt(dynamic value) => value?.toInt() ?? 0;

  String? _parseToString(dynamic value) => value?.toString().trim();

  bool _parseToBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  String _formatearFecha(DateTime fecha) {
    final dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes',];
    final meses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 
                  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    return '${dias[fecha.weekday - 1]} ${fecha.day} de ${meses[fecha.month - 1]}';
  }

  String _formatearFechaAPI(DateTime fecha) {
    return '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
  }
  Future<void> _cargarHorariosDelDia() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    try {
      final response = await _apiService.getHorarios(widget.token);
      
      if (response == null || response is! List) {
        throw ApiException('Formato de respuesta inválido para horarios');
      }
      
      final horariosHoy = response.where((h) => _esHorarioParaHoy(h)).toList();
      final horarios = await _procesarHorarios(horariosHoy, _formatearFechaAPI(_fechaSeleccionada));
      
      setState(() => _horariosHoy = horarios);
    } on ApiException catch (e) {
      setState(() => _hasError = true);
      _mostrarErrorSnackbar(e.message);
    } catch (e) {
      setState(() => _hasError = true);
      _mostrarErrorSnackbar('Error al cargar los horarios');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _esHorarioParaHoy(dynamic horario) {
    try {
      final Map<String, dynamic> horarioMap = _convertToMap(horario);
      final diaHorario = _parseToString(horarioMap['dia'])?.toUpperCase() ?? '';
      final diaActual = _obtenerDiaSemana(_fechaSeleccionada).toUpperCase();
      return diaHorario == diaActual;
    } catch (e) {
      return false;
    }
  }

  Map<String, dynamic> _convertToMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  String _obtenerDiaSemana(DateTime fecha) {
    const dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes',];
    return dias[fecha.weekday - 1];
  }

Future<List<Horario>> _procesarHorarios(List<dynamic> horariosHoy, String hoy) async {
  final List<Horario> result = [];
  
  try {
    debugPrint('Solicitando asistencias para fecha: $hoy');
    
    final response = await _apiService.getAsistencias(
      token: widget.token,
      fecha: hoy,
    );

    debugPrint('Respuesta de asistencias: $response');

    final responseMap = _convertToMap(response);
    final asistencias = responseMap.containsKey('data')
        ? (responseMap['data'] as List?)?.map((e) => _convertToMap(e)).toList() ?? []
        : [];

    debugPrint('Asistencias encontradas: ${asistencias.length}');

    for (var h in horariosHoy) {
      try {
        final horarioMap = _convertToMap(h);
        final idHorario = _parseToInt(horarioMap['id_horario']);
        Map<String, dynamic>? asistencia;
        
        if (asistencias.isNotEmpty) {
          asistencia = asistencias.firstWhere(
            (a) => _parseToInt(a['id_horario']) == idHorario,
            orElse: () => <String, dynamic>{},
          );
        }

        final bool asistenciaRegistrada = asistencia != null && asistencia.isNotEmpty;

        debugPrint('Horario $idHorario - Asistencia registrada: $asistenciaRegistrada');

        final horarioData = {
          ...horarioMap,
          'asistencia_registrada': asistenciaRegistrada,
          'id_estado': asistenciaRegistrada ? _parseToInt(asistencia!['id_estado']) : null,
          'id_asistencia': asistenciaRegistrada ? _parseToInt(asistencia!['id_asistencia']) : null,
          'hora_registro': asistenciaRegistrada
              ? _formatearHoraAsistencia(asistencia!['hora_asistencia'])
              : null,
        };

        result.add(Horario.fromJson(horarioData));
      } catch (e) {
        debugPrint('Error procesando horario: $e');
        final horarioMap = _convertToMap(h);
        result.add(Horario.fromJson({
          ...horarioMap,
          'asistencia_registrada': false,
          'id_estado': null,
          'id_asistencia': null,
          'hora_registro': null,
        }));
      }
    }
  } catch (e, stackTrace) {
    debugPrint('Error al procesar horarios: $e');
    debugPrint('Stack trace: $stackTrace');
    for (var h in horariosHoy) {
      final horarioMap = _convertToMap(h);
      result.add(Horario.fromJson({
        ...horarioMap,
        'asistencia_registrada': false,
        'id_estado': null,
        'id_asistencia': null,
        'hora_registro': null,
      }));
    }
  }

  return result;
}

  String? _formatearHoraAsistencia(dynamic hora) {
    if (hora == null) return null;
    if (hora is String) return hora.length > 5 ? hora.substring(0, 5) : hora;
    if (hora is DateTime) {
      return '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
    }
    return hora.toString();
  }

  bool _esClaseDeHoy(Horario horario) {
    final hoy = DateTime.now();
    final fechaHorario = DateTime(
      _fechaSeleccionada.year,
      _fechaSeleccionada.month,
      _fechaSeleccionada.day,
    );
    return hoy.isAtSameMomentAs(fechaHorario) || hoy.isAfter(fechaHorario);
  }

Future<void> _manejarAsistencia(Horario horario, int estado) async {
  if (!_esClaseDeHoy(horario)) {
    _mostrarErrorSnackbar('Solo puedes registrar asistencias para clases de hoy');
    return;
  }

  setState(() => _isLoading = true);
  
  try {
    final hoy = _formatearFechaAPI(_fechaSeleccionada);
    final ahora = DateFormat('HH:mm:ss').format(DateTime.now());

    dynamic response;
    
    if (horario.asistenciaRegistrada && horario.idAsistencia != null) {
      // DEBUG LOG
      debugPrint('Actualizando asistencia para horario ${horario.idHorario} con estado $estado');
      
      response = await _apiService.updateAsistencia(
        token: widget.token,
        idAsistencia: horario.idAsistencia!,
        idEstado: estado,
        horaAsistencia: ahora,
      );
    } else {
      // DEBUG LOG
      debugPrint('Creando nueva asistencia para horario ${horario.idHorario}');
      
      response = await _apiService.createAsistencia(
        token: widget.token,
        idHorario: horario.idHorario,
        idEstado: estado,
        fechaAsistencia: hoy,
        horaAsistencia: ahora,
      );
    }

    // DEBUG LOG de la respuesta
    debugPrint('Respuesta del servidor: $response');

    // Forzar recarga de datos
    await _cargarHorariosDelDia();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Asistencia ${horario.asistenciaRegistrada ? 'actualizada' : 'registrada'} como ${_estadosAsistencia[estado]}'),
        backgroundColor: _coloresEstado[estado],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  } on ApiException catch (e) {
    _mostrarErrorSnackbar('Esta seguro de que desea marcar esa asistencia?');
  } catch (e, stackTrace) {
    debugPrint('Error completo: $e');
    debugPrint('Stack trace: $stackTrace');
    _mostrarErrorSnackbar('Error inesperado: ${e.toString()}');
  } finally {
    setState(() => _isLoading = false);
  }
}
  void _mostrarErrorSnackbar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: const Color.fromARGB(255, 8, 107, 153),
        action: SnackBarAction(
          label: 'Aceptar',
          textColor: Colors.white,
          onPressed: _cargarHorariosDelDia,
        ),
      ),
    );
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF64A6E3),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _fechaSeleccionada) {
      setState(() => _fechaSeleccionada = picked);
      await _cargarHorariosDelDia();
    }
  }

  void _confirmarCierreSesion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cerrarSesion();
            },
            child: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _cerrarSesion() {
    Navigator.of(context).pushReplacementNamed('/login');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sesión cerrada correctamente'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Panel Prefecto'),
            Text(
              _formatearFecha(_fechaSeleccionada),
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF64A6E3),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _seleccionarFecha(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _confirmarCierreSesion,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFB8D1E7),
              Color(0xFF8FBFEC),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _cargarHorariosDelDia,
          child: _buildBodyContent(),
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF64A6E3)),
        ),
      );
    }
    
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 50, color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar los horarios',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarHorariosDelDia,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF64A6E3),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    
    if (_horariosHoy.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.schedule, size: 50, color: Colors.white54),
            const SizedBox(height: 16),
            Text(
              'No hay clases programadas para ${_formatearFecha(_fechaSeleccionada).toLowerCase()}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
              onPressed: _confirmarCierreSesion,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _horariosHoy.length,
      itemBuilder: (context, index) => _buildHorarioCard(_horariosHoy[index]),
    );
  }

  Widget _buildHorarioCard(Horario horario) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${horario.horaInicio} - ${horario.horaFin}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0960AE),
                  ),
                ),
                Chip(
                  label: Text('Aula: ${horario.aula}'),
                  backgroundColor: Colors.grey[200],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              horario.asignatura,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Grupo: ${horario.grupo} | Carrera: ${horario.carrera}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Maestro: ${horario.maestro}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildAsistenciaSection(horario),
          ],
        ),
      ),
    );
  }

  Widget _buildAsistenciaSection(Horario horario) {
    final puedeEditar = _esClaseDeHoy(horario);
    
    if (horario.asistenciaRegistrada && horario.idEstado != null) {
      final estado = horario.idEstado!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_iconosEstado[estado], color: _coloresEstado[estado]),
              const SizedBox(width: 8),
              Text(
                'Estado: ${_estadosAsistencia[estado]}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _coloresEstado[estado],
                ),
              ),
            ],
          ),
          if (horario.horaRegistro != null) ...[
            const SizedBox(height: 4),
            Text(
              'Registrado a las: ${horario.horaRegistro}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
          if (puedeEditar) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _estadosAsistencia.entries.map((entry) {
                final estado = entry.key;
                if (estado == horario.idEstado) return const SizedBox.shrink();
                
                return ActionChip(
                  avatar: Icon(_iconosEstado[estado], size: 18),
                  label: Text('Cambiar a ${entry.value}'),
                  onPressed: () => _manejarAsistencia(horario, estado),
                  backgroundColor: _coloresEstado[estado]!.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: _coloresEstado[estado],
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      );
    } else {
      return Column(
        children: [
          const Text(
            'Registrar asistencia:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _estadosAsistencia.entries.map((entry) {
              final estado = entry.key;
              return ElevatedButton.icon(
                icon: Icon(_iconosEstado[estado], size: 18),
                label: Text(entry.value),
                style: ElevatedButton.styleFrom(
                  backgroundColor: puedeEditar 
                      ? _coloresEstado[estado]
                      : Colors.grey,
                  foregroundColor: Colors.white,
                ),
                onPressed: puedeEditar 
                    ? () => _manejarAsistencia(horario, estado)
                    : null,
              );
            }).toList(),
          ),
          if (!puedeEditar) ...[
            const SizedBox(height: 8),
            Text(
              'Solo puedes registrar asistencias para clases de hoy',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      );
    }
  }
  
}