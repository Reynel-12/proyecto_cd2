import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_cd2/controller/repository_user.dart';
import 'package:proyecto_cd2/model/app_logger.dart';
import 'package:proyecto_cd2/model/preferences.dart';
import 'package:proyecto_cd2/view/nuevo_usuario.dart';
import 'package:proyecto_cd2/view/widgets/loading.dart';

// ignore: must_be_immutable
class PerfilUsuario extends StatefulWidget {
  String docID;
  PerfilUsuario({super.key, required this.docID});

  @override
  State<PerfilUsuario> createState() => _PerfilUsuarioState();
}

class _PerfilUsuarioState extends State<PerfilUsuario> {
  String nombre = '';
  String apellido = '';
  String correo = '';
  String telefono = '';
  String rol = '';
  String estado = '';
  String fechaCreacion = '';
  String fechaActualizacion = '';
  String contrasena = '';
  bool isLoading = true;
  bool _isProcessing = false;

  final repo = RepositoryUser();
  final AppLogger _logger = AppLogger.instance;

  @override
  void dispose() {
    super.dispose();
  }

  ///Método para obtener el ultimo código de la orden de ttrabajo, dentro de la colección Control
  Future<void> _obtenerInfoUsuario() async {
    try {
      setState(() {
        isLoading = true;
      });
      final user = await repo.getUserById(int.parse(widget.docID));
      if (user != null) {
        setState(() {
          nombre = user.nombre;
          apellido = user.apellido;
          correo = user.correo;
          telefono = user.telefono;
          rol = user.tipo;
          estado = user.estado;
          contrasena = user.contrasena;
          fechaCreacion = user.fechaCreacion;
          fechaActualizacion = user.fechaActualizacion;
          isLoading = false;
        });
      }
    } catch (e, st) {
      _logger.log.e(
        'Error al obtener la información del usuario',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _obtenerInfoUsuario();
  }

  // Método para crear elementos del menú popup de manera más limpia
  PopupMenuItem _buildPopupMenuItem(String value, IconData icon, String text) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            color:
                Provider.of<TemaProveedor>(context, listen: false).esModoOscuro
                ? Colors.white
                : Colors.black,
            size: isMobile ? 20.0 : 22.0,
          ),
          SizedBox(width: isMobile ? 6.0 : 8.0),
          Text(text, style: TextStyle(fontSize: isMobile ? 14.0 : 16.0)),
        ],
      ),
    );
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
    final double contentPadding = isMobile ? 12.0 : (isTablet ? 16.0 : 24.0);
    final double cardElevation = isMobile ? 3.0 : 5.0;

    return Scaffold(
      backgroundColor: Provider.of<TemaProveedor>(context).esModoOscuro
          ? Colors.black
          : const Color.fromRGBO(244, 243, 243, 1),
      appBar: AppBar(
        title: Text(
          'Información',
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
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Colors.white
                : Colors.black,
          ),
          onPressed: () => Navigator.pop(context, true),
        ),
        actions: [
          isLoading
              ? Container()
              : PopupMenuButton(
                  color: Provider.of<TemaProveedor>(context).esModoOscuro
                      ? const Color.fromRGBO(30, 30, 30, 1)
                      : const Color.fromRGBO(244, 243, 243, 1),
                  icon: Icon(
                    Icons.more_vert,
                    color: Provider.of<TemaProveedor>(context).esModoOscuro
                        ? Colors.white
                        : Colors.black,
                    size: isMobile ? 22.0 : 24.0,
                  ),
                  itemBuilder: (context) => [
                    _buildPopupMenuItem('editar', Icons.edit, 'Editar usuario'),
                    _buildPopupMenuItem(
                      'eliminar',
                      Icons.delete,
                      'Eliminar usuario',
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'editar':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NuevoUsuario(
                              isEdit: true,
                              uid: widget.docID,
                              nombre: nombre,
                              apellido: apellido,
                              telefono: telefono,
                              tipo: rol,
                              estado: estado,
                            ),
                          ),
                        ).then((value) {
                          if (value == true) {
                            _obtenerInfoUsuario();
                          }
                        });
                        break;
                      case 'eliminar':
                        eliminarUserDialog();
                        break;
                    }
                  },
                ),
        ],
      ),
      body: isLoading
          ? CargandoInventario()
          : Stack(
              children: [
                isDesktop
                    ? _buildDesktopLayout(contentPadding, cardElevation)
                    : _buildMobileTabletLayout(contentPadding, cardElevation),
                if (_isProcessing) CircularProgressIndicator(),
              ],
            ),
    );
  }

  // Layout para móvil y tablet (diseño vertical)
  Widget _buildMobileTabletLayout(double padding, double elevation) {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.all(padding),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_buildProductInfo(elevation)],
            ),
          ),
        ),
      ],
    );
  }

  // Layout para escritorio (diseño horizontal)
  Widget _buildDesktopLayout(double padding, double elevation) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Columna izquierda con información del producto
          Expanded(flex: 2, child: _buildProductInfo(elevation)),
        ],
      ),
    );
  }

  Widget _buildProductInfo(double elevation) {
    // Ajustamos tamaños según el dispositivo
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;

    final double titleFontSize = isMobile ? 20.0 : (isTablet ? 22.0 : 24.0);
    final double infoFontSize = isMobile ? 14.0 : (isTablet ? 15.0 : 16.0);

    return Card(
      color: Provider.of<TemaProveedor>(context).esModoOscuro
          ? const Color.fromRGBO(30, 30, 30, 1)
          : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: elevation,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: isMobile ? 24.0 : 28.0,
                  color: Provider.of<TemaProveedor>(context).esModoOscuro
                      ? Colors.white
                      : Colors.black,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$nombre $apellido',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: Provider.of<TemaProveedor>(context).esModoOscuro
                          ? Colors.white
                          : Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 12.0 : 16.0),
            _infoRow('Correo', correo, infoFontSize),
            _infoRow('Teléfono', telefono, infoFontSize),
            _infoRow('Rol del usuario', rol, infoFontSize),
            _infoRow('Estado', estado, infoFontSize),
            _infoRow(
              'Fecha de creación',
              DateFormat(
                'dd/MM/yyyy HH:mm:ss',
              ).format(DateTime.parse(fechaCreacion)),
              infoFontSize,
            ),
            _infoRow(
              'Fecha de actualización',
              DateFormat(
                'dd/MM/yyyy HH:mm:ss',
              ).format(DateTime.parse(fechaActualizacion)),
              infoFontSize,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, double fontSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: Provider.of<TemaProveedor>(context).esModoOscuro
                  ? Colors.white
                  : Colors.black,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              color: Provider.of<TemaProveedor>(context).esModoOscuro
                  ? Colors.white
                  : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  void eliminarUserDialog() {
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
      dialogBackgroundColor:
          Provider.of<TemaProveedor>(context, listen: false).esModoOscuro
          ? Color.fromRGBO(60, 60, 60, 1)
          : Color.fromRGBO(220, 220, 220, 1),
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: 'Atención',
      desc: '¿Está seguro que desea eliminar este usuario?',
      btnCancelText: 'No, cancelar',
      btnOkText: 'Si, eliminar',
      btnOkOnPress: () {
        _eliminarUser();
      },
      btnCancelOnPress: () {},
    ).show();
  }

  void _eliminarUser() async {
    try {
      await repo.deleteUser(int.parse(widget.docID));
      _mostrarMensaje(
        'Éxito',
        'Usuario eliminado correctamente',
        ContentType.success,
      );
      Navigator.pop(context, true);
    } catch (e, st) {
      _mostrarMensaje(
        'Error',
        'Error al eliminar el usuario',
        ContentType.failure,
      );
      Navigator.pop(context, true);
      _logger.log.e('Error al eliminar el usuario', error: e, stackTrace: st);
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
}
