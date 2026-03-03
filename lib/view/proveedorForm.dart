import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proyecto_cd2/controller/repository_proveedor.dart';
import 'package:proyecto_cd2/model/app_logger.dart';
import 'package:proyecto_cd2/model/preferences.dart';
import 'package:proyecto_cd2/model/proveedor.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class ProveedorForm extends StatefulWidget {
  bool isEdit;
  int? id;
  String nombre;
  String direccion;
  String telefono;
  String correo;
  String fechaRegistro;
  String fechaActualizacion;
  String estado;

  ProveedorForm({
    super.key,
    this.isEdit = false,
    this.id,
    this.nombre = '',
    this.direccion = '',
    this.telefono = '',
    this.correo = '',
    this.fechaRegistro = '',
    this.fechaActualizacion = '',
    this.estado = '',
  });

  @override
  State<ProveedorForm> createState() => _ProveedorFormState();
}

class _ProveedorFormState extends State<ProveedorForm> {
  final TextEditingController _nombre = TextEditingController();
  final TextEditingController _direccion = TextEditingController();
  final TextEditingController _telefono = TextEditingController();
  final TextEditingController _correo = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  List<String> estado = ['Activo', 'Inactivo'];
  String? selectedEstado;

  final ProveedorRepository _proveedorRepository = ProveedorRepository();
  final AppLogger _logger = AppLogger.instance;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      _nombre.text = widget.nombre;
      _direccion.text = widget.direccion;
      _telefono.text = widget.telefono;
      _correo.text = widget.correo;
      if (estado.isNotEmpty) {
        selectedEstado = estado.firstWhere(
          (item) => item == widget.estado,
          orElse: () => estado.first,
        );
      }
    }
  }

  void _mostrarMensaje(String titulo, String mensaje, ContentType type) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: titulo,
        message: mensaje,
        contentType: type,
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  void _guardarProveedor() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final proveedor = Proveedor(
        id: widget.id,
        nombre: _nombre.text.trim(),
        direccion: _direccion.text.trim(),
        telefono: _telefono.text.trim(),
        correo: _correo.text.trim(),
        estado: selectedEstado,
        fechaRegistro: widget.isEdit
            ? widget.fechaRegistro
            : DateTime.now().toIso8601String(),
        fechaActualizacion: DateTime.now().toIso8601String(),
      );

      if (widget.isEdit) {
        await _proveedorRepository.updateProveedor(proveedor);
        _mostrarMensaje(
          'Éxito',
          'Proveedor actualizado correctamente',
          ContentType.success,
        );
      } else {
        await _proveedorRepository.insertProveedor(proveedor);
        _mostrarMensaje(
          'Éxito',
          'Proveedor creado correctamente',
          ContentType.success,
        );
      }
      Navigator.pop(context, true);
    } catch (e, stackTrace) {
      _mostrarMensaje(
        'Error',
        'Error al guardar el proveedor',
        ContentType.warning,
      );
      _logger.log.e(
        'Error al guardar proveedor',
        error: e,
        stackTrace: stackTrace,
      );
      Navigator.pop(context, true);
    }
  }

  void _eliminarProveedor() async {
    // Obtenemos el tamaño de la pantalla
    final screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;
    final bool isDesktop = screenSize.width >= 900;

    // Calculamos el ancho del awesomeDialog según el tamaño de pantalla
    final double dialogWidth = isDesktop
        ? screenSize.width * 0.3
        : (isTablet ? screenSize.width * 0.5 : screenSize.width * 0.8);
    AwesomeDialog(
      width: isDesktop ? (screenSize.width - dialogWidth) / 2 : null,
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: 'Eliminar proveedor',
      desc: '¿Está seguro que desea eliminar a este proveedor?',
      btnCancelText: 'No, cancelar',
      btnOkText: 'Si, eliminar',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        try {
          await _proveedorRepository.deleteProveedor(widget.id!);
          _mostrarMensaje(
            'Éxito',
            'Proveedor eliminado correctamente',
            ContentType.success,
          );
          Navigator.pop(context, true);
        } catch (e, stackTrace) {
          _mostrarMensaje(
            'Error',
            'Error al eliminar el proveedor',
            ContentType.warning,
          );
          _logger.log.e(
            'Error al eliminar proveedor',
            error: e,
            stackTrace: stackTrace,
          );
          Navigator.pop(context, true);
        }
      },
      dialogBackgroundColor:
          Provider.of<TemaProveedor>(context, listen: false).esModoOscuro
          ? Color.fromRGBO(60, 60, 60, 1)
          : Color.fromRGBO(220, 220, 220, 1),
    ).show();
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
        title: Text(
          widget.isEdit ? 'Editar proveedor' : 'Nuevo proveedor',
          style: TextStyle(
            color: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Colors.white
                : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: titleFontSize,
          ),
        ),
        centerTitle: true,
        backgroundColor: Provider.of<TemaProveedor>(context).esModoOscuro
            ? Colors.black
            : const Color.fromRGBO(244, 243, 243, 1),
        iconTheme: IconThemeData(
          color: Provider.of<TemaProveedor>(context).esModoOscuro
              ? Colors.white
              : Colors.black,
        ),
        actions: [
          if (widget.isEdit)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _eliminarProveedor,
              tooltip: 'Eliminar Proveedor',
            ),
        ],
      ),
      body: isDesktop ? _buildDesktopLayout() : Stack(children: [formulario()]),
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
                      widget.isEdit ? Icons.edit_note : Icons.person_add,
                      size: 120,
                      color: Provider.of<TemaProveedor>(context).esModoOscuro
                          ? Colors.white.withOpacity(0.8)
                          : Colors.blueAccent.withOpacity(0.8),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.isEdit
                          ? 'Actualizar proveedor'
                          : 'Nuevo proveedor',
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
                          ? 'Modifica los datos del proveedor según sea necesario.'
                          : 'Completa el formulario para registrar un nuevo proveedor.',
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
              _buildTextField(_nombre, 'Nombre del proveedor'),
              SizedBox(height: fieldSpacing),

              // Dirección
              _buildTextField(_direccion, 'Dirección'),
              SizedBox(height: fieldSpacing),

              // Teléfono
              _buildTextField(_telefono, 'Teléfono', isTelefono: true),
              SizedBox(height: fieldSpacing),

              // Correo / Información adicional
              _buildTextField(_correo, 'Correo / Información', isCorreo: true),

              // Estado
              Column(
                children: [
                  SizedBox(height: fieldSpacing),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdownEstado(
                          value: selectedEstado,
                          items: estado,
                          label: 'Seleccionar estado',
                          icon: Icons.category,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedEstado = newValue;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Por favor selecciona una opción';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: isMobile ? 8.0 : 12.0),
                    ],
                  ),
                ],
              ),

              // Botón de confirmar
              SizedBox(height: fieldSpacing * 1.25),
              ElevatedButton(
                onPressed: _guardarProveedor,
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
                  'Guardar',
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
    bool isTelefono = false,
    bool isCorreo = false,
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

    return TextFormField(
      controller: controller,
      keyboardType: isTelefono
          ? TextInputType.phone
          : isCorreo
          ? TextInputType.emailAddress
          : TextInputType.text,
      style: TextStyle(
        fontSize: inputFontSize,
        color: Provider.of<TemaProveedor>(context).esModoOscuro
            ? Colors.white
            : Colors.black,
      ),
      decoration: InputDecoration(
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
        }
        return null;
      },
    );
  }

  Widget _buildDropdownEstado({
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
}
