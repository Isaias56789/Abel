import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegistrarCarrerasScreen extends StatefulWidget {
  final String token;
  
  const RegistrarCarrerasScreen({super.key, required this.token});

  @override
  State<RegistrarCarrerasScreen> createState() => _CarrerasScreenState();
}

class _CarrerasScreenState extends State<RegistrarCarrerasScreen> {
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> carreras = [];
  bool _isLoading = true;
  final TextEditingController _nombreController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarCarreras();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _cargarCarreras() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://primera-versi-n-de-mi-api-flask-production.up.railway.app/carreras'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          carreras = List<Map<String, dynamic>>.from(json.decode(response.body));
          _isLoading = false;
        });
      } else {
        throw Exception('Error al cargar carreras: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarError('Error al cargar carreras: ${e.toString()}');
    }
  }

  Future<void> _registrarCarrera() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await http.post(
          Uri.parse('https://primera-versi-n-de-mi-api-flask-production.up.railway.app/carreras'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
          body: json.encode({
            'carrera': _nombreController.text.trim(),
          }),
        );

        if (response.statusCode == 201) {
          _mostrarExito('Carrera registrada exitosamente');
          _nombreController.clear();
          await _cargarCarreras();
        } else {
          final errorData = json.decode(response.body);
          throw Exception(errorData['message'] ?? 'Error al registrar carrera');
        }
      } catch (e) {
        _mostrarError('Error al registrar carrera: ${e.toString()}');
      }
    }
  }

  Future<void> _editarCarrera(int id) async {
    final carrera = carreras.firstWhere((c) => c['id_carrera'] == id);
    final nuevoNombre = await _mostrarDialogoEdicion(carrera['carrera']);
    
    if (nuevoNombre != null && nuevoNombre.isNotEmpty && nuevoNombre != carrera['carrera']) {
      try {
        final response = await http.put(
          Uri.parse('https://primera-versi-n-de-mi-api-flask-production.up.railway.app/carreras/$id'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
          body: json.encode({'carrera': nuevoNombre}),
        );

        if (response.statusCode == 200) {
          _mostrarExito('Carrera actualizada exitosamente');
          await _cargarCarreras();
        } else {
          final errorData = json.decode(response.body);
          throw Exception(errorData['message'] ?? 'Error al actualizar carrera');
        }
      } catch (e) {
        _mostrarError('Error al actualizar carrera: ${e.toString()}');
      }
    }
  }

  Future<void> _borrarCarrera(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de eliminar esta carrera? Esta acción no se puede deshacer.'),
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

    if (confirm == true) {
      try {
        final response = await http.delete(
          Uri.parse('https://primera-versi-n-de-mi-api-flask-production.up.railway.app/carreras/$id'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
        );

        if (response.statusCode == 200) {
          _mostrarExito('Carrera eliminada exitosamente');
          await _cargarCarreras();
        } else {
          final errorData = json.decode(response.body);
          throw Exception(errorData['message'] ?? 'Error al eliminar carrera');
        }
      } catch (e) {
        _mostrarError('Error al eliminar carrera: ${e.toString()}');
      }
    }
  }

  Future<String?> _mostrarDialogoEdicion(String nombreActual) async {
    final controller = TextEditingController(text: nombreActual);
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Carrera'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nombre de la carrera',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Carreras'),
        backgroundColor: const Color(0xFF64A6E3),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarCarreras,
            tooltip: 'Recargar',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CarreraSearchDelegate(
                  carreras: carreras,
                  onEdit: _editarCarrera,
                  onDelete: _borrarCarrera,
                ),
              );
            },
            tooltip: 'Buscar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nombreController,
                              decoration: InputDecoration(
                                labelText: 'Nombre de la carrera',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () => _nombreController.clear(),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Por favor ingrese un nombre válido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.save),
                              label: const Text('Registrar Carrera'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF64A6E3),
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _registrarCarrera,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: carreras.length,
                      itemBuilder: (context, index) {
                        final carrera = carreras[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 2,
                          child: ListTile(
                            title: Text(
                              carrera['carrera'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('ID: ${carrera['id_carrera']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _editarCarrera(carrera['id_carrera']),
                                  tooltip: 'Editar',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _borrarCarrera(carrera['id_carrera']),
                                  tooltip: 'Eliminar',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class CarreraSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> carreras;
  final Function(int) onEdit;
  final Function(int) onDelete;

  CarreraSearchDelegate({
    required this.carreras, 
    required this.onEdit, 
    required this.onDelete,
  });

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
        tooltip: 'Limpiar',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
      tooltip: 'Regresar',
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildResultados();
  @override
  Widget buildSuggestions(BuildContext context) => _buildResultados();

  Widget _buildResultados() {
    final results = query.isEmpty
        ? carreras
        : carreras.where((c) => 
            c['carrera'].toLowerCase().contains(query.toLowerCase()) ||
            c['id_carrera'].toString().contains(query)).toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No se encontraron resultados para "$query"',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final carrera = results[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          elevation: 2,
          child: ListTile(
            title: Text(
              carrera['carrera'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('ID: ${carrera['id_carrera']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => onEdit(carrera['id_carrera']),
                  tooltip: 'Editar',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => onDelete(carrera['id_carrera']),
                  tooltip: 'Eliminar',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}