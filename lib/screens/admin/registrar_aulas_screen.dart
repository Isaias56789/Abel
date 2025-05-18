import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegistrarAulasScreen extends StatefulWidget {
  final String token;
  
  const RegistrarAulasScreen({super.key, required this.token});

  @override
  State<RegistrarAulasScreen> createState() => _RegistrarAulasScreenState();
}

class _RegistrarAulasScreenState extends State<RegistrarAulasScreen> {
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> aulas = [];
  bool _isLoading = true;
  final TextEditingController _aulaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarAulas();
  }

  @override
  void dispose() {
    _aulaController.dispose();
    super.dispose();
  }

  Future<void> _cargarAulas() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://primera-versi-n-de-mi-api-flask-production.up.railway.app/aulas'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          aulas = List<Map<String, dynamic>>.from(json.decode(response.body));
          _isLoading = false;
        });
      } else {
        throw Exception('Error al cargar aulas');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarError('Error al cargar aulas: $e');
    }
  }

  Future<void> _registrarAula() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await http.post(
          Uri.parse('https://primera-versi-n-de-mi-api-flask-production.up.railway.app/aulas'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
          body: json.encode({
            'aula': _aulaController.text,
          }),
        );

        if (response.statusCode == 201) {
          _mostrarExito('Aula registrada exitosamente');
          _aulaController.clear();
          await _cargarAulas();
        } else {
          throw Exception('Error al registrar aula');
        }
      } catch (e) {
        _mostrarError('Error al registrar aula: $e');
      }
    }
  }

  Future<void> _editarAula(int id) async {
    final aula = aulas.firstWhere((a) => a['id_aula'] == id);
    final nuevoNombre = await _mostrarDialogoEdicion(aula['aula']);
    
    if (nuevoNombre != null && nuevoNombre.isNotEmpty) {
      try {
        final response = await http.put(
          Uri.parse('https://primera-versi-n-de-mi-api-flask-production.up.railway.app/aulas/$id'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
          body: json.encode({'aula': nuevoNombre}),
        );

        if (response.statusCode == 200) {
          _mostrarExito('Aula actualizada exitosamente');
          await _cargarAulas();
        } else {
          throw Exception('Error al actualizar aula');
        }
      } catch (e) {
        _mostrarError('Error al actualizar aula: $e');
      }
    }
  }

  Future<String?> _mostrarDialogoEdicion(String nombreActual) async {
    final controller = TextEditingController(text: nombreActual);
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Aula'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nombre del aula'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _borrarAula(int id) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text('¿Estás seguro de eliminar este aula?'),
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
          Uri.parse('https://primera-versi-n-de-mi-api-flask-production.up.railway.app/aulas/$id'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
        );

        if (response.statusCode == 200) {
          _mostrarExito('Aula eliminada exitosamente');
          await _cargarAulas();
        } else {
          throw Exception('Error al eliminar aula');
        }
      } catch (e) {
        _mostrarError('Error al eliminar aula: $e');
      }
    }
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.green),
    );
  }

  void _mostrarError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Aulas'),
        backgroundColor: const Color(0xFF64A6E3),
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
                        TextFormField(
                          controller: _aulaController,
                          decoration: InputDecoration(
                            labelText: 'Nombre del aula',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Este campo es obligatorio';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF64A6E3),
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _registrarAula,
                          child: const Text(
                            'Registrar Aula',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: aulas.length,
                      itemBuilder: (context, index) {
                        final aula = aulas[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                          child: ListTile(
                            title: Text(aula['aula']),
                            subtitle: Text('ID: ${aula['id_aula']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _editarAula(aula['id_aula']),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _borrarAula(aula['id_aula']),
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