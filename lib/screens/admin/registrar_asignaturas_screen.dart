import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegistrarAsignaturasScreen extends StatefulWidget {
  final String token;
  
  const RegistrarAsignaturasScreen({super.key, required this.token});

  @override
  State<RegistrarAsignaturasScreen> createState() => _RegistrarAsignaturaScreenState();
}

class _RegistrarAsignaturaScreenState extends State<RegistrarAsignaturasScreen> {
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> asignaturas = [];
  bool _isLoading = true;

  String nombreAsignatura = '';
  String claveAsignatura = '';
  String horasTeoricas = '';
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _cargarAsignaturas();
  }

  Future<void> _cargarAsignaturas() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://primera-versi-n-de-mi-api-flask-production.up.railway.app/asignaturas'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          asignaturas = List<Map<String, dynamic>>.from(json.decode(response.body));
          _isLoading = false;
        });
      } else {
        throw Exception('Error al cargar asignaturas');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _registrarAsignatura() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      try {
        final response = await http.post(
          Uri.parse('https://primera-versi-n-de-mi-api-flask-production.up.railway.app/asignaturas'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
          body: json.encode({
            'nombre_asignatura': nombreAsignatura,
            'clave_asignatura': claveAsignatura,
            'horas_teoricas': horasTeoricas,
          }),
        );

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Asignatura registrada exitosamente!')),
          );
          await _cargarAsignaturas();
          Navigator.pop(context);
        } else {
          throw Exception('Error al registrar asignatura');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _editarAsignatura(int id) async {
    final asignatura = asignaturas.firstWhere((a) => a['id_asignatura'] == id);
    
    final result = await showDialog(
      context: context,
      builder: (context) => Dialog(
        child: EditarAsignaturaForm(
          asignatura: asignatura,
          token: widget.token,
        ),
      ),
    );

    if (result == true) {
      await _cargarAsignaturas();
    }
  }

  Future<void> _borrarAsignatura(int id) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text('¿Estás seguro de eliminar esta asignatura?'),
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
          Uri.parse('https://primera-versi-n-de-mi-api-flask-production.up.railway.app/asignaturas/$id'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Asignatura eliminada exitosamente')),
          );
          await _cargarAsignaturas();
        } else {
          throw Exception('Error al eliminar asignatura');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> _buscarAsignatura(String query) {
    return asignaturas
        .where((asignatura) =>
            asignatura['nombre_asignatura'].toLowerCase().contains(query.toLowerCase()) ||
            asignatura['clave_asignatura'].toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Asignatura'),
        backgroundColor: const Color(0xFF64A6E3),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: AsignaturaSearchDelegate(
                  asignaturas: asignaturas,
                  onEdit: _editarAsignatura,
                  onDelete: _borrarAsignatura,
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
                          label: 'Nombre Asignatura',
                          onSaved: (value) => nombreAsignatura = value!,
                        ),
                        _buildTextField(
                          label: 'Clave Asignatura',
                          onSaved: (value) => claveAsignatura = value!,
                        ),
                        _buildTextField(
                          label: 'Horas Teóricas',
                          keyboardType: TextInputType.number,
                          onSaved: (value) => horasTeoricas = value!,
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF64A6E3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          onPressed: _registrarAsignatura,
                          child: const Text(
                            'Registrar Asignatura',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: asignaturas.length,
                      itemBuilder: (context, index) {
                        final asignatura = asignaturas[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                          child: ListTile(
                            title: Text(asignatura['nombre_asignatura']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Clave: ${asignatura['clave_asignatura']}'),
                                Text('Horas: ${asignatura['horas_teoricas']}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _editarAsignatura(asignatura['id_asignatura']),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _borrarAsignatura(asignatura['id_asignatura']),
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

  Widget _buildTextField({
    required String label,
    required FormFieldSetter<String> onSaved,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        keyboardType: keyboardType,
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

class EditarAsignaturaForm extends StatefulWidget {
  final Map<String, dynamic> asignatura;
  final String token;

  const EditarAsignaturaForm({super.key, required this.asignatura, required this.token});

  @override
  State<EditarAsignaturaForm> createState() => _EditarAsignaturaFormState();
}

class _EditarAsignaturaFormState extends State<EditarAsignaturaForm> {
  final _formKey = GlobalKey<FormState>();
  late String nombreAsignatura;
  late String claveAsignatura;
  late String horasTeoricas;

  @override
  void initState() {
    super.initState();
    nombreAsignatura = widget.asignatura['nombre_asignatura'];
    claveAsignatura = widget.asignatura['clave_asignatura'];
    horasTeoricas = widget.asignatura['horas_teoricas'].toString();
  }

  Future<void> _actualizarAsignatura() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      try {
        final response = await http.put(
          Uri.parse('https://primera-versi-n-de-mi-api-flask-production.up.railway.app/asignaturas/${widget.asignatura['id_asignatura']}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
          body: json.encode({
            'nombre_asignatura': nombreAsignatura,
            'clave_asignatura': claveAsignatura,
            'horas_teoricas': horasTeoricas,
          }),
        );

        if (response.statusCode == 200) {
          Navigator.pop(context, true);
        } else {
          throw Exception('Error al actualizar asignatura');
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
              initialValue: nombreAsignatura,
              decoration: const InputDecoration(labelText: 'Nombre Asignatura'),
              onChanged: (value) => nombreAsignatura = value,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Campo obligatorio';
                return null;
              },
            ),
            TextFormField(
              initialValue: claveAsignatura,
              decoration: const InputDecoration(labelText: 'Clave Asignatura'),
              onChanged: (value) => claveAsignatura = value,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Campo obligatorio';
                return null;
              },
            ),
            TextFormField(
              initialValue: horasTeoricas,
              decoration: const InputDecoration(labelText: 'Horas Teóricas'),
              keyboardType: TextInputType.number,
              onChanged: (value) => horasTeoricas = value,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Campo obligatorio';
                return null;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _actualizarAsignatura,
              child: const Text('Guardar Cambios'),
            ),
          ],
        ),
      ),
    );
  }
}

class AsignaturaSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> asignaturas;
  final Function(int) onEdit;
  final Function(int) onDelete;

  AsignaturaSearchDelegate({required this.asignaturas, required this.onEdit, required this.onDelete});

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
    final results = _buscarAsignaturas();
    return _buildResultados(results);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = _buscarAsignaturas();
    return _buildResultados(suggestions);
  }

  List<Map<String, dynamic>> _buscarAsignaturas() {
    return asignaturas
        .where((asignatura) =>
            asignatura['nombre_asignatura'].toLowerCase().contains(query.toLowerCase()) ||
            asignatura['clave_asignatura'].toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Widget _buildResultados(List<Map<String, dynamic>> resultados) {
    return ListView.builder(
      itemCount: resultados.length,
      itemBuilder: (context, index) {
        final asignatura = resultados[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          child: ListTile(
            title: Text(asignatura['nombre_asignatura']),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Clave: ${asignatura['clave_asignatura']}'),
                Text('Horas: ${asignatura['horas_teoricas']}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => onEdit(asignatura['id_asignatura']),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => onDelete(asignatura['id_asignatura']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}