import 'package:flutter/material.dart';
import 'package:prefectura_1/screens/admin/registrar_maestro_screen.dart';
import 'package:prefectura_1/screens/admin/registrar_grupos_screen.dart';
import 'package:prefectura_1/screens/admin/registrar_asignaturas_screen.dart';
import 'package:prefectura_1/screens/admin/registrar_aulas_screen.dart';
import 'package:prefectura_1/screens/admin/registrar_carreras_screen.dart';
import 'package:prefectura_1/screens/admin/registrar_horarios_screen.dart';
import 'package:prefectura_1/screens/admin/registrar_usuarios_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  final String token;
  
  const AdminHomeScreen({super.key, required this.token});

  void _confirmarCierreSesion(BuildContext context) {
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
              _cerrarSesion(context);
            },
            child: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _cerrarSesion(BuildContext context) {
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
        title: const Text('Panel Administrador'),
        backgroundColor: const Color(0xFF64A6E3),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmarCierreSesion(context),
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
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildMenuButton(
                    context, 
                    'Gestión de Maestros', 
                    Icons.person_outline, 
                    RegistrarMaestroScreen(token: token),
                  ),
                  _buildMenuButton(
                    context, 
                    'Gestión de Grupos', 
                    Icons.group_outlined, 
                    RegistrarGruposScreen(token: token),
                  ),
                  _buildMenuButton(
                    context, 
                    'Gestión de Asignaturas', 
                    Icons.menu_book_outlined, 
                    RegistrarAsignaturasScreen(token: token),
                  ),
                  _buildMenuButton(
                    context, 
                    'Gestión de Aulas', 
                    Icons.meeting_room_outlined, 
                    RegistrarAulasScreen(token: token),
                  ),
                  _buildMenuButton(
                    context, 
                    'Gestión de Carreras', 
                    Icons.school_outlined, 
                    RegistrarCarrerasScreen(token: token),
                  ),
                  _buildMenuButton(
                    context, 
                    'Gestión de Horarios', 
                    Icons.schedule_outlined, 
                    RegistrarHorariosScreen(token: token),
                  ),
                  _buildMenuButton(
                    context, 
                    'Gestión de Usuarios', 
                    Icons.manage_accounts_outlined, 
                    RegistrarUsuariosScreen(token: token),
                  ),
                ],
              ),
            ),
            // Botón adicional de cierre de sesión en el pie de página
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout, size: 20),
                label: const Text('Cerrar sesión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _confirmarCierreSesion(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String title, IconData icon, Widget targetScreen) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF64A6E3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64A6E3).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF0960AE), size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF0960AE),
            fontSize: 16,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 300),
              pageBuilder: (_, __, ___) => targetScreen,
              transitionsBuilder: (_, animation, __, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                );
              },
            ),
          );
        },
      ),
    );
  }
}