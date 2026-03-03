import 'dart:convert';

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_cd2/controller/repository_user.dart';
import 'package:proyecto_cd2/model/app_logger.dart';
import 'package:proyecto_cd2/model/preferences.dart';

class RestablecerContrasena extends StatefulWidget {
  const RestablecerContrasena({super.key});

  @override
  State<RestablecerContrasena> createState() => _RestablecerContrasenaState();
}

class _RestablecerContrasenaState extends State<RestablecerContrasena> {
  final repositoryUser = RepositoryUser();
  final AppLogger _logger = AppLogger.instance;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _correo = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _isProcessing = false;
  bool _obscureText = true;

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _correo.dispose();
    _password.dispose();
  }

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> resetPassword() async {
    try {
      setState(() {
        _isProcessing = true;
      });
      String email = _correo.text;
      String password = hashPassword(_password.text);
      await repositoryUser.resetPassword(email, password);
      _mostrarMensaje(
        "Atención",
        "Contraseña restablecida correctamente.",
        ContentType.success,
      );
      Navigator.pop(context);
    } catch (e, st) {
      _mostrarMensaje("Atención", e.toString(), ContentType.warning);
      setState(() {
        _isProcessing = false;
      });
      _logger.log.e(
        'Error al restablecer la contraseña',
        error: e,
        stackTrace: st,
      );
    }
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
    InputDecoration buildInputDecoration({
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
    Widget buildForm() {
      return Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Título del formulario (opcional, pero mejora UX en desktop)
            if (!isMobile) ...[
              Text(
                'Ingrese su correo electrónico y su nueva contraseña',
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
              decoration: buildInputDecoration(
                labelText: 'Correo',
                prefixIcon: Icons.email,
                fillColor: inputFillColor,
                labelColor: textColor,
                iconColor: textColor,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _password,
              style: TextStyle(fontSize: inputFontSize, color: textColor),
              obscureText: _obscureText,
              keyboardType: TextInputType.visiblePassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, ingrese la contraseña';
                }
                return null;
              },
              decoration: buildInputDecoration(
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
            // Botón de restablecer (ancho responsivo)
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
                      resetPassword();
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
                        'Restablecer',
                        style: TextStyle(
                          fontSize: buttonFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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
          'Restablecer contraseña',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: titleFontSize,
          ),
        ),
        centerTitle: true,
        backgroundColor: backgroundColor,
        iconTheme: IconThemeData(color: textColor),
        elevation: 0, // Mejora visual: sin sombra para un look más limpio
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
                        child: buildForm(),
                      ) // Scroll solo en mobile
                    : buildForm(), // Sin scroll en tablet/desktop (asumiendo espacio suficiente)
              ),
            ),
          ),
        ),
      ),
    );
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

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
