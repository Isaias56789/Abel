import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:io';

class RegistrarHorariosScreen extends StatefulWidget {
  final String token;
  
  const RegistrarHorariosScreen({super.key, required this.token});

  @override
  State<RegistrarHorariosScreen> createState() => _RegistrarHorarioScreenState();
}

class _RegistrarHorarioScreenState extends State<RegistrarHorariosScreen> {
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> horarios = [];
  List<Map<String, dynamic>> maestros = [];
  List<Map<String, dynamic>> asignaturas = [];
  List<Map<String, dynamic>> carreras = [];
  List<Map<String, dynamic>> grupos = [];
  List<Map<String, dynamic>> aulas = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  // Controladores
  int? _selectedMaestro;
  int? _selectedAsignatura;
  int? _selectedCarrera;
  int? _selectedGrupo;
  int? _selectedAula;
  String _selectedDia = 'Lunes';
  final TextEditingController _horaInicioController = TextEditingController();
  final TextEditingController _horaFinController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  final List<String> dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes',];

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  @override
  void dispose() {
    _horaInicioController.dispose();
    _horaFinController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _cargarHorarios(),
        _cargarMaestros(),
        _cargarAsignaturas(),
        _cargarCarreras(),
        _cargarGrupos(),
        _cargarAulas(),
      ]);
    } catch (e) {
      _mostrarError('Error al cargar datos: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cargarHorarios() async {
    try {
      final response = await http.get(
        Uri.parse('https://primera-versi-n-de-mi-api-flask-production.up.railway.app/horarios'),
        headers: _buildHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData is List) {
          setState(() {
            horarios = List<Map<String, dynamic>>.from(responseData);
          });
        } else if (responseData is Map && responseData.containsKey('data')) {
          setState(() {
            horarios = List<Map<String, dynamic>>.from(responseData['data']);
          });
        } else {
          throw Exception('Formato de respuesta no reconocido');
        }
      } else {
        throw Exception('Error al cargar horarios: ${response.statusCode}');
      }
    } on TimeoutException {
      _mostrarError('Tiempo de espera agotado al cargar horarios');
    } catch (e) {
      _mostrarError('Error al cargar horarios: ${e.toString()}');
      if (mounted && horarios.isEmpty) {
        setState(() => horarios = []);
      }
    }
  }

  Future<void> _cargarMaestros() async {
    try {
      final response = await http.get(
        Uri.parse('https://primera-versi-n-de-mi-api-flask-production.up.railway.app/maestros'),
        headers: _buildHeaders(),
      );

      if (response.statusCode == 200) {
        setState(() {
          maestros = List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      } else {
        throw Exception('Error al cargar maestros: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al cargar maestros: ${e.toString()}');
    }
  }

  Future<void> _cargarAsignaturas() async {
    try {
      final response = await http.get(
        Uri.parse('https://primera-versi-n-de-mi-api-flask-production.up.railway.app/asignaturas'),
        headers: _buildHeaders(),
      );

      if (response.statusCode == 200) {
        setState(() {
          asignaturas = List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      } else {
        throw Exception('Error al cargar asignaturas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al cargar asignaturas: ${e.toString()}');
    }
  }

  Future<void> _cargarCarreras() async {
    try {
      final response = await http.get(
        Uri.parse('https://primera-versi-n-de-mi-api-flask-production.up.railway.app/carreras'),
        headers: _buildHeaders(),
      );

      if (response.statusCode == 200) {
        setState(() {
          carreras = List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      } else {
        throw Exception('Error al cargar carreras: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al cargar carreras: ${e.toString()}');
    }
  }

  Future<void> _cargarGrupos() async {
    try {
      final response = await http.get(
        Uri.parse('https://primera-versi-n-de-mi-api-flask-production.up.railway.app/grupos'),
        headers: _buildHeaders(),
      );

      if (response.statusCode == 200) {
        setState(() {
          grupos = List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      } else {
        throw Exception('Error al cargar grupos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al cargar grupos: ${e.toString()}');
    }
  }

  Future<void> _cargarAulas() async {
    try {
      final response = await http.get(
        Uri.parse('https://primera-versi-n-de-mi-api-flask-production.up.railway.app/aulas'),
        headers: _buildHeaders(),
      );

      if (response.statusCode == 200) {
        setState(() {
          aulas = List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      } else {
        throw Exception('Error al cargar aulas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al cargar aulas: ${e.toString()}');
    }
  }

  Map<String, String> _buildHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${widget.token}',
    };
  }

  Future<void> _registrarHorario() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedMaestro == null ||
        _selectedAsignatura == null ||
        _selectedCarrera == null ||
        _selectedGrupo == null ||
        _selectedAula == null) {
      _mostrarError('Por favor complete todos los campos');
      return;
    }

    try {
      _validarHoras();
    } catch (e) {
      _mostrarError(e.toString());
      return;
    }

    setState(() => _isSubmitting = true);
    
    try {
      final response = await http.post(
        Uri.parse('https://primera-versi-n-de-mi-api-flask-production.up.railway.app/horarios'),
        headers: _buildHeaders(),
        body: json.encode({
          'id_maestro': _selectedMaestro,
          'id_asignatura': _selectedAsignatura,
          'id_carrera': _selectedCarrera,
          'id_grupo': _selectedGrupo,
          'id_aula': _selectedAula,
          'dia': _selectedDia,
          'hora_inicio': _horaInicioController.text.trim(),
          'hora_fin': _horaFinController.text.trim(),
        }),
      ).timeout(const Duration(seconds: 30));

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 201) {
        _mostrarExito('Horario registrado exitosamente');
        _limpiarFormulario();
        await _cargarHorarios();
      } else {
        throw _parsearError(responseData);
      }
    } on TimeoutException {
      _mostrarError('El servidor está tardando demasiado en responder');
    } on SocketException {
      _mostrarError('No se pudo conectar al servidor');
    } on http.ClientException catch (e) {
      _mostrarError('Error de conexión: ${e.message}');
    } catch (e) {
      _mostrarError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _validarHoras() {
    if (_horaInicioController.text.isNotEmpty && 
        _horaFinController.text.isNotEmpty) {
      final inicio = _horaInicioController.text.split(':');
      final fin = _horaFinController.text.split(':');
      
      final horaInicio = int.parse(inicio[0]);
      final minutoInicio = int.parse(inicio[1]);
      final horaFin = int.parse(fin[0]);
      final minutoFin = int.parse(fin[1]);
      
      if (horaFin < horaInicio || 
          (horaFin == horaInicio && minutoFin <= minutoInicio)) {
        throw Exception('Hora fin debe ser mayor que hora inicio');
      }
    }
  }

  String _parsearError(dynamic responseData) {
    if (responseData is Map) {
      if (responseData['message'] != null) {
        return responseData['message'];
      }
      if (responseData['errors'] != null) {
        if (responseData['errors'] is List) {
          return responseData['errors'].join(', ');
        }
        return responseData['errors'].toString();
      }
    }
    return 'Error al procesar la solicitud';
  }

  Future<void> _editarHorario(int id) async {
    try {
      final horario = horarios.firstWhere((h) => h['id_horario'] == id);
      
      final editado = await showDialog<bool>(
        context: context,
        builder: (context) => Dialog(
          child: EditarHorarioForm(
            horario: {
              ...horario,
              'hora_inicio': _parseTimeFromBackend(horario['hora_inicio']),
              'hora_fin': _parseTimeFromBackend(horario['hora_fin']),
            },
            token: widget.token,
            maestros: maestros,
            asignaturas: asignaturas,
            carreras: carreras,
            grupos: grupos,
            aulas: aulas,
            dias: dias,
          ),
        ),
      );

      if (editado == true) {
        await _cargarHorarios();
        _mostrarExito('Horario actualizado correctamente');
      }
    } catch (e) {
      _mostrarError('Error al editar horario: ${e.toString()}');
    }
  }

  dynamic _parseTimeFromBackend(dynamic time) {
    if (time == null) return null;
    
    // Si ya está en formato HH:mm
    if (time is String && time.contains(':')) {
      return time;
    }
    
    // Si es un número (segundos o formato decimal)
    if (time is num || (time is String && num.tryParse(time.toString()) != null)) {
      final totalSeconds = double.tryParse(time.toString()) ?? 0;
      final hours = (totalSeconds / 3600).floor();
      final minutes = ((totalSeconds % 3600) / 60).floor();
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    }
    
    return '00:00'; // Valor por defecto
  }

  Future<void> _borrarHorario(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de eliminar este horario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.delete(
        Uri.parse('https://primera-versi-n-de-mi-api-flask-production.up.railway.app/horarios/$id'),
        headers: _buildHeaders(),
      );

      if (response.statusCode == 200) {
        _mostrarExito('Horario eliminado exitosamente');
        await _cargarHorarios();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Error al eliminar horario');
      }
    } catch (e) {
      _mostrarError('Error al eliminar horario: ${e.toString()}');
    }
  }

  void _limpiarFormulario() {
    _formKey.currentState?.reset();
    _selectedMaestro = null;
    _selectedAsignatura = null;
    _selectedCarrera = null;
    _selectedGrupo = null;
    _selectedAula = null;
    _selectedDia = 'Lunes';
    _horaInicioController.clear();
    _horaFinController.clear();
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _mostrarError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  List<Map<String, dynamic>> _filtrarHorarios() {
    if (_searchController.text.isEmpty) {
      return horarios;
    }
    
    final query = _searchController.text.toLowerCase();
    return horarios.where((horario) =>
      (horario['nombre_asignatura']?.toString().toLowerCase() ?? '').contains(query) ||
      (horario['maestro_nombre']?.toString().toLowerCase() ?? '').contains(query) ||
      (horario['maestro_apellido']?.toString().toLowerCase() ?? '').contains(query) ||
      (horario['grupo']?.toString().toLowerCase() ?? '').contains(query) ||
      (horario['carrera']?.toString().toLowerCase() ?? '').contains(query) ||
      (horario['aula']?.toString().toLowerCase() ?? '').contains(query) ||
      (horario['dia']?.toString().toLowerCase() ?? '').contains(query) ||
      (horario['hora_inicio']?.toString().toLowerCase() ?? '').contains(query) ||
      (horario['hora_fin']?.toString().toLowerCase() ?? '').contains(query)
    ).toList();
  }

  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    TimeOfDay initialTime = TimeOfDay.now();
    
    if (controller.text.isNotEmpty) {
      try {
        final parts = controller.text.split(':');
        initialTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      } catch (e) {
        print('Error parsing time: $e');
      }
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF64A6E3),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      controller.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final horariosFiltrados = _filtrarHorarios();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Horarios'),
        backgroundColor: const Color(0xFF64A6E3),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatosIniciales,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Buscar horarios',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                Expanded(
                  child: _buildHorariosList(horariosFiltrados),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF64A6E3),
        onPressed: () => _mostrarFormulario(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHorariosList(List<Map<String, dynamic>> horarios) {
    if (horarios.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isEmpty 
              ? 'No hay horarios registrados' 
              : 'No se encontraron resultados',
          style: const TextStyle(fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: horarios.length,
      itemBuilder: (context, index) {
        final horario = horarios[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              horario['nombre_asignatura'] ?? 'Sin nombre',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Maestro: ${horario['maestro_nombre'] ?? ''} ${horario['maestro_apellido'] ?? ''}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Grupo: ${horario['grupo'] ?? ''} - ${horario['carrera'] ?? ''}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Aula: ${horario['aula'] ?? ''}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Horario: ${horario['dia'] ?? ''} ${_parseTimeFromBackend(horario['hora_inicio']) ?? ''} - ${_parseTimeFromBackend(horario['hora_fin']) ?? ''}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editarHorario(horario['id_horario']),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _borrarHorario(horario['id_horario']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _mostrarFormulario(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Nuevo Horario',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDropdown(
                    label: 'Maestro',
                    value: _selectedMaestro,
                    items: maestros.map((maestro) {
                      return DropdownMenuItem<int>(
                        value: maestro['id_maestro'],
                        child: Text('${maestro['nombre']} ${maestro['apellido']}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMaestro = value;
                      });
                    },
                  ),
                  _buildDropdown(
                    label: 'Asignatura',
                    value: _selectedAsignatura,
                    items: asignaturas.map((asignatura) {
                      return DropdownMenuItem<int>(
                        value: asignatura['id_asignatura'],
                        child: Text(asignatura['nombre_asignatura']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedAsignatura = value;
                      });
                    },
                  ),
                  _buildDropdown(
                    label: 'Carrera',
                    value: _selectedCarrera,
                    items: carreras.map((carrera) {
                      return DropdownMenuItem<int>(
                        value: carrera['id_carrera'],
                        child: Text(carrera['carrera']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCarrera = value;
                      });
                    },
                  ),
                  _buildDropdown(
                    label: 'Grupo',
                    value: _selectedGrupo,
                    items: grupos.map((grupo) {
                      return DropdownMenuItem<int>(
                        value: grupo['id_grupo'],
                        child: Text(grupo['grupo']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedGrupo = value;
                      });
                    },
                  ),
                  _buildDropdown(
                    label: 'Aula',
                    value: _selectedAula,
                    items: aulas.map((aula) {
                      return DropdownMenuItem<int>(
                        value: aula['id_aula'],
                        child: Text(aula['aula']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedAula = value;
                      });
                    },
                  ),
                  _buildDropdown<String>(
                    label: 'Día',
                    value: _selectedDia,
                    items: dias.map((dia) {
                      return DropdownMenuItem<String>(
                        value: dia,
                        child: Text(dia),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDia = value!;
                      });
                    },
                  ),
                  _buildTimeField(
                    label: 'Hora de Inicio',
                    controller: _horaInicioController,
                    context: context,
                  ),
                  _buildTimeField(
                    label: 'Hora de Fin',
                    controller: _horaFinController,
                    context: context,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF64A6E3),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isSubmitting ? null : _registrarHorario,
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Guardar Horario',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<T>(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        value: value,
        items: items,
        onChanged: onChanged,
        validator: (value) => value == null ? 'Seleccione una opción' : null,
      ),
    );
  }

  Widget _buildTimeField({
    required String label,
    required TextEditingController controller,
    required BuildContext context,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.grey[100],
          suffixIcon: IconButton(
            icon: const Icon(Icons.access_time),
            onPressed: () => _selectTime(context, controller),
          ),
        ),
        readOnly: true,
        onTap: () => _selectTime(context, controller),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor seleccione una hora';
          }
          if (!RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$').hasMatch(value)) {
            return 'Formato inválido (HH:MM)';
          }
          return null;
        },
      ),
    );
  }
}

class EditarHorarioForm extends StatefulWidget {
  final Map<String, dynamic> horario;
  final String token;
  final List<Map<String, dynamic>> maestros;
  final List<Map<String, dynamic>> asignaturas;
  final List<Map<String, dynamic>> carreras;
  final List<Map<String, dynamic>> grupos;
  final List<Map<String, dynamic>> aulas;
  final List<String> dias;

  const EditarHorarioForm({
    super.key,
    required this.horario,
    required this.token,
    required this.maestros,
    required this.asignaturas,
    required this.carreras,
    required this.grupos,
    required this.aulas,
    required this.dias,
  });

  @override
  State<EditarHorarioForm> createState() => _EditarHorarioFormState();
}

class _EditarHorarioFormState extends State<EditarHorarioForm> {
  final _formKey = GlobalKey<FormState>();
  late int? selectedMaestro;
  late int? selectedAsignatura;
  late int? selectedCarrera;
  late int? selectedGrupo;
  late int? selectedAula;
  late String selectedDia;
  final TextEditingController _horaInicioController = TextEditingController();
  final TextEditingController _horaFinController = TextEditingController();
  bool _isSubmitting = false;

    void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }


  @override
  
  void initState() {
    super.initState();
    
    selectedMaestro = widget.horario['id_maestro'] != null ? int.tryParse(widget.horario['id_maestro'].toString()) : null;
    selectedAsignatura = widget.horario['id_asignatura'] != null ? int.tryParse(widget.horario['id_asignatura'].toString()) : null;
    selectedCarrera = widget.horario['id_carrera'] != null ? int.tryParse(widget.horario['id_carrera'].toString()) : null;
    selectedGrupo = widget.horario['id_grupo'] != null ? int.tryParse(widget.horario['id_grupo'].toString()) : null;
    selectedAula = widget.horario['id_aula'] != null ? int.tryParse(widget.horario['id_aula'].toString()) : null;
    
    selectedDia = widget.horario['dia']?.toString() ?? 'Lunes';
    
    _horaInicioController.text = _formatTime(widget.horario['hora_inicio']);
    _horaFinController.text = _formatTime(widget.horario['hora_fin']);
  }

  String _formatTime(dynamic timeValue) {
    if (timeValue == null) return '00:00';

    // Si ya está en formato HH:mm
    if (timeValue is String && timeValue.contains(':')) {
      return timeValue.length >= 5 ? timeValue.substring(0, 5) : timeValue;
    }

    // Si es un número (segundos o formato decimal)
    if (timeValue is num || (timeValue is String && num.tryParse(timeValue.toString()) != null)) {
      final totalSeconds = double.tryParse(timeValue.toString()) ?? 0;
      final hours = (totalSeconds / 3600).floor();
      final minutes = ((totalSeconds % 3600) / 60).floor();
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    }

    return '00:00'; // Valor por defecto
  }

  String _convertDecimalTime(String decimalTime) {
    try {
      final totalSeconds = double.parse(decimalTime);
      final hours = (totalSeconds / 3600).floor();
      final minutes = ((totalSeconds % 3600) / 60).floor();
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    } catch (e) {
      print('Error convirtiendo tiempo decimal: $e');
      return '00:00';
    }
  }


  @override
  void dispose() {
    _horaInicioController.dispose();
    _horaFinController.dispose();
    super.dispose();
  }

Future<void> _actualizarHorario() async {
  if (!_formKey.currentState!.validate()) {
    _mostrarError('Por favor complete todos los campos correctamente');
    return;
  }

  try {
    _validarHoras();
  } catch (e) {
    _mostrarError(e.toString());
    return;
  }

  setState(() => _isSubmitting = true);
  
  try {
    // Preparar datos para enviar
    final datosActualizacion = {
      'id_maestro': selectedMaestro,
      'id_asignatura': selectedAsignatura,
      'id_carrera': selectedCarrera,
      'id_grupo': selectedGrupo,
      'id_aula': selectedAula,
      'dia': selectedDia,
      'hora_inicio': _horaInicioController.text.trim(),
      'hora_fin': _horaFinController.text.trim(),
    };

    print('Enviando datos de actualización: $datosActualizacion'); // Debug

    final response = await http.put(
        Uri.parse('https://primera-versi-n-de-mi-api-flask-production.up.railway.app/horarios/${widget.horario['id_horario']}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: json.encode(datosActualizacion),
    ).timeout(const Duration(seconds: 30));

    final responseData = json.decode(response.body);
    print('Respuesta del servidor: ${response.statusCode} - $responseData'); // Debug

    if (response.statusCode == 200) {
      _mostrarExito(responseData['message'] ?? 'Horario actualizado exitosamente');
      Navigator.pop(context, true);
    } else {
      throw Exception(responseData['message'] ?? 
                   'Error al actualizar (${response.statusCode})');
    }
  } on TimeoutException {
    _mostrarError('El servidor no respondió a tiempo');
  } on SocketException {
    _mostrarError('No hay conexión a internet');
  } on http.ClientException catch (e) {
    _mostrarError('Error de conexión: ${e.message}');
  } catch (e) {
    _mostrarError('Error al actualizar horario: ${e.toString().replaceAll('Exception: ', '')}');
  } finally {
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }
}

  void _validarHoras() {
    if (_horaInicioController.text.isNotEmpty && 
        _horaFinController.text.isNotEmpty) {
      final inicio = _horaInicioController.text.split(':');
      final fin = _horaFinController.text.split(':');
      
      final horaInicio = int.parse(inicio[0]);
      final minutoInicio = int.parse(inicio[1]);
      final horaFin = int.parse(fin[0]);
      final minutoFin = int.parse(fin[1]);
      
      if (horaFin < horaInicio || 
          (horaFin == horaInicio && minutoFin <= minutoInicio)) {
        throw Exception('Hora fin debe ser mayor que hora inicio');
      }
    }
  }

  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    TimeOfDay initialTime = TimeOfDay.now();
    
    if (controller.text.isNotEmpty) {
      try {
        final parts = controller.text.split(':');
        initialTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      } catch (e) {
        print('Error parsing time: $e');
      }
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF64A6E3),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      controller.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Editar Horario',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildDropdown(
              label: 'Maestro',
              value: selectedMaestro,
              items: widget.maestros.map((maestro) {
                return DropdownMenuItem<int>(
                  value: maestro['id_maestro'],
                  child: Text('${maestro['nombre']} ${maestro['apellido']}'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedMaestro = value;
                });
              },
            ),
            _buildDropdown(
              label: 'Asignatura',
              value: selectedAsignatura,
              items: widget.asignaturas.map((asignatura) {
                return DropdownMenuItem<int>(
                  value: asignatura['id_asignatura'],
                  child: Text(asignatura['nombre_asignatura']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedAsignatura = value;
                });
              },
            ),
            _buildDropdown(
              label: 'Carrera',
              value: selectedCarrera,
              items: widget.carreras.map((carrera) {
                return DropdownMenuItem<int>(
                  value: carrera['id_carrera'],
                  child: Text(carrera['carrera']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCarrera = value;
                });
              },
            ),
            _buildDropdown(
              label: 'Grupo',
              value: selectedGrupo,
              items: widget.grupos.map((grupo) {
                return DropdownMenuItem<int>(
                  value: grupo['id_grupo'],
                  child: Text(grupo['grupo']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedGrupo = value;
                });
              },
            ),
            _buildDropdown(
              label: 'Aula',
              value: selectedAula,
              items: widget.aulas.map((aula) {
                return DropdownMenuItem<int>(
                  value: aula['id_aula'],
                  child: Text(aula['aula']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedAula = value;
                });
              },
            ),
            _buildDropdown<String>(
              label: 'Día',
              value: selectedDia,
              items: widget.dias.map((dia) {
                return DropdownMenuItem<String>(
                  value: dia,
                  child: Text(dia),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedDia = value!;
                });
              },
            ),
            _buildTimeField(
              label: 'Hora de Inicio',
              controller: _horaInicioController,
              context: context,
            ),
            _buildTimeField(
              label: 'Hora de Fin',
              controller: _horaFinController,
              context: context,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF64A6E3),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isSubmitting ? null : _actualizarHorario,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Guardar Cambios'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<T>(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        value: value,
        items: items,
        onChanged: onChanged,
        validator: (value) => value == null ? 'Seleccione una opción' : null,
      ),
    );
  }

  Widget _buildTimeField({
    required String label,
    required TextEditingController controller,
    required BuildContext context,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[100],
          suffixIcon: IconButton(
            icon: const Icon(Icons.access_time),
            onPressed: () => _selectTime(context, controller),
          ),
        ),
        readOnly: true,
        onTap: () => _selectTime(context, controller),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor seleccione una hora';
          }
          if (!RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$').hasMatch(value)) {
            return 'Formato inválido (HH:MM)';
          }
          return null;
        },
      ),
    );
  }
}