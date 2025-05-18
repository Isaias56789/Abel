import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegistrarUsuariosScreen extends StatefulWidget {
  final String token;

  const RegistrarUsuariosScreen({super.key, required this.token});

  @override
  State<RegistrarUsuariosScreen> createState() => _RegistrarUsuariosScreenState();
}

class _RegistrarUsuariosScreenState extends State<RegistrarUsuariosScreen> {
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> usuarios = [];
  bool _isLoading = true;
  bool _obscurePassword = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedRole = 'prefecto';

  final List<String> roles = ['prefecto', 'administrador'];

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _cargarUsuarios() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://primera-versi-n-de-mi-api-flask-production.up.railway.app/usuarios'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          usuarios = data.map((user) => {
            'id': user['id'],
            'name': user['name'],
            'email': user['email'],
            'role': user['role'],
          }).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Error al cargar usuarios: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarError('Error al cargar usuarios: ${e.toString()}');
    }
  }

  Future<void> _registrarUsuario() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await http.post(
          Uri.parse('https://primera-versi-n-de-mi-api-flask-production.up.railway.app/usuarios'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
          body: json.encode({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'password': _passwordController.text.trim(),
            'role': _selectedRole,
          }),
        );

        if (response.statusCode == 201) {
          _mostrarExito('Usuario registrado exitosamente');
          _limpiarFormulario();
          await _cargarUsuarios();
        } else {
          final errorData = json.decode(response.body);
          throw Exception(errorData['message'] ?? 'Error al registrar usuario');
        }
      } catch (e) {
        _mostrarError('Error al registrar usuario: ${e.toString()}');
      }
    }
  }

  Future<void> _editarUsuario(int id) async {
    final usuario = usuarios.firstWhere((u) => u['id'] == id);
    final result = await _mostrarDialogoEdicion(usuario);

    if (result != null && result['confirmed'] == true) {
      try {
        final response = await http.put(
          Uri.parse('https://primera-versi-n-de-mi-api-flask-production.up.railway.app/usuarios/$id'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
          body: json.encode({
            'name': result['name'],
            'email': result['email'],
            'role': result['role'],
          }),
        );

        if (response.statusCode == 200) {
          _mostrarExito('Usuario actualizado exitosamente');
          await _cargarUsuarios();
        } else {
          final errorData = json.decode(response.body);
          throw Exception(errorData['message'] ?? 'Error al actualizar usuario');
        }
      } catch (e) {
        _mostrarError('Error al actualizar usuario: ${e.toString()}');
      }
    }
  }

  Future<void> _borrarUsuario(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de eliminar este usuario?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await http.delete(
          Uri.parse('https://primera-versi-n-de-mi-api-flask-production.up.railway.app/usuarios/$id'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
        );

        if (response.statusCode == 200) {
          _mostrarExito('Usuario eliminado exitosamente');
          await _cargarUsuarios();
        } else {
          final errorData = json.decode(response.body);
          throw Exception(errorData['message'] ?? 'Error al eliminar usuario');
        }
      } catch (e) {
        _mostrarError('Error al eliminar usuario: ${e.toString()}');
      }
    }
  }

  Future<Map<String, dynamic>?> _mostrarDialogoEdicion(Map<String, dynamic> usuario) async {
    final nameController = TextEditingController(text: usuario['name']);
    final emailController = TextEditingController(text: usuario['email']);
    String selectedRole = usuario['role'];

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Editar Usuario'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Rol',
                        border: OutlineInputBorder(),
                      ),
                      items: roles.map((role) {
                        return DropdownMenuItem<String>(
                          value: role,
                          child: Text(role),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedRole = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'confirmed': true,
                      'name': nameController.text.trim(),
                      'email': emailController.text.trim(),
                      'role': selectedRole,
                    });
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _limpiarFormulario() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    setState(() => _selectedRole = 'prefecto');
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
        title: const Text('Gestión de Usuarios'),
        backgroundColor: const Color(0xFF64A6E3),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarUsuarios,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
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
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nombre completo',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Por favor ingrese un nombre';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Correo electrónico',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Por favor ingrese un correo';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () {
                                    setState(() => _obscurePassword = !_obscurePassword);
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.length < 6) {
                                  return 'La contraseña debe tener al menos 6 caracteres';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedRole,
                              decoration: const InputDecoration(
                                labelText: 'Rol',
                                border: OutlineInputBorder(),
                              ),
                              items: roles.map((role) {
                                return DropdownMenuItem<String>(
                                  value: role,
                                  child: Text(role),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedRole = value!);
                              },
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _registrarUsuario,
                              child: const Text('Registrar'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: usuarios.length,
                      itemBuilder: (context, index) {
                        final user = usuarios[index];
                        return Card(
                          elevation: 3,
                          child: ListTile(
                            title: Text(user['name']),
                            subtitle: Text('${user['email']} | Rol: ${user['role']}'),
                            trailing: Wrap(
                              spacing: 8,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange),
                                  onPressed: () => _editarUsuario(user['id']),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _borrarUsuario(user['id']),
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
