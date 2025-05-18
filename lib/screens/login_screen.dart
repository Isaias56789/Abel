import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  String? _errorMessage;
  bool _isLoading = false;
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _apiService.login(email, password);
      if (token == null) {
        throw Exception('Credenciales incorrectas');
      }

      final profile = await _apiService.getUserProfile(token);
      final role = profile['role'];

      if (role == 'administrador') {
        Navigator.pushReplacementNamed(
          context,
          '/admin_home_screen',
          arguments: {'token': token},
        );
      } else if (role == 'prefecto') {
        Navigator.pushReplacementNamed(
          context,
          '/prefecto_home_screen',
          arguments: {'token': token},
        );
      } else {
        throw Exception('Rol no autorizado');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          child: Column(
            children: <Widget>[
              // Sección superior con imágenes
              Container(
                height: 400,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/imagenes/background.png'),
                    fit: BoxFit.fill
                  )
                ),
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      left: 30,
                      width: 80,
                      height: 200,
                      child: FadeInUp(
                        duration: Duration(seconds: 1), 
                        child: Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/imagenes/light-1.png')
                            )
                          ),
                        )
                      ),
                    ),
                    Positioned(
                      left: 140,
                      width: 80,
                      height: 150,
                      child: FadeInUp(
                        duration: Duration(milliseconds: 1200), 
                        child: Container(
                          decoration: BoxDecoration(
                           
                          ),
                        )
                      ),
                    ),
                    Positioned(
                      right: 40,
                      top: 40,
                      width: 80,
                      height: 150,
                      child: FadeInUp(
                        duration: Duration(milliseconds: 1300), 
                        child: Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/imagenes/clock.png')
                            )
                          ),
                        )
                      ),
                    ),
                    Positioned(
                      child: FadeInUp(
                        duration: Duration(milliseconds: 1600), 
                        child: Container(
                          margin: EdgeInsets.only(top: 50),
                          child: Center(
                            
                          ),
                        )
                      ),
                    )
                  ],
                ),
              ),
              
              // Sección del formulario
              Padding(
                padding: EdgeInsets.all(30.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      FadeInUp(
                        duration: Duration(milliseconds: 1800), 
                        child: Container(
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Color(0xFF8FBFEC)),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF8FBFEC).withOpacity(0.2),
                                blurRadius: 20.0,
                                offset: Offset(0, 10)
                              )
                            ]
                          ),
                          child: Column(
                            children: <Widget>[
                              Container(
                                padding: EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Color(0xFF8FBFEC))
                                  )
                                ),
                                child: TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: "Email",
                                    hintStyle: TextStyle(color: Colors.grey[700])
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor ingrese su email';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Ingrese un email válido';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.all(8.0),
                                child: TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: "Contraseña",
                                    hintStyle: TextStyle(color: Colors.grey[700]),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword 
                                          ? Icons.visibility_off 
                                          : Icons.visibility,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor ingrese su contraseña';
                                    }
                                    return null;
                                  },
                                ),
                              )
                            ],
                          ),
                        )
                      ),
                      SizedBox(height: 30),
                      
                      // Botón de login
                      FadeInUp(
                        duration: Duration(milliseconds: 1900), 
                        child: Material(
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            onTap: _isLoading ? null : _login,
                            borderRadius: BorderRadius.circular(10),
                            child: Ink(
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF64A6E3),
                                    Color(0xFF8FBFEC),
                                  ]
                                )
                              ),
                              child: Center(
                                child: _isLoading
                                    ? CircularProgressIndicator(color: Colors.white)
                                    : Text(
                                        "Iniciar sesión", 
                                        style: TextStyle(
                                          color: Colors.white, 
                                          fontWeight: FontWeight.bold
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Mensaje de error
                      if (_errorMessage != null)
                        Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: FadeInUp(
                            duration: Duration(milliseconds: 200),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.red.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade800,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      
                      SizedBox(height: 20),
                      
                      // Enlace para recuperar contraseña
                      FadeInUp(
                        duration: Duration(milliseconds: 2000), 
                        child: TextButton(
                          onPressed: () {
                            // Navegar a pantalla de recuperación de contraseña
                          },
                          child: Text(
                            "", 
                            style: TextStyle(
                              color: Color(0xFF8FBFEC), 
                              fontWeight: FontWeight.w500
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}