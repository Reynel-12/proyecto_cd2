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
  bool isValidateDay = true;

  final ProveedorRepository _proveedorRepository = ProveedorRepository();
  final AppLogger _logger = AppLogger.instance;

  // Variables para manejar días
  List<Map<String, dynamic>> diasDisponibles = [];
  List<Map<String, dynamic>> diasSeleccionados = [];
  String? diaSeleccionadoTemporal;
  bool cargandoDias = true;

  @override
  void initState() {
    super.initState();
    _cargarDias();
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

  Future<void> _cargarDias() async {
    try {
      final dias = await _proveedorRepository.obtenerDias();
      setState(() {
        diasDisponibles = dias;
        cargandoDias = false;
      });

      // Si es edición, cargar los días del proveedor
      if (widget.isEdit && widget.id != null) {
        final diasProveedor = await _proveedorRepository.obtenerDiasProveedor(
          widget.id!,
        );
        setState(() {
          diasSeleccionados = diasProveedor;
        });
      }
    } catch (e, st) {
      _logger.log.e('Error al cargar días', error: e, stackTrace: st);
      setState(() {
        cargandoDias = false;
      });
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
    if (!_formKey.currentState!.validate()) {
      if (diasSeleccionados.isEmpty) {
        setState(() {
          isValidateDay = false;
        });
        return;
      }
      return;
    }
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

        // Actualizar días: eliminar todos y agregar los nuevos
        await _proveedorRepository.eliminarTodosDiasProveedor(widget.id!);
        for (var dia in diasSeleccionados) {
          await _proveedorRepository.insertarDiaProveedor(
            widget.id!,
            dia['id_dia'],
          );
        }

        _mostrarMensaje(
          'Éxito',
          'Proveedor actualizado correctamente',
          ContentType.success,
        );
      } else {
        final nuevoProveedorId = await _proveedorRepository.insertProveedor(
          proveedor,
        );

        // Insertar los días para el nuevo proveedor
        if (nuevoProveedorId > 0) {
          for (var dia in diasSeleccionados) {
            await _proveedorRepository.insertarDiaProveedor(
              nuevoProveedorId,
              dia['id_dia'],
            );
          }
        }

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

  void _agregarDia() {
    if (diaSeleccionadoTemporal == null ||
        diaSeleccionadoTemporal!.isEmpty ||
        diaSeleccionadoTemporal == 'Seleccionar día' ||
        diaSeleccionadoTemporal == '') {
      _mostrarMensaje(
        'Atención',
        'Por favor selecciona un día',
        ContentType.warning,
      );
      return;
    } else if (diasSeleccionados.length >= 7) {
      _mostrarMensaje(
        'Atención',
        'No puedes seleccionar más de 7 días',
        ContentType.warning,
      );
      return;
    }

    final diaExistente = diasSeleccionados.firstWhere(
      (dia) => dia['id_dia'].toString() == diaSeleccionadoTemporal,
      orElse: () => {},
    );

    if (diaExistente.isNotEmpty) {
      _mostrarMensaje(
        'Atención',
        'Este día ya está seleccionado',
        ContentType.warning,
      );
      return;
    }

    final diaPorAgregar = diasDisponibles.firstWhere(
      (dia) => dia['id_dia'].toString() == diaSeleccionadoTemporal,
    );

    setState(() {
      diasSeleccionados.add(diaPorAgregar);
      diaSeleccionadoTemporal = null;
    });
  }

  void _quitarDia(int idDia) {
    setState(() {
      diasSeleccionados.removeWhere((dia) => dia['id_dia'] == idDia);
    });
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

              // Sección de Días
              SizedBox(height: fieldSpacing * 1.5),
              _buildSeccionDias(isMobile, isTablet, isDesktop, fieldSpacing),

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

  Widget _buildSeccionDias(
    bool isMobile,
    bool isTablet,
    bool isDesktop,
    double fieldSpacing,
  ) {
    final temaOscuro = Provider.of<TemaProveedor>(context).esModoOscuro;
    final double labelFontSize = isMobile ? 14.0 : (isTablet ? 15.0 : 16.0);
    final double inputFontSize = isMobile ? 14.0 : (isTablet ? 15.0 : 16.0);

    if (cargandoDias) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3), width: 2),
        borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
        color: temaOscuro
            ? const Color.fromRGBO(30, 30, 30, 1)
            : Colors.white.withOpacity(0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Row(
            children: [
              Icon(
                Icons.calendar_month,
                color: Colors.blueAccent,
                size: isMobile ? 20 : 24,
              ),
              SizedBox(width: 12),
              Text(
                'Días de entrega',
                style: TextStyle(
                  fontSize: labelFontSize + 2,
                  fontWeight: FontWeight.bold,
                  color: temaOscuro ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: fieldSpacing),

          // Selector de día
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  dropdownColor: temaOscuro ? Colors.black : Colors.white,
                  value: diaSeleccionadoTemporal,
                  hint: Text(
                    'Seleccionar día',
                    style: TextStyle(
                      color: temaOscuro ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  items: diasDisponibles.map<DropdownMenuItem<String>>((dia) {
                    // Validar si el día ya está seleccionado
                    final yaSeleccionado = diasSeleccionados.any(
                      (selected) => selected['id_dia'] == dia['id_dia'],
                    );
                    return DropdownMenuItem<String>(
                      value: dia['id_dia'].toString(),
                      enabled: !yaSeleccionado,
                      child: Text(
                        dia['nombre'],
                        style: TextStyle(
                          color: yaSeleccionado
                              ? Colors.grey
                              : (temaOscuro ? Colors.white : Colors.black),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      diaSeleccionadoTemporal = value;
                    });
                  },
                  style: TextStyle(
                    fontSize: inputFontSize,
                    color: temaOscuro ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: temaOscuro
                        ? const Color.fromRGBO(30, 30, 30, 1)
                        : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
                      borderSide: BorderSide(
                        color: Colors.blueAccent.withOpacity(0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.blueAccent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
                      borderSide: BorderSide(
                        color: Colors.blueAccent.withOpacity(0.3),
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: isMobile ? 12.0 : 14.0,
                      horizontal: isMobile ? 10.0 : 12.0,
                    ),
                  ),
                  // validator: (value) {
                  //   if (value == null) {
                  //     return 'Por favor selecciona una opción';
                  //   }
                  //   return null;
                  // },
                ),
              ),
              SizedBox(width: isMobile ? 8.0 : 12.0),
              // Botón para agregar día
              Container(
                height: isMobile ? 48 : 56,
                width: isMobile ? 48 : 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blueAccent, Colors.blue.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _agregarDia,
                    borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: isMobile ? 20 : 24,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Lista de días seleccionados
          if (diasSeleccionados.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: fieldSpacing),
                Text(
                  'Días seleccionados:',
                  style: TextStyle(
                    fontSize: labelFontSize,
                    fontWeight: FontWeight.w600,
                    color: temaOscuro ? Colors.white70 : Colors.black54,
                  ),
                ),
                SizedBox(height: 12),
                Wrap(
                  spacing: isMobile ? 8.0 : 12.0,
                  runSpacing: isMobile ? 8.0 : 12.0,
                  children: diasSeleccionados.map((dia) {
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12.0 : 14.0,
                        vertical: isMobile ? 8.0 : 10.0,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blueAccent.withOpacity(0.8),
                            Colors.blue.shade600.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.event_available,
                            color: Colors.white,
                            size: isMobile ? 16 : 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            dia['nombre'],
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: inputFontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _quitarDia(dia['id_dia']),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: isMobile ? 16 : 18,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            )
          else
            Padding(
              padding: EdgeInsets.only(top: fieldSpacing / 2),
              child: Center(
                child: Text(
                  'Sin días seleccionados',
                  style: TextStyle(
                    fontSize: labelFontSize - 2,
                    color: !isValidateDay
                        ? Colors.red
                        : temaOscuro
                        ? Colors.white70
                        : Colors.black54,
                    fontStyle: FontStyle.italic,
                    fontWeight: !isValidateDay
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
        ],
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
