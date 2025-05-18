import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegistrarMaestroScreen extends StatefulWidget {
  final String token;
  
  const RegistrarMaestroScreen({super.key, required this.token});

  @override
  State<RegistrarMaestroScreen> createState() => _RegistrarMaestroScreenState();
}

class _RegistrarMaestroScreenState extends State<RegistrarMaestroScreen> {
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> maestros = [];
  bool _isLoading = true;

  String nombre = '';
  String apellido = '';
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _cargarMaestros();
  }

  Future<void> _cargarMaestros() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://primera-versi-n-de-mi-api-flask-production.up.railway.app/maestros'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          maestros = List<Map<String, dynamic>>.from(json.decode(response.body));
          _isLoading = false;
        });
      } else {
        throw Exception('Error al cargar maestros');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _registrarMaestro() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      try {
        final response = await http.post(
          Uri.parse('https://primera-versi-n-de-mi-api-flask-production.up.railway.app/maestros'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
          body: json.encode({
            'nombre': nombre,
            'apellido': apellido,
          }),
        );

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Maestro registrado exitosamente!')),
          );
          await _cargarMaestros(); // Recargar la lista
          Navigator.pop(context);
        } else {
          throw Exception('Error al registrar maestro');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _editarMaestro(int id) async {
    final maestro = maestros.firstWhere((m) => m['id_maestro'] == id);
    
    final result = await showDialog(
      context: context,
      builder: (context) => Dialog(
        child: EditarMaestroForm(
          maestro: maestro,
          token: widget.token,
        ),
      ),
    );

    if (result == true) {
      await _cargarMaestros();
    }
  }

  Future<void> _borrarMaestro(int id) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text('¿Estás seguro de eliminar este maestro?'),
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
          Uri.parse('https://primera-versi-n-de-mi-api-flask-production.up.railway.app/maestros/$id'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maestro eliminado exitosamente')),
          );
          await _cargarMaestros();
        } else {
          throw Exception('Error al eliminar maestro');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> _buscarMaestro(String query) {
    return maestros
        .where((maestro) =>
            maestro['nombre'].toLowerCase().contains(query.toLowerCase()) ||
            maestro['apellido'].toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Maestro'),
        backgroundColor: const Color(0xFF64A6E3),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: MaestroSearchDelegate(
                  maestros: maestros,
                  onEdit: _editarMaestro,
                  onDelete: _borrarMaestro,
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(
                          label: 'Nombre',
                          onSaved: (value) => nombre = value!,
                        ),
                        _buildTextField(
                          label: 'Apellido',
                          onSaved: (value) => apellido = value!,
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF64A6E3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          onPressed: _registrarMaestro,
                          child: const Text(
                            'Registrar Maestro',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: maestros.length,
                      itemBuilder: (context, index) {
                        final maestro = maestros[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                          child: ListTile(
                            title: Text('${maestro['nombre']} ${maestro['apellido']}'),
                            subtitle: Text('ID: ${maestro['id_maestro']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _editarMaestro(maestro['id_maestro']),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _borrarMaestro(maestro['id_maestro']),
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

  Widget _buildTextField({required String label, required FormFieldSetter<String> onSaved}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Este campo es obligatorio';
          }
          return null;
        },
        onSaved: onSaved,
      ),
    );
  }
}

class EditarMaestroForm extends StatefulWidget {
  final Map<String, dynamic> maestro;
  final String token;

  const EditarMaestroForm({super.key, required this.maestro, required this.token});

  @override
  State<EditarMaestroForm> createState() => _EditarMaestroFormState();
}

class _EditarMaestroFormState extends State<EditarMaestroForm> {
  final _formKey = GlobalKey<FormState>();
  late String nombre;
  late String apellido;

  @override
  void initState() {
    super.initState();
    nombre = widget.maestro['nombre'];
    apellido = widget.maestro['apellido'];
  }

  Future<void> _actualizarMaestro() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      try {
        final response = await http.put(
          Uri.parse('https://primera-versi-n-de-mi-api-flask-production.up.railway.app/maestros/${widget.maestro['id_maestro']}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
          body: json.encode({
            'nombre': nombre,
            'apellido': apellido,
          }),
        );

        if (response.statusCode == 200) {
          Navigator.pop(context, true);
        } else {
          throw Exception('Error al actualizar maestro');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: nombre,
              decoration: const InputDecoration(labelText: 'Nombre'),
              onChanged: (value) => nombre = value,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Campo obligatorio';
                return null;
              },
            ),
            TextFormField(
              initialValue: apellido,
              decoration: const InputDecoration(labelText: 'Apellido'),
              onChanged: (value) => apellido = value,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Campo obligatorio';
                return null;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _actualizarMaestro,
              child: const Text('Guardar Cambios'),
            ),
          ],
        ),
      ),
    );
  }
}

class MaestroSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> maestros;
  final Function(int) onEdit;
  final Function(int) onDelete;

  MaestroSearchDelegate({required this.maestros, required this.onEdit, required this.onDelete});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = _buscarMaestros();
    return _buildResultados(results);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = _buscarMaestros();
    return _buildResultados(suggestions);
  }

  List<Map<String, dynamic>> _buscarMaestros() {
    return maestros
        .where((maestro) =>
            maestro['nombre'].toLowerCase().contains(query.toLowerCase()) ||
            maestro['apellido'].toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Widget _buildResultados(List<Map<String, dynamic>> resultados) {
    return ListView.builder(
      itemCount: resultados.length,
      itemBuilder: (context, index) {
        final maestro = resultados[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          child: ListTile(
            title: Text('${maestro['nombre']} ${maestro['apellido']}'),
            subtitle: Text('ID: ${maestro['id_maestro']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => onEdit(maestro['id_maestro']),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => onDelete(maestro['id_maestro']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}