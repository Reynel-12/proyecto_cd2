import 'dart:io';
import 'package:proyecto_cd2/controller/repository_categoria.dart';
import 'package:proyecto_cd2/model/categorias.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proyecto_cd2/model/app_logger.dart';
import 'package:proyecto_cd2/model/preferences.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_cd2/view/barcode_scanner_view.dart';

// ignore: must_be_immutable
class NuevaCategoria extends StatefulWidget {
  bool isEdit;
  bool isEditNombre;
  bool isEditEstado;
  bool isEditDescripcion;
  int codigo;
  String nombre;
  String descripcion;
  String estado;
  String fechaCreacion;
  String fechaActualizacion;
  NuevaCategoria({
    super.key,
    this.isEdit = false,
    this.isEditNombre = false,
    this.isEditEstado = false,
    this.isEditDescripcion = false,
    this.codigo = 0,
    this.nombre = '',
    this.descripcion = '',
    this.estado = '',
    this.fechaCreacion = '',
    this.fechaActualizacion = '',
  });

  @override
  State<NuevaCategoria> createState() => _NuevaCategoriaState();
}

class _NuevaCategoriaState extends State<NuevaCategoria> {
  final TextEditingController _descripcion = TextEditingController();
  final TextEditingController _nombre = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AppLogger _logger = AppLogger.instance;

  final RepositoryCategoria _categoriaRepository = RepositoryCategoria();

  List<String> estado = ['Activo', 'Inactivo'];
  String? selectedEstado;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      _descripcion.text = widget.descripcion;
      _nombre.text = widget.nombre;
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
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: titulo,
        message: mensaje,

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: type,
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  Future<void> _updateCategoria() async {
    String nombre = _nombre.text;
    String descripcion = _descripcion.text;

    try {
      final categoria = Categorias(
        idCategoria: widget.codigo,
        descripcion: descripcion,
        nombre: nombre,
        fechaActualizacion: DateTime.now().toIso8601String(),
        fechaCreacion: widget.fechaCreacion,
        estado: selectedEstado,
      );
      await _categoriaRepository.updateCategoria(categoria);
      _mostrarMensaje(
        'Éxito',
        'Categoria actualizada correctamente',
        ContentType.success,
      );
      Navigator.pop(context, true);
    } catch (e, stackTrace) {
      _mostrarMensaje('Error', 'Error inesperado', ContentType.failure);
      _logger.log.e(
        'Error al actualizar la categoria',
        error: e,
        stackTrace: stackTrace,
      );
      Navigator.pop(context, false);
    }
  }

  void agregarCategoria() async {
    try {
      String nombre = _nombre.text.trim();
      String descripcion = _descripcion.text.trim();
      String fechaCreacion = DateTime.now().toIso8601String();
      final categoria = Categorias(
        nombre: nombre,
        descripcion: descripcion,
        fechaCreacion: fechaCreacion,
        fechaActualizacion: DateTime.now().toIso8601String(),
        estado: selectedEstado,
      );
      await _categoriaRepository.insertCategoria(categoria);
      _mostrarMensaje(
        'Éxito',
        'Categoria creada correctamente',
        ContentType.success,
      );
      Navigator.pop(context, true);
    } catch (e, stackTrace) {
      _mostrarMensaje('Error', 'Error inesperado', ContentType.failure);
      _logger.log.e(
        'Error al agregar la categoria',
        error: e,
        stackTrace: stackTrace,
      );
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
        title: Text(
          widget.isEdit ? 'Editar categoria' : 'Agregar categoria',
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
      ),
      body: isDesktop
          ? _buildDesktopLayout()
          : Stack(children: [widget.isEdit ? formulario() : formulario()]),
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
                          ? 'Actualizar categoria'
                          : 'Nueva categoria',
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
                          ? 'Modifica los datos de la categoria según sea necesario.'
                          : 'Completa el formulario para agregar una nueva categoria.',
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
              if ((widget.isEdit && widget.isEditNombre) || !widget.isEdit)
                Column(
                  children: [
                    SizedBox(height: fieldSpacing),
                    _buildTextField(_nombre, 'Nombre'),
                  ],
                ),

              // Descripcion
              if ((widget.isEdit && widget.isEditDescripcion) || !widget.isEdit)
                Column(
                  children: [
                    SizedBox(height: fieldSpacing),
                    _buildTextField(
                      _descripcion,
                      widget.isEdit ? 'Descripción' : 'Descripción',
                      maxLines: 3,
                    ),
                  ],
                ),

              // Estado
              if ((widget.isEdit && widget.isEditEstado) || !widget.isEdit)
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
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.isEdit ? _updateCategoria() : agregarCategoria();
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
    bool code = false,
    bool readOnly = false,
    int maxLines = 1,
  }) {
    // Obtenemos el tamaño de la pantalla
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;
    final bool isDesktop = screenSize.width >= 900;

    // Ajustamos tamaños según el dispositivo
    final double labelFontSize = isMobile ? 14.0 : (isTablet ? 15.0 : 16.0);
    final double inputFontSize = isMobile ? 14.0 : (isTablet ? 15.0 : 16.0);
    final double iconSize = isMobile ? 22.0 : (isTablet ? 24.0 : 26.0);
    final double verticalPadding = isMobile ? 15.0 : (isTablet ? 16.0 : 18.0);
    final double horizontalPadding = isMobile ? 10.0 : (isTablet ? 12.0 : 14.0);

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber
          ? <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly, // Permite solo dígitos
            ]
          : null,
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
        suffixIcon: code
            ? IconButton(
                icon: Icon(
                  Icons.barcode_reader,
                  color: Provider.of<TemaProveedor>(context).esModoOscuro
                      ? Colors.white
                      : Colors.black,
                  size: iconSize,
                ),
                onPressed: () async {
                  if (Platform.isAndroid || Platform.isIOS) {
                    final scannedCode = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => BarcodeScannerView()),
                    );

                    if (scannedCode != null && widget.isEdit) {
                      controller.text = widget.codigo.toString();
                    } else if (scannedCode == null) {
                      _mostrarMensaje(
                        'Atención',
                        'Escaneo cancelado',
                        ContentType.warning,
                      );
                    } else if (scannedCode != null) {
                      controller.text = scannedCode;
                    }
                  }
                },
              )
            : null,
      ),
      validator: (value) {
        if (value!.isEmpty) {
          return 'Por favor, ingrese el $label';
        } else if (isNumber && value.contains('-')) {
          return 'Por favor, ingrese números positivos';
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
