import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_cd2/controller/repository_user.dart';
import 'package:proyecto_cd2/model/app_logger.dart';
import 'package:proyecto_cd2/model/preferences.dart';
import 'package:proyecto_cd2/view/principal.dart';
import 'package:proyecto_cd2/view/nuevo_usuario.dart';
import 'package:proyecto_cd2/view/reset_password.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final repositoryUser = RepositoryUser();
  final AppLogger _logger = AppLogger.instance;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _correo = TextEditingController();
  final TextEditingController _contrasena = TextEditingController();
  bool _obscureText = true;
  String? errorMessage = "";
  bool _isProcessing = false;

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstRun();
    });
  }

  Future<void> _checkFirstRun() async {
    final hasUsers = await repositoryUser.hasUsers();
    if (!hasUsers) {
      if (!mounted) return;
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => NuevoUsuario(isFirstRun: true)),
      );

      if (result == true) {
        if (!mounted) return;
        _mostrarMensaje(
          "Configuración completada",
          "Usuario administrador creado exitosamente. Inicie sesión.",
          ContentType.success,
        );
      }
    }
  }

  Future<void> _login() async {
    try {
      final email = _correo.text;
      final password = hashPassword(_contrasena.text);

      final prefs = await SharedPreferences.getInstance();
      final user = await repositoryUser.getUserByEmail(email);
      String fullname = '${user!.nombre} ${user.apellido}';
      await prefs.setString('email', email);
      await prefs.setString('password', password);
      await prefs.setString('user', user.id.toString());
      await prefs.setString('tipo', user.tipo.toString());
      await prefs.setString('estado', user.estado.toString());
      await prefs.setString('user_fullname', fullname);
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => MyHomePage()),
      );
    } catch (e, st) {
      _logger.log.e('Error al iniciar sesión', error: e, stackTrace: st);
      _mostrarMensaje(
        "Atención",
        "Error al iniciar sesión",
        ContentType.failure,
      );
    }
  }

  Future<void> signInWithEmailAndPassword() async {
    try {
      setState(() {
        _isProcessing = true;
      });
      final response = await repositoryUser.signInWithEmailAndPassword(
        _correo.text,
        hashPassword(_contrasena.text),
      );
      if (response != null) {
        if (response.estado == 'Activo') {
          _login();
        } else {
          _mostrarMensaje(
            "Atención",
            "El usuario no se encuentra activo",
            ContentType.failure,
          );
        }
      } else {
        _mostrarMensaje(
          "Atención",
          "Credenciales incorrectas",
          ContentType.warning,
        );
      }
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
    } on Exception catch (e, st) {
      setState(() {
        errorMessage = e.toString();
      });
      _mostrarMensaje("Atención", errorMessage!, ContentType.failure);
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
      _logger.log.e('Error al iniciar sesión', error: e, stackTrace: st);
    }
  }

  void _mostrarMensaje(String title, String message, ContentType contentType) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: title,
        message: message,
        contentType: contentType,
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _correo.clear();
    _contrasena.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el tamaño de la pantalla y determinamos el tipo de dispositivo
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet =
        screenSize.width >= 600 &&
        screenSize.width <
            1200; // Ajustado para tablets hasta 1200px (mejor para landscape)
    final bool isDesktop =
        screenSize.width >= 1200; // Umbral más alto para desktop real

    // Colores basados en el tema (evitamos repeticiones de Provider.of)
    final themeProvider = Provider.of<TemaProveedor>(context);
    final bool isDarkMode = themeProvider.esModoOscuro;
    final Color backgroundColor = isDarkMode
        ? Colors.black
        : const Color.fromRGBO(244, 243, 243, 1);
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color inputFillColor = isDarkMode
        ? const Color.fromRGBO(30, 30, 30, 1)
        : Colors.white;
    final Color borderColor = textColor;
    final Color buttonColor =
        Colors.blueAccent; // Podrías hacerlo dinámico con el tema si lo deseas

    // Tamaños responsivos (agrupados para mejor legibilidad)
    final double titleFontSize = isMobile
        ? 18.0
        : (isTablet ? 20.0 : 24.0); // Aumentado para desktop
    final double labelFontSize = isMobile ? 14.0 : (isTablet ? 15.0 : 16.0);
    final double inputFontSize = isMobile ? 14.0 : (isTablet ? 15.0 : 16.0);
    final double iconSize = isMobile ? 22.0 : (isTablet ? 24.0 : 26.0);
    final double verticalPadding = isMobile ? 15.0 : (isTablet ? 16.0 : 18.0);
    final double horizontalPadding = isMobile ? 10.0 : (isTablet ? 12.0 : 14.0);
    final double buttonHeight = isMobile ? 50.0 : (isTablet ? 55.0 : 60.0);
    final double buttonFontSize = isMobile ? 16.0 : (isTablet ? 17.0 : 18.0);
    final double borderRadius = isDesktop ? 12.0 : 10.0;
    final double errorFontSize = isMobile ? 12.0 : 13.0;

    // Anchos responsivos para el contenedor del formulario
    final double formMaxWidth = isMobile
        ? double.infinity
        : (isTablet
              ? 500.0
              : 600.0); // Límite máximo para evitar estiramiento en pantallas grandes
    final double outerHorizontalPadding = isMobile
        ? 16.0
        : (isTablet
              ? 24.0
              : 32.0); // Padding exterior más amplio en pantallas grandes

    // Método reutilizable para la decoración de inputs (reduce duplicación)
    InputDecoration _buildInputDecoration({
      required String labelText,
      required IconData prefixIcon,
      Widget? suffixIcon,
      required Color fillColor,
      required Color labelColor,
      required Color iconColor,
    }) {
      return InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: labelColor, fontSize: labelFontSize),
        filled: true,
        fillColor: fillColor,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2.0),
        ),
        errorStyle: TextStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.w500,
          fontSize: errorFontSize,
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: verticalPadding,
          horizontal: horizontalPadding,
        ),
        prefixIcon: Icon(prefixIcon, color: iconColor, size: iconSize),
        suffixIcon: suffixIcon,
      );
    }

    // Widget reutilizable para el formulario (mejora la modularidad)
    Widget _buildForm() {
      return Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Título del formulario (opcional, pero mejora UX en desktop)
            if (!isMobile) ...[
              Text(
                'Bienvenido',
                style: TextStyle(
                  fontSize:
                      titleFontSize + 4, // Título más grande en tablet/desktop
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
            ],
            // Campo de correo
            TextFormField(
              controller: _correo,
              style: TextStyle(fontSize: inputFontSize, color: textColor),
              obscureText: false,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, ingrese el correo';
                }
                // Regex simplificado para email (más legible y eficiente)
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(value)) {
                  return 'Por favor, ingrese un correo válido';
                }
                return null;
              },
              decoration: _buildInputDecoration(
                labelText: 'Correo',
                prefixIcon: Icons.email,
                fillColor: inputFillColor,
                labelColor: textColor,
                iconColor: textColor,
              ),
            ),
            const SizedBox(height: 20),
            // Campo de contraseña
            TextFormField(
              controller: _contrasena,
              obscureText: _obscureText,
              style: TextStyle(fontSize: inputFontSize, color: textColor),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, ingrese la contraseña';
                }
                if (value.length < 8) {
                  return 'La contraseña debe tener al menos 8 caracteres';
                }
                return null;
              },
              decoration: _buildInputDecoration(
                labelText: 'Contraseña',
                prefixIcon: Icons.lock,
                fillColor: inputFillColor,
                labelColor: textColor,
                iconColor: textColor,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                    color: textColor,
                    size: iconSize,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Botón de inicio de sesión (ancho responsivo)
            SizedBox(
              width: isDesktop
                  ? 250.0
                  : double
                        .infinity, // En desktop, ancho fijo y centrado para mejor estética
              height: buttonHeight,
              child: ElevatedButton(
                onPressed: () async {
                  if (_isProcessing) {
                    null;
                  } else {
                    if (_formKey.currentState!.validate()) {
                      // Asumiendo que singInWithEmailAndPassword es un método async; corrige el typo si es necesario
                      await signInWithEmailAndPassword();
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  disabledBackgroundColor: _isProcessing
                      ? Colors.blueGrey
                      : null,
                  backgroundColor: buttonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                  elevation: 2,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Iniciar sesión',
                        style: TextStyle(
                          fontSize: buttonFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            // Enlace para restablecer contraseña (mejorado con tema y accesibilidad)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RestablecerContrasena(),
                  ),
                );
              },
              child: Text(
                '¿Olvidaste tu contraseña?',
                style: TextStyle(
                  color: buttonColor,
                  fontSize: isMobile ? 14.0 : 16.0, // Ajuste responsivo
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Inicio de sesión',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: titleFontSize,
          ),
        ),
        centerTitle: true,
        backgroundColor: backgroundColor,
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: outerHorizontalPadding,
          ), // Padding exterior responsivo
          child: ConstrainedBox(
            // Nuevo: Limita el ancho máximo para pantallas grandes
            constraints: BoxConstraints(
              maxWidth: formMaxWidth,
              minWidth: isMobile
                  ? 0
                  : 300.0, // Mínimo para evitar colapso en tablet/desktop
            ),
            child: Card(
              // Nuevo: Card para un look más profesional en tablet/desktop
              color:
                  inputFillColor, // Usa el color de input para consistencia con tema
              elevation: isMobile
                  ? 0
                  : 8.0, // Elevación solo en pantallas grandes para profundidad
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: Padding(
                padding: EdgeInsets.all(
                  isMobile ? 16.0 : 24.0,
                ), // Padding interno responsivo
                child: isMobile
                    ? SingleChildScrollView(
                        child: _buildForm(),
                      ) // Scroll solo en mobile
                    : _buildForm(), // Sin scroll en tablet/desktop (asumiendo espacio suficiente)
              ),
            ),
          ),
        ),
      ),
    );
  }
}
