import 'dart:async';
import 'dart:convert';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_cd2/controller/repository_user.dart';
import 'package:proyecto_cd2/model/app_logger.dart';
import 'package:proyecto_cd2/model/preferences.dart';
import 'package:proyecto_cd2/model/user.dart';
import 'package:proyecto_cd2/view/widgets/loading.dart';
import 'package:crypto/crypto.dart';

// ignore: must_be_immutable
class NuevoUsuario extends StatefulWidget {
  bool isEdit;
  String uid;
  String nombre;
  String apellido;
  String telefono;
  String tipo;
  String estado;
  String fechaCreacion;
  String fechaActualizacion;
  NuevoUsuario({
    super.key,
    this.isEdit = false,
    this.uid = 'N/A',
    this.nombre = 'N/A',
    this.apellido = 'N/A',
    this.telefono = 'N/A',
    this.tipo = 'N/A',
    this.estado = 'N/A',
    this.fechaCreacion = 'N/A',
    this.fechaActualizacion = 'N/A',
    this.isFirstRun = false,
  });

  final bool isFirstRun;

  @override
  State<NuevoUsuario> createState() => _NuevoUsuarioState();
}

class _NuevoUsuarioState extends State<NuevoUsuario> {
  final repository = RepositoryUser();
  final AppLogger _logger = AppLogger.instance;
  final TextEditingController _nombre = TextEditingController();
  final TextEditingController _apellido = TextEditingController();
  final TextEditingController _telefono = TextEditingController();
  final TextEditingController _correo = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _obscureText = true;

  String nombreOriginal = "";
  String apellidoOriginal = "";
  String telefonoOriginal = "";

  List<String> estado = ['Activo', 'Inactivo'];
  String? selectedEstado;
  List<String> tipo = ['Vendedor', 'Administrador'];
  String? selectedTipo;

  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;
  late bool isLoading = false;

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      _obtenerInformacion();
    }
    if (widget.isFirstRun) {
      selectedTipo = 'Administrador';
      selectedEstado = 'Activo';
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    _telefono.dispose();
    _correo.dispose();
    _password.dispose();
    super.dispose();
  }

  void _obtenerInformacion() async {
    setState(() {
      _nombre.text = widget.nombre;
      _apellido.text = widget.apellido;
      _telefono.text = widget.telefono;
      selectedTipo = widget.tipo;
      selectedEstado = widget.estado;

      nombreOriginal = widget.nombre;
      apellidoOriginal = widget.apellido;
      telefonoOriginal = widget.telefono;
    });
  }

  Future<void> _actualizarUsuario() async {
    if (_nombre.text.isEmpty ||
        _apellido.text.isEmpty ||
        _telefono.text.isEmpty) {
      return;
    }

    setState(() => _isProcessing = true);

    String nombre = _nombre.text;
    String apellido = _apellido.text;
    String telefono = _telefono.text;

    try {
      Map<String, dynamic> userMap = {
        'nombre': nombre,
        'apellido': apellido,
        'telefono': telefono,
        'tipo': selectedTipo!,
        'estado': selectedEstado!,
        'fecha_actualizacion': DateTime.now().toIso8601String(),
      };
      final response = await repository.updateUser(
        int.parse(widget.uid),
        userMap,
      );

      if (response != -1) {
        _mostrarMensaje(
          'Éxito',
          'Usuario actualizado correctamente',
          ContentType.success,
        );
        Navigator.pop(context, true);
      } else {
        _mostrarMensaje(
          'Error',
          'Hubo un error al actualizar el usuario',
          ContentType.failure,
        );
        Navigator.pop(context, false);
      }
    } catch (e, st) {
      _mostrarMensaje('Error', 'Error inesperado: $e', ContentType.failure);
      Navigator.pop(context, false);
      _logger.log.e('Error al actualizar el usuario', error: e, stackTrace: st);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> agregarUsuario() async {
    try {
      if (!mounted) return;
      // Deshabilitar el botón para evitar clics múltiples
      setState(() {
        _isProcessing = true;
      });
      String nombre = _nombre.text;
      String apellido = _apellido.text;
      String correo = _correo.text;
      String telefono = _telefono.text;
      String password = hashPassword(_password.text);

      final user = User(
        nombre: nombre,
        apellido: apellido,
        telefono: telefono,
        correo: correo,
        contrasena: password,
        tipo: selectedTipo!,
        estado: selectedEstado!,
        fechaCreacion: DateTime.now().toIso8601String(),
        fechaActualizacion: DateTime.now().toIso8601String(),
      );

      final response = await repository.insertUser(user);

      if (response != -1) {
        setState(() {
          _isProcessing = false; // Volver a habilitar el botón
        });
        _mostrarMensaje(
          'Éxito',
          'Usuario creado correctamente',
          ContentType.success,
        );
        Navigator.pop(context, true);
      } else {
        _mostrarMensaje(
          'Error',
          'Hubo un error al crear el nuevo usuario',
          ContentType.failure,
        );
        Navigator.pop(context, false);
      }
    } catch (e, st) {
      setState(() {
        _isProcessing = false; // Volver a habilitar el botón
      });
      _mostrarMensaje('Error', 'Error inesperado: $e', ContentType.failure);
      _logger.log.e('Error al crear el usuario', error: e, stackTrace: st);
      Navigator.pop(context, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el tamaño de la pantalla
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;
    final bool isDesktop = screenSize.width >= 900;

    // Ajustamos tamaños según el dispositivo
    final double titleFontSize = isMobile ? 18.0 : (isTablet ? 20.0 : 22.0);

    return Scaffold(
      backgroundColor: Provider.of<TemaProveedor>(context).esModoOscuro
          ? Colors.black
          : const Color.fromRGBO(244, 243, 243, 1),
      appBar: AppBar(
        title: widget.isEdit
            ? Text(
                'Editar usuario',
                style: TextStyle(
                  color: Provider.of<TemaProveedor>(context).esModoOscuro
                      ? Colors.white
                      : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: titleFontSize,
                ),
              )
            : Text(
                widget.isFirstRun
                    ? 'Configurar administrador'
                    : 'Crear usuario',
                style: TextStyle(
                  color: Provider.of<TemaProveedor>(context).esModoOscuro
                      ? Colors.white
                      : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: titleFontSize,
                ),
              ),
        iconTheme: IconThemeData(
          color: Provider.of<TemaProveedor>(context).esModoOscuro
              ? Colors.white
              : Colors.black,
        ),
        backgroundColor: Provider.of<TemaProveedor>(context).esModoOscuro
            ? Colors.black
            : const Color.fromRGBO(244, 243, 243, 1),
        centerTitle: true,
      ),
      body: isLoading
          ? CargandoInventario()
          : SafeArea(
              child: Stack(
                children: [
                  widget.isEdit
                      ? isDesktop
                            ? _buildDesktopLayout()
                            : formulario()
                      : isDesktop
                      ? _buildDesktopLayout()
                      : formulario(),
                  if (_isProcessing) CircularProgressIndicator(),
                ],
              ),
            ),
    );
  }

  // Layout para escritorio (diseño horizontal)
  Widget _buildDesktopLayout() {
    return Center(
      child: Container(
        width: 800, // Ancho máximo para el formulario en escritorio
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Columna izquierda con imagen o icono
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.isEdit ? Icons.edit_document : Icons.add_box,
                      size: 120,
                      color: Provider.of<TemaProveedor>(context).esModoOscuro
                          ? Colors.white.withOpacity(0.8)
                          : Colors.blueAccent.withOpacity(0.8),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.isEdit
                          ? 'Actualizar usuario'
                          : (widget.isFirstRun
                                ? 'Crear administrador'
                                : 'Nuevo usuario'),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Provider.of<TemaProveedor>(context).esModoOscuro
                            ? Colors.white
                            : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.isEdit
                          ? 'Modifica los datos del usuario según sea necesario.'
                          : (widget.isFirstRun
                                ? 'Configure la cuenta de administrador principal para el sistema.'
                                : 'Completa el formulario para agregar un nuevo usuario'),
                      style: TextStyle(
                        fontSize: 16,
                        color: Provider.of<TemaProveedor>(context).esModoOscuro
                            ? Colors.white.withOpacity(0.7)
                            : Colors.black.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // Columna derecha con el formulario
            Expanded(
              flex: 3,
              child: Card(
                margin: const EdgeInsets.all(24.0),
                color: Provider.of<TemaProveedor>(context).esModoOscuro
                    ? const Color.fromRGBO(30, 30, 30, 1)
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: formulario(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget formulario() {
    // Obtenemos el tamaño de la pantalla
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;
    final bool isDesktop = screenSize.width >= 900;

    // Ajustamos tamaños según el dispositivo
    final double buttonHeight = isMobile ? 50.0 : (isTablet ? 55.0 : 60.0);
    final double buttonFontSize = isMobile ? 16.0 : (isTablet ? 17.0 : 18.0);
    final double fieldSpacing = isMobile ? 16.0 : (isTablet ? 20.0 : 24.0);

    double iconSize = isMobile ? 24.0 : (isTablet ? 28.0 : 30.0);
    double fontSize = isMobile ? 10.0 : (isTablet ? 12.0 : 14.0);

    iconSize = iconSize.clamp(24.0, 60.0);
    fontSize = fontSize.clamp(12.0, 24.0);

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(
          isMobile ? 16.0 : (isTablet ? 20.0 : 0.0),
        ), // Sin padding adicional en desktop
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Nombre
              Column(
                children: [
                  SizedBox(height: fieldSpacing),
                  _buildTextField(_nombre, 'Nombre'),
                  SizedBox(height: fieldSpacing),
                  _buildTextField(_apellido, 'Apellido'),
                  SizedBox(height: fieldSpacing),
                  _buildTextField(_telefono, 'Teléfono', isTelefono: true),
                  widget.isEdit ? SizedBox(height: fieldSpacing) : Container(),
                  widget.isEdit ? Container() : SizedBox(height: fieldSpacing),
                  widget.isEdit
                      ? Container()
                      : _buildTextField(_correo, 'Correo', isEmail: true),
                  widget.isEdit ? Container() : SizedBox(height: fieldSpacing),
                  // widget.isEdit
                  //     ? Container()
                  //     : _buildTextField(
                  //         _password,
                  //         'Contraseña',
                  //         isPassword: true,
                  //       ),
                  widget.isEdit
                      ? Container()
                      : _buildTextField(
                          _password,
                          'Contraseña',
                          isPassword: true,
                        ),
                  widget.isEdit ? Container() : SizedBox(height: fieldSpacing),
                  widget.isFirstRun
                      ? _buildReadOnlyField('Tipo', 'Administrador')
                      : _buildDropdown(
                          value: selectedTipo,
                          items: tipo,
                          label: 'Tipo',
                          icon: Icons.person,
                          onChanged: (value) {
                            setState(() {
                              selectedTipo = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Por favor, seleccione un tipo';
                            }
                            return null;
                          },
                        ),
                  SizedBox(height: fieldSpacing),
                  widget.isFirstRun
                      ? _buildReadOnlyField('Estado', 'Activo')
                      : _buildDropdown(
                          value: selectedEstado,
                          items: estado,
                          label: 'Estado',
                          icon: Icons.person,
                          onChanged: (value) {
                            setState(() {
                              selectedEstado = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Por favor, seleccione un estado';
                            }
                            return null;
                          },
                        ),
                ],
              ),

              // Botón de confirmar
              SizedBox(height: fieldSpacing * 1.25),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _isProcessing
                        ? null
                        : widget.isEdit
                        ? _actualizarUsuario()
                        : agregarUsuario();
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, buttonHeight),
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: isMobile ? 12.0 : 16.0,
                  ),
                ),
                child: Text(
                  'Confirmar',
                  style: TextStyle(
                    fontSize: buttonFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              // Botón de cancelar (solo en escritorio)
              if (isDesktop)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        fontSize: 16,
                        color: Provider.of<TemaProveedor>(context).esModoOscuro
                            ? Colors.white.withOpacity(0.8)
                            : Colors.black.withOpacity(0.8),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
    bool isEmail = false,
    bool isPassword = false,
    bool isPrefijo = false,
    bool isTelefono = false,
  }) {
    // Obtenemos el tamaño de la pantalla
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;
    final bool isDesktop = screenSize.width >= 900;

    // Ajustamos tamaños según el dispositivo
    final double labelFontSize = isMobile ? 14.0 : (isTablet ? 15.0 : 16.0);
    final double inputFontSize = isMobile ? 14.0 : (isTablet ? 15.0 : 16.0);
    final double verticalPadding = isMobile ? 15.0 : (isTablet ? 16.0 : 18.0);
    final double horizontalPadding = isMobile ? 10.0 : (isTablet ? 12.0 : 14.0);

    // Colores basados en el tema (evitamos repeticiones de Provider.of)
    final themeProvider = Provider.of<TemaProveedor>(context);
    final bool isDarkMode = themeProvider.esModoOscuro;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final double iconSize = isMobile ? 22.0 : (isTablet ? 24.0 : 26.0);

    return TextFormField(
      readOnly: isPrefijo,
      controller: controller,
      keyboardType: isNumber
          ? TextInputType.number
          : isEmail
          ? TextInputType.emailAddress
          : isTelefono ? TextInputType.phone : TextInputType.text,
      inputFormatters: isNumber
          ? <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly, // Permite solo dígitos
            ]
          : null,
      obscureText: isPassword ? _obscureText : false,
      style: TextStyle(
        fontSize: inputFontSize,
        color: Provider.of<TemaProveedor>(context).esModoOscuro
            ? Colors.white
            : Colors.black,
      ),
      decoration: InputDecoration(
        suffixIcon: isPassword
            ? IconButton(
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
              )
            : null,
        labelText: label,
        labelStyle: TextStyle(
          color: Provider.of<TemaProveedor>(context).esModoOscuro
              ? Colors.white
              : Colors.black,
          fontSize: labelFontSize,
        ),
        filled: true,
        fillColor: Provider.of<TemaProveedor>(context).esModoOscuro
            ? const Color.fromRGBO(30, 30, 30, 1)
            : Colors.white,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
          borderSide: BorderSide(
            color: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Colors.white
                : Colors.black,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Colors.white
                : Colors.black,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2.0),
        ),
        errorStyle: TextStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.w500,
          fontSize: isMobile ? 12.0 : 13.0,
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: verticalPadding,
          horizontal: horizontalPadding,
        ),
      ),
      validator: (value) {
        if (value!.isEmpty) {
          return 'Por favor, ingrese el $label';
        } else if (isNumber && value.contains('-')) {
          return 'Por favor, ingrese números positivos';
        } else if (isEmail) {
          // Regex simplificado para email (más legible y eficiente)
          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
          if (!emailRegex.hasMatch(value)) {
            return 'Por favor, ingrese un correo válido';
          }
        } else if (isPassword) {
          if (value.length < 8) {
            return 'La contraseña debe tener al menos 8 caracteres';
          }
        }
        return null;
      },
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

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String label,
    required IconData icon,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    // Obtenemos el tamaño de la pantalla
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;
    final bool isDesktop = screenSize.width >= 900;

    // Ajustamos tamaños según el dispositivo
    final double labelFontSize = isMobile ? 14.0 : (isTablet ? 15.0 : 16.0);
    final double inputFontSize = isMobile ? 14.0 : (isTablet ? 15.0 : 16.0);
    final double verticalPadding = isMobile ? 15.0 : (isTablet ? 16.0 : 18.0);
    final double horizontalPadding = isMobile ? 10.0 : (isTablet ? 12.0 : 14.0);

    final temaOscuro = Provider.of<TemaProveedor>(context).esModoOscuro;

    return DropdownButtonFormField<String>(
      dropdownColor: temaOscuro ? Colors.black : Colors.white,
      value: value,
      items: items.map<DropdownMenuItem<String>>((String item) {
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      style: TextStyle(
        fontSize: inputFontSize,
        color: temaOscuro ? Colors.white : Colors.black,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: temaOscuro ? Colors.white : Colors.black,
          fontSize: labelFontSize,
        ),
        filled: true,
        fillColor: temaOscuro
            ? const Color.fromRGBO(30, 30, 30, 1)
            : Colors.white,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
          borderSide: BorderSide(
            color: temaOscuro ? Colors.white : Colors.black,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: temaOscuro ? Colors.white : Colors.black,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2.0),
        ),
        errorStyle: TextStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.w500,
          fontSize: isMobile ? 12.0 : 13.0,
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: verticalPadding,
          horizontal: horizontalPadding,
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return _buildTextField(
      TextEditingController(text: value),
      label,
      isPrefijo: true,
    );
  }
}
