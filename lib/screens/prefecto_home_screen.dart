import 'package:flutter/material.dart';
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

  // Métodos auxiliares para parseo seguro
  int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String? _parseToString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.trim();
    return value.toString().trim();
  }

  bool _parseToBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _cargarHorariosDelDia();
  }

  String _formatearFecha(DateTime fecha) {
    final dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    final meses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 
                  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    
    return '${dias[fecha.weekday - 1]} ${fecha.day} de ${meses[fecha.month - 1]}';
  }

  Future<void> _cargarHorariosDelDia() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    try {
      final response = await _apiService.getHorarios(widget.token);
      debugPrint('Respuesta de horarios: $response');
      
      final hoy = '${_fechaSeleccionada.year}-${_fechaSeleccionada.month.toString().padLeft(2, '0')}-${_fechaSeleccionada.day.toString().padLeft(2, '0')}';
      
      final horariosHoy = response.where((h) => _esHorarioParaHoy(h)).toList();
      debugPrint('Horarios filtrados para hoy: ${horariosHoy.length}');
      
      final horarios = await _procesarHorarios(horariosHoy, hoy);
      
      setState(() => _horariosHoy = horarios);
    } on ApiException catch (e) {
      debugPrint('ApiException: ${e.message}');
      if (e.stackTrace != null) {
        debugPrint('Stack trace: ${e.stackTrace}');
      }
      setState(() => _hasError = true);
      _mostrarErrorSnackbar(e.message);
    } catch (e, stackTrace) {
      debugPrint('Error inesperado: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() => _hasError = true);
      _mostrarErrorSnackbar('Error inesperado: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _esHorarioParaHoy(dynamic horario) {
    try {
      final diaHorario = _parseToString(horario['dia'])?.toUpperCase() ?? '';
      final diaActual = _obtenerDiaSemana(_fechaSeleccionada).toUpperCase();
      
      debugPrint('Comparando días - Horario: $diaHorario, Hoy: $diaActual');
      
      return diaHorario == diaActual;
    } catch (e, stackTrace) {
      debugPrint("Error comparando días: $e");
      debugPrint("Stack trace: $stackTrace");
      debugPrint("Datos del horario: $horario");
      return false;
    }
  }

  String _obtenerDiaSemana(DateTime fecha) {
    const dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return dias[fecha.weekday - 1];
  }

Future<List<Horario>> _procesarHorarios(List<dynamic> horariosHoy, String hoy) async {
  final List<Horario> result = [];
  
  try {
    final response = await _apiService.getAsistencias(
      token: widget.token,
      fecha: hoy,
    );

    final asistencias = (response['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    for (var h in horariosHoy) {
      try {
        final asistencia = asistencias.firstWhere(
          (a) => _parseToInt(a['id_horario']) == _parseToInt(h['id_horario']),
          orElse: () => <String, dynamic>{},
        );

        final horarioData = Map<String, dynamic>.from({
          ...h,
          'asistencia_registrada': asistencia.isNotEmpty,
          'estado_asistencia': asistencia.isNotEmpty 
              ? (_parseToInt(asistencia['id_estado']) == 1 ? 'PRESENTE' : 'AUSENTE')
              : null,
          'hora_registro': asistencia.isNotEmpty 
              ? _formatearHoraAsistencia(asistencia['hora_asistencia'])
              : null,
        });

        result.add(Horario.fromJson(horarioData));
      } catch (e, stackTrace) {
        debugPrint('Error procesando horario: $e');
        debugPrint('Stack trace: $stackTrace');
        
        result.add(Horario.fromJson({
          ...h,
          'asistencia_registrada': false,
          'estado_asistencia': null,
          'hora_registro': null,
        }));
      }
    }
  } catch (e, stackTrace) {
    debugPrint('Error al procesar horarios: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow;
  }

  return result;
}

  String? _formatearHoraAsistencia(dynamic hora) {
    if (hora == null) return null;
    
    try {
      if (hora is String) {
        return hora;
      } else if (hora is DateTime) {
        return '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
      } else {
        return hora.toString();
      }
    } catch (e) {
      debugPrint('Error formateando hora: $e');
      return null;
    }
  }

  void _mostrarErrorSnackbar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        action: SnackBarAction(
          label: 'Reintentar',
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

Future<void> _registrarAsistencia(Horario horario, bool asistio) async {
  if (!asistio) {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar ausencia'),
        content: const Text('¿Está seguro de marcar esta clase como ausente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
  }

  setState(() => _isLoading = true);
  try {
    final asistencia = await _apiService.createAsistencia(
      token: widget.token,
      idHorario: horario.idHorario,
      idEstado: asistio ? 1 : 2,
      fechaAsistencia: '${_fechaSeleccionada.year}-${_fechaSeleccionada.month.toString().padLeft(2, '0')}-${_fechaSeleccionada.day.toString().padLeft(2, '0')}',
      horaAsistencia: '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}',
    );

    await _cargarHorariosDelDia();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Asistencia marcada como ${asistio ? 'PRESENTE' : 'AUSENTE'}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } on ApiException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: ${e.message}'),
        duration: const Duration(seconds: 5),
      ),
    );
  } finally {
    setState(() => _isLoading = false);
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
              Navigator.pop(context); // Cierra el diálogo
              _cerrarSesion();
            },
            child: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

    void _cerrarSesion() {
    // Navega de vuelta a la pantalla de login
    Navigator.of(context).pushReplacementNamed('/login');
    
    // Opcional: Mostrar mensaje de sesión cerrada
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
      return const Center(child: CircularProgressIndicator());
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
    if (horario.asistenciaRegistrada) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estado: ${horario.estadoAsistencia}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: horario.estadoAsistencia == 'PRESENTE' 
                  ? Colors.green 
                  : Colors.red,
            ),
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
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => _registrarAsistencia(horario, true),
            child: const Text('Asistió'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => _registrarAsistencia(horario, false),
            child: const Text('Ausente'),
          ),
        ],
      );
    }
  }
}
