import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/admin_home_screen.dart';
import 'screens/prefecto_home_screen.dart';
import 'screens/admin/registrar_maestro_screen.dart';
import 'screens/admin/registrar_grupos_screen.dart';
import 'screens/admin/registrar_asignaturas_screen.dart';
import 'screens/admin/registrar_aulas_screen.dart';
import 'screens/admin/registrar_carreras_screen.dart';
import 'screens/admin/registrar_horarios_screen.dart';
import 'screens/admin/registrar_usuarios_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Perfectura',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF64A6E3),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            color: Colors.black87,
            fontSize: 16,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF64A6E3),
            foregroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF64A6E3)),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/admin_home_screen':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => AdminHomeScreen(token: args['token']),
            );
          case '/prefecto_home_screen':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => PrefectoHomeScreen(token: args['token']),
            );
          // Rutas para las pantallas de administración
          case '/registrar_maestro':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => RegistrarMaestroScreen(token: args['token']),
            );
          case '/registrar_grupos':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => RegistrarGruposScreen(token: args['token']),
            );
          case '/registrar_asignaturas':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => RegistrarAsignaturasScreen(token: args['token']),
            );
          case '/registrar_aulas':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => RegistrarAulasScreen(token: args['token']),
            );
          case '/registrar_carreras':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => RegistrarCarrerasScreen(token: args['token']),
            );
          case '/registrar_horarios':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => RegistrarHorariosScreen(token: args['token']),
            );
          case '/registrar_usuarios':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => RegistrarUsuariosScreen(token: args['token']),
            );
          default:
            return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
      },
    );
  }
}