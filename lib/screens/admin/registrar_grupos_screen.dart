import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegistrarGruposScreen extends StatefulWidget {
  final String token;
  
  const RegistrarGruposScreen({super.key, required this.token});

  @override
  State<RegistrarGruposScreen> createState() => _RegistrarGruposScreenState();
}

class _RegistrarGruposScreenState extends State<RegistrarGruposScreen> {
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> grupos = [];
  bool _isLoading = true;
  final TextEditingController _grupoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarGrupos();
  }

  @override
  void dispose() {
    _grupoController.dispose();
    super.dispose();
  }

  Future<void> _cargarGrupos() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://primera-versi-n-de-mi-api-flask-production.up.railway.app/grupos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          grupos = List<Map<String, dynamic>>.from(json.decode(response.body));
          _isLoading = false;
        });
      } else {
        throw Exception('Error al cargar grupos: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarError('Error al cargar grupos: ${e.toString()}');
    }
  }

  Future<void> _registrarGrupo() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await http.post(
          Uri.parse('https://primera-versi-n-de-mi-api-flask-production.up.railway.app/grupos'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
          body: json.encode({
            'grupo': _grupoController.text.trim(),
          }),
        );

        if (response.statusCode == 201) {
          _mostrarExito('Grupo registrado exitosamente');
          _grupoController.clear();
          await _cargarGrupos();
        } else {
          final errorData = json.decode(response.body);
          throw Exception(errorData['message'] ?? 'Error al registrar grupo');
        }
      } catch (e) {
        _mostrarError('Error al registrar grupo: ${e.toString()}');
      }
    }
  }

  Future<void> _editarGrupo(int id) async {
    final grupo = grupos.firstWhere((g) => g['id_grupo'] == id);
    final nuevoNombre = await _mostrarDialogoEdicion(grupo['grupo']);
    
    if (nuevoNombre != null && nuevoNombre.isNotEmpty && nuevoNombre != grupo['grupo']) {
      try {
        final response = await http.put(
          Uri.parse('https://primera-versi-n-de-mi-api-flask-production.up.railway.app/grupos/$id'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
          body: json.encode({'grupo': nuevoNombre}),
        );

        if (response.statusCode == 200) {
          _mostrarExito('Grupo actualizado exitosamente');
          await _cargarGrupos();
        } else {
          final errorData = json.decode(response.body);
          throw Exception(errorData['message'] ?? 'Error al actualizar grupo');
        }
      } catch (e) {
        _mostrarError('Error al actualizar grupo: ${e.toString()}');
      }
    }
  }

  Future<void> _borrarGrupo(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de eliminar este grupo? Esta acción no se puede deshacer.'),
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
          Uri.parse('https://primera-versi-n-de-mi-api-flask-production.up.railway.app/grupos/$id'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
        );

        if (response.statusCode == 200) {
          _mostrarExito('Grupo eliminado exitosamente');
          await _cargarGrupos();
        } else {
          final errorData = json.decode(response.body);
          throw Exception(errorData['message'] ?? 'Error al eliminar grupo');
        }
      } catch (e) {
        _mostrarError('Error al eliminar grupo: ${e.toString()}');
      }
    }
  }

  Future<String?> _mostrarDialogoEdicion(String nombreActual) async {
    final controller = TextEditingController(text: nombreActual);
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Grupo'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nombre del grupo',
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
        title: const Text('Gestión de Grupos'),
        backgroundColor: const Color(0xFF64A6E3),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarGrupos,
            tooltip: 'Recargar',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: GrupoSearchDelegate(
                  grupos: grupos,
                  onEdit: _editarGrupo,
                  onDelete: _borrarGrupo,
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
                              controller: _grupoController,
                              decoration: InputDecoration(
                                labelText: 'Nombre del grupo',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () => _grupoController.clear(),
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
                              label: const Text('Registrar Grupo'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF64A6E3),
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _registrarGrupo,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: grupos.length,
                      itemBuilder: (context, index) {
                        final grupo = grupos[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 2,
                          child: ListTile(
                            title: Text(
                              grupo['grupo'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('ID: ${grupo['id_grupo']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _editarGrupo(grupo['id_grupo']),
                                  tooltip: 'Editar',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _borrarGrupo(grupo['id_grupo']),
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

class GrupoSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> grupos;
  final Function(int) onEdit;
  final Function(int) onDelete;

  GrupoSearchDelegate({
    required this.grupos, 
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
        ? grupos
        : grupos.where((g) => 
            g['grupo'].toLowerCase().contains(query.toLowerCase()) ||
            g['id_grupo'].toString().contains(query)).toList();

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
        final grupo = results[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          elevation: 2,
          child: ListTile(
            title: Text(
              grupo['grupo'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('ID: ${grupo['id_grupo']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => onEdit(grupo['id_grupo']),
                  tooltip: 'Editar',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => onDelete(grupo['id_grupo']),
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