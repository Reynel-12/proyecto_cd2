import 'package:proyecto_cd2/controller/repository_categoria.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proyecto_cd2/controller/repository_producto.dart';
import 'package:proyecto_cd2/controller/repository_proveedor.dart';
import 'package:proyecto_cd2/model/app_logger.dart';
import 'package:proyecto_cd2/model/preferences.dart';
import 'package:proyecto_cd2/controller/repository_venta.dart';
import 'package:proyecto_cd2/view/productoForm.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:proyecto_cd2/view/widgets/loading.dart';

// ignore: must_be_immutable
class PerfilProducto extends StatefulWidget {
  String docID;
  int idProveedor;
  int idCategoria;
  PerfilProducto({
    super.key,
    required this.docID,
    required this.idProveedor,
    required this.idCategoria,
  });

  @override
  State<PerfilProducto> createState() => _PerfilProductoState();
}

class _PerfilProductoState extends State<PerfilProducto> {
  final repositoryProveedor = ProveedorRepository();
  final repositoryProducto = ProductoRepository();
  final repositoryCategoria = RepositoryCategoria();
  final TextEditingController _cantidad = TextEditingController();
  final TextEditingController _inventarioController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String nombreProveedor = '';
  String nombreCategoria = '';
  // final _movimientoRepo = CajaRepository();
  final AppLogger _logger = AppLogger.instance;
  final _ventaRepo = VentaRepository();
  double totalVentas = 0;
  List<Map<String, dynamic>> ultimasVentas = [];
  bool isLoading = false;
  bool isLoadingProveedor = false;

  String nombre = '';
  String unidad = '';
  double precio = 0.0;
  double costos = 0.0;
  double isv = 0.0;
  double precioVenta = 0.0;
  int idProveedor = 0;
  int inventario = 0;
  int stockMinimo = 0;
  String estado = '';
  String fechaCreacion = '';
  String fechaActualizacion = '';

  List<String> _metodosPago = ['Efectivo', 'Tarjeta', 'Transferencia'];
  String _metodoPago = 'Efectivo';

  @override
  void initState() {
    super.initState();
    _getProducto();
    _getProveedor();
  }

  Future<void> _getProveedor() async {
    try {
      setState(() {
        isLoadingProveedor = true;
      });
      final proveedor = await repositoryProveedor.getProveedorById(
        widget.idProveedor,
      );
      final categoria = await repositoryCategoria.getCategoriaById(
        widget.idCategoria,
      );
      // final caja = await _movimientoRepo.obtenerCajaAbierta();
      final total = await _ventaRepo.getTotalVentasByProducto(widget.docID);
      final ultimas = await _ventaRepo.getUltimasVentasByProducto(widget.docID);

      setState(() {
        nombreProveedor = proveedor[0].nombre;
        nombreCategoria = categoria[0].nombre!;
        // _cajaSeleccionada = caja;
        totalVentas = total;
        ultimasVentas = ultimas;
        isLoadingProveedor = false;
      });
    } catch (e, st) {
      _mostrarMensaje(
        'Error',
        'Error al obtener la informacion del proveedor',
        ContentType.failure,
      );
      _logger.log.e(
        'Error al obtener la informacion del proveedor',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _getProducto() async {
    try {
      setState(() {
        isLoading = true;
      });
      final producto = await repositoryProducto.getProductoByID(widget.docID);
      setState(() {
        nombre = producto!.nombre;
        unidad = producto.unidadMedida!;
        precio = producto.precio;
        costos = producto.costo;
        isv = producto.isv;
        precioVenta = producto.precioVenta;
        widget.idProveedor = producto.proveedorId!;
        inventario = producto.stock;
        stockMinimo = producto.stockMinimo;
        estado = producto.estado!;
        fechaCreacion = producto.fechaCreacion!;
        fechaActualizacion = producto.fechaActualizacion!;
        isLoading = false;
      });
    } catch (e, st) {
      _mostrarMensaje(
        'Error',
        'Error al obtener la informacion del producto',
        ContentType.failure,
      );
      _logger.log.e(
        'Error al obtener la informacion del producto',
        error: e,
        stackTrace: st,
      );
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

  // Función para manejar la navegación y la lógica de actualización
  void _navigateToEdit(
    BuildContext context,
    bool isEdit,
    bool isEditNombre,
    bool isEditUnidad,
    bool isEditPrecio,
    bool isEditProveedor,
    bool isEditCosto,
    bool isEditEstado,
    bool isEditCategoria,
    bool isEditISV,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Nuevoproducto(
          isEdit: isEdit,
          codigo: widget.docID,
          isEditNombre: isEditNombre,
          isEditUnidad: isEditUnidad,
          isEditPrecio: isEditPrecio,
          isEditProveedor: isEditProveedor,
          isEditCosto: isEditCosto,
          isEditEstado: isEditEstado,
          isEditCategoria: isEditCategoria,
          isEditISV: isEditISV,
          inventario: inventario,
          nombre: nombre,
          precio: precio,
          costo: costos,
          unidadMedida: unidad,
          stock: inventario,
          proveedorId: widget.idProveedor,
          estado: estado,
          isv: isv,
          fechaCreacion: fechaCreacion,
          fechaActualizacion: fechaActualizacion,
        ),
      ),
    ).then((value) {
      if (value == true) {
        _getProducto();
        _getProveedor();
      }
    });
  }

  void addInventory() async {
    try {
      // final fecha = DateTime.now().toIso8601String();
      // final movimiento = MovimientoCaja(
      //   idCaja: _cajaSeleccionada!.id!,
      //   tipo: 'Egreso',
      //   concepto: 'Egreso de inventario',
      //   monto: precio * int.parse(_cantidad.text),
      //   metodoPago: _metodoPago,
      //   fecha: fecha,
      // );
      await repositoryProducto.addInventario(
        widget.docID,
        int.parse(_cantidad.text),
      );
      // await _movimientoRepo.registrarMovimiento(movimiento);
      _mostrarMensaje(
        'Éxito',
        'Se actualizó correctamente el inventario',
        ContentType.success,
      );
      // Navegar hacia atrás
      Navigator.pop(context);
    } catch (e, st) {
      _logger.log.e('Error al agregar inventario', error: e, stackTrace: st);
    }
  }

  void _editInventory() async {
    try {
      final inventario = int.parse(_inventarioController.text);
      if (inventario == inventario) {
        _mostrarMensaje(
          'Error',
          'El inventario no ha cambiado',
          ContentType.warning,
        );
        Navigator.pop(context);
        return;
      }
      await repositoryProducto.editInventario(widget.docID, inventario);
      // await _movimientoRepo.registrarMovimiento(movimiento!);
      _mostrarMensaje(
        'Éxito',
        'Inventario actualizado correctamente',
        ContentType.success,
      );
      Navigator.pop(context);
    } catch (e, st) {
      _logger.log.e('Error al editar inventario', error: e, stackTrace: st);
    }
  }

  void _eliminarProducto() async {
    try {
      await repositoryProducto.deleteProducto(widget.docID);
      Navigator.pop(context, true);
      _mostrarMensaje(
        'Éxito',
        'Producto eliminado correctamente',
        ContentType.success,
      );
      Navigator.pop(context, true);
    } catch (e, st) {
      _mostrarMensaje(
        'Error',
        'Error al eliminar el producto',
        ContentType.warning,
      );
      Navigator.pop(context);
      _logger.log.e('Error al eliminar el producto', error: e, stackTrace: st);
      return;
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
    final double contentPadding = isMobile ? 12.0 : (isTablet ? 16.0 : 24.0);
    final double cardElevation = isMobile ? 3.0 : 5.0;

    // Calculamos el ancho del awesomeDialog según el tamaño de pantalla
    final double dialogWidth = isDesktop
        ? screenSize.width * 0.3
        : (isTablet ? screenSize.width * 0.5 : screenSize.width * 0.8);

    return isLoading && isLoadingProveedor
        ? CargandoInventario()
        : Scaffold(
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
                onPressed: () {
                  Navigator.pop(context, true);
                },
                icon: Icon(Icons.arrow_back),
              ),
              actions: [
                PopupMenuButton(
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
                    _buildPopupMenuItem(
                      'editar_producto',
                      Icons.edit,
                      'Editar producto',
                    ),
                    _buildPopupMenuItem(
                      'editar_inventario',
                      Icons.inventory_2,
                      'Editar inventario',
                    ),
                    _buildPopupMenuItem(
                      'eliminar_producto',
                      Icons.delete,
                      'Eliminar producto',
                    ),
                  ],
                  onSelected: (value) async {
                    switch (value) {
                      case 'editar_producto':
                        _navigateToEdit(
                          context,
                          true,
                          true,
                          true,
                          true,
                          true,
                          true,
                          true,
                          true,
                          true,
                        );
                        break;
                      case 'editar_inventario':
                        _showEditInventory();
                        break;
                      case 'eliminar_producto':
                        AwesomeDialog(
                          width: isDesktop
                              ? (screenSize.width - dialogWidth) / 2
                              : null,
                          dialogBackgroundColor:
                              Provider.of<TemaProveedor>(
                                context,
                                listen: false,
                              ).esModoOscuro
                              ? Color.fromRGBO(60, 60, 60, 1)
                              : Color.fromRGBO(220, 220, 220, 1),
                          context: context,
                          dialogType: DialogType.warning,
                          animType: AnimType.scale,
                          title: 'Atención',
                          desc:
                              '¿Está seguro que desea eliminar este producto?',
                          btnCancelText: 'No, cancelar',
                          btnOkText: 'Sí, eliminar',
                          btnOkOnPress: () {
                            _eliminarProducto();
                          },
                          btnCancelOnPress: () {},
                        ).show();
                        break;
                    }
                  },
                ),
              ],
            ),
            body: isDesktop
                ? _buildDesktopLayout(contentPadding, cardElevation)
                : _buildMobileTabletLayout(contentPadding, cardElevation),
          );
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

  // Layout para móvil y tablet (diseño vertical)
  Widget _buildMobileTabletLayout(double padding, double elevation) {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.all(padding),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductInfo(elevation),
                SizedBox(height: padding),
                _buildStatsCard(elevation, padding),
                SizedBox(height: padding),
                _buildActionButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Layout para escritorio (diseño horizontal)
  Widget _buildDesktopLayout(double padding, double elevation) {
    // Obtenemos el tamaño de la pantalla
    final screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;
    final bool isDesktop = screenSize.width >= 900;

    // Calculamos el ancho del awesomeDialog según el tamaño de pantalla
    final double dialogWidth = isDesktop
        ? screenSize.width * 0.3
        : (isTablet ? screenSize.width * 0.5 : screenSize.width * 0.8);

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Columna izquierda con información del producto
          Expanded(flex: 2, child: _buildProductInfo(elevation)),

          SizedBox(width: padding),

          // Columna derecha con acciones y estadísticas
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Card(
                  color: Provider.of<TemaProveedor>(context).esModoOscuro
                      ? const Color.fromRGBO(30, 30, 30, 1)
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: elevation,
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Acciones',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color:
                                Provider.of<TemaProveedor>(context).esModoOscuro
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildActionButtonDesktop(
                          'Agregar inventario',
                          Icons.add_circle_outline,
                          Colors.blueAccent,
                          () {
                            _showAddInventory();
                          },
                        ),
                        SizedBox(height: 12),
                        _buildActionButtonDesktop(
                          'Eliminar producto',
                          Icons.delete,
                          Colors.redAccent,
                          () {
                            AwesomeDialog(
                              width: isDesktop
                                  ? (screenSize.width - dialogWidth) / 2
                                  : 24.0,
                              dialogBackgroundColor:
                                  Provider.of<TemaProveedor>(
                                    context,
                                    listen: false,
                                  ).esModoOscuro
                                  ? Color.fromRGBO(60, 60, 60, 1)
                                  : Color.fromRGBO(220, 220, 220, 1),
                              context: context,
                              dialogType: DialogType.warning,
                              animType: AnimType.scale,
                              title: 'Atención',
                              desc:
                                  '¿Está seguro que desea eliminar este producto?',
                              btnCancelText: 'Cancelar',
                              btnOkText: 'Eliminar',
                              btnOkOnPress: () {
                                _eliminarProducto();
                              },
                              btnCancelOnPress: () {},
                            ).show();
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: padding),

                // Tarjeta de estadísticas (ejemplo)
                Card(
                  color: Provider.of<TemaProveedor>(context).esModoOscuro
                      ? const Color.fromRGBO(30, 30, 30, 1)
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: elevation,
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estadísticas',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color:
                                Provider.of<TemaProveedor>(context).esModoOscuro
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildStatRow(
                          'Ventas totales',
                          totalVentas.toStringAsFixed(0),
                        ),
                        _buildStatRow(
                          'Última venta',
                          ultimasVentas.isNotEmpty
                              ? DateFormat('dd/MM/yyyy').format(
                                  DateTime.parse(ultimasVentas[0]['fecha']),
                                )
                              : 'N/A',
                        ),
                        _buildStatRow(
                          'Valor en inventario',
                          'L. ${inventario * costos}',
                        ),
                        if (ultimasVentas.isNotEmpty) ...[
                          SizedBox(height: 16),
                          Text(
                            'Últimas ventas',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color:
                                  Provider.of<TemaProveedor>(
                                    context,
                                  ).esModoOscuro
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                          SizedBox(height: 8),
                          ...ultimasVentas.map(
                            (v) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat(
                                      'dd/MM HH:mm',
                                    ).format(DateTime.parse(v['fecha'])),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          Provider.of<TemaProveedor>(
                                            context,
                                          ).esModoOscuro
                                          ? Colors.white70
                                          : Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    '${v['cantidad']} $unidad',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          Provider.of<TemaProveedor>(
                                            context,
                                          ).esModoOscuro
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Botón de acción para escritorio
  Widget _buildActionButtonDesktop(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(double elevation, double padding) {
    return Card(
      color: Provider.of<TemaProveedor>(context).esModoOscuro
          ? const Color.fromRGBO(30, 30, 30, 1)
          : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: elevation,
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estadísticas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Provider.of<TemaProveedor>(context).esModoOscuro
                    ? Colors.white
                    : Colors.black,
              ),
            ),
            SizedBox(height: 16),
            _buildStatRow('Ventas totales', totalVentas.toStringAsFixed(0)),
            _buildStatRow(
              'Última venta',
              ultimasVentas.isNotEmpty
                  ? DateFormat(
                      'dd/MM/yyyy',
                    ).format(DateTime.parse(ultimasVentas[0]['fecha']))
                  : 'N/A',
            ),
            _buildStatRow('Valor en inventario', 'L. ${inventario * costos}'),
            if (ultimasVentas.isNotEmpty) ...[
              SizedBox(height: 16),
              Text(
                'Últimas ventas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Provider.of<TemaProveedor>(context).esModoOscuro
                      ? Colors.white
                      : Colors.black,
                ),
              ),
              SizedBox(height: 8),
              ...ultimasVentas.map(
                (v) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat(
                          'dd/MM HH:mm',
                        ).format(DateTime.parse(v['fecha'])),
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              Provider.of<TemaProveedor>(context).esModoOscuro
                              ? Colors.white70
                              : Colors.black87,
                        ),
                      ),
                      Text(
                        '${v['cantidad']} $unidad',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color:
                              Provider.of<TemaProveedor>(context).esModoOscuro
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Fila de estadísticas
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Provider.of<TemaProveedor>(context).esModoOscuro
                  ? Colors.white
                  : Colors.black,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: Provider.of<TemaProveedor>(context).esModoOscuro
                  ? Colors.white
                  : Colors.black,
            ),
          ),
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
                  Icons.shopping_bag_outlined,
                  size: isMobile ? 24.0 : 28.0,
                  color: Provider.of<TemaProveedor>(context).esModoOscuro
                      ? Colors.white
                      : Colors.black,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    nombre,
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
            _infoRow('Código', widget.docID, infoFontSize),
            _infoRow('Unidad', unidad, infoFontSize),
            _infoRow('Stock', inventario.toString(), infoFontSize),
            _infoRow('Stock mínimo', stockMinimo.toString(), infoFontSize),
            _infoRow('Precio', 'L. $precio', infoFontSize),
            _infoRow('Costo', 'L. $costos', infoFontSize),
            _infoRow('ISV', '$isv %', infoFontSize),
            _infoRow(
              'Precio con ISV',
              'L. ${precioVenta.toStringAsFixed(2)}',
              infoFontSize,
            ),
            _infoRow(
              'Porcentaje de ganancia',
              '${((precio - costos) / costos * 100).toStringAsFixed(2)} %',
              infoFontSize,
            ),
            _infoRow('Categoria', nombreCategoria, infoFontSize),
            _infoRow('Proveedor', nombreProveedor, infoFontSize),
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

  Widget _buildActionButton() {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Center(
      child: ElevatedButton.icon(
        onPressed: () {
          _showAddInventory();
        },
        icon: Icon(
          Icons.add_circle_outline,
          size: isMobile ? 20.0 : 24.0,
          color: Colors.white,
        ),
        label: Text(
          'Agregar inventario',
          style: TextStyle(
            fontSize: isMobile ? 16.0 : 18.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 24.0 : 32.0,
            vertical: isMobile ? 12.0 : 16.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }

  Future<void> _showEditInventory() {
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;
    final bool isDesktop = screenSize.width >= 900;

    // Calculamos el ancho del diálogo según el tamaño de pantalla
    final double dialogWidth = isDesktop
        ? screenSize.width * 0.3
        : (isTablet ? screenSize.width * 0.5 : screenSize.width * 0.8);

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Provider.of<TemaProveedor>(context).esModoOscuro
              ? Color.fromRGBO(60, 60, 60, 1)
              : Color.fromRGBO(220, 220, 220, 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: EdgeInsets.zero,
          contentPadding: EdgeInsets.all(isMobile ? 20.0 : 24.0),
          insetPadding: EdgeInsets.symmetric(
            horizontal: isDesktop ? (screenSize.width - dialogWidth) / 2 : 24.0,
            vertical: 24.0,
          ),
          title: Container(
            padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
            decoration: BoxDecoration(
              color: Provider.of<TemaProveedor>(context).esModoOscuro
                  ? Color.fromRGBO(60, 60, 60, 1)
                  : Color.fromRGBO(220, 220, 220, 1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: isMobile ? 20.0 : 24.0,
                  color: Provider.of<TemaProveedor>(context).esModoOscuro
                      ? Colors.white
                      : Colors.black,
                ),
                SizedBox(width: 8),
                Text(
                  'Editar Inventario',
                  style: TextStyle(
                    color: Provider.of<TemaProveedor>(context).esModoOscuro
                        ? Colors.white
                        : Colors.black,
                    fontSize: isMobile ? 18.0 : 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          content: Container(
            width: dialogWidth,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _inventarioController,
                      decoration: InputDecoration(
                        labelText: 'Cantidad',
                        labelStyle: TextStyle(
                          color:
                              Provider.of<TemaProveedor>(context).esModoOscuro
                              ? Colors.white
                              : Colors.black,
                          fontSize: isMobile ? 14.0 : 16.0,
                        ),
                        hintText: 'Ingrese la cantidad',
                        filled: true,
                        fillColor:
                            Provider.of<TemaProveedor>(context).esModoOscuro
                            ? const Color.fromRGBO(30, 30, 30, 1)
                            : const Color.fromRGBO(244, 243, 243, 1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color:
                                Provider.of<TemaProveedor>(context).esModoOscuro
                                ? Colors.white
                                : Colors.black,
                            width: 2,
                          ),
                        ),
                        prefixIcon: Icon(
                          Icons.inventory_2_outlined,
                          size: isMobile ? 20.0 : 22.0,
                          color:
                              Provider.of<TemaProveedor>(context).esModoOscuro
                              ? Colors.white
                              : Colors.black,
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.redAccent,
                            width: 2.0,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.redAccent,
                            width: 2.0,
                          ),
                        ),
                        errorStyle: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w500,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: isMobile ? 12.0 : 16.0,
                          horizontal: isMobile ? 12.0 : 16.0,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Por favor, ingrese la cantidad';
                        } else if (value.contains('-')) {
                          return 'Por favor, ingrese un número positivo';
                        }
                        return null;
                      },
                      style: TextStyle(fontSize: isMobile ? 14.0 : 16.0),
                    ),
                    SizedBox(height: isMobile ? 12.0 : 16.0),
                    _buildDropdownMetodoPago(
                      value: _metodoPago,
                      items: _metodosPago,
                      label: 'Método de pago',
                      icon: Icons.payment,
                      onChanged: (value) {
                        setState(() {
                          _metodoPago = value!;
                        });
                      },
                    ),
                    SizedBox(height: isMobile ? 12.0 : 16.0),
                    Text(
                      'Por favor, asegúrese de ingresar la cantidad correcta.',
                      style: TextStyle(
                        fontSize: isMobile ? 12.0 : 14.0,
                        color: Provider.of<TemaProveedor>(context).esModoOscuro
                            ? Colors.white
                            : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actionsPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12.0 : 16.0,
            vertical: isMobile ? 8.0 : 12.0,
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16.0 : 24.0,
                      vertical: isMobile ? 8.0 : 12.0,
                    ),
                  ),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 14.0 : 16.0,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16.0 : 24.0,
                      vertical: isMobile ? 8.0 : 12.0,
                    ),
                  ),
                  child: Text(
                    'Confirmar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 14.0 : 16.0,
                    ),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _editInventory();
                    }
                  },
                ),
              ],
            ),
          ],
        );
      },
    ).then((_) {
      _inventarioController.clear();
    });
  }

  Future<void> _showAddInventory() {
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;
    final bool isDesktop = screenSize.width >= 900;

    // Calculamos el ancho del diálogo según el tamaño de pantalla
    final double dialogWidth = isDesktop
        ? screenSize.width * 0.3
        : (isTablet ? screenSize.width * 0.5 : screenSize.width * 0.8);

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Provider.of<TemaProveedor>(context).esModoOscuro
              ? Color.fromRGBO(60, 60, 60, 1)
              : Color.fromRGBO(220, 220, 220, 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: EdgeInsets.zero,
          contentPadding: EdgeInsets.all(isMobile ? 20.0 : 24.0),
          insetPadding: EdgeInsets.symmetric(
            horizontal: isDesktop ? (screenSize.width - dialogWidth) / 2 : 24.0,
            vertical: 24.0,
          ),
          title: Container(
            padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
            decoration: BoxDecoration(
              color: Provider.of<TemaProveedor>(context).esModoOscuro
                  ? Color.fromRGBO(60, 60, 60, 1)
                  : Color.fromRGBO(220, 220, 220, 1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: isMobile ? 20.0 : 24.0,
                  color: Provider.of<TemaProveedor>(context).esModoOscuro
                      ? Colors.white
                      : Colors.black,
                ),
                SizedBox(width: 8),
                Text(
                  'Agregar inventario',
                  style: TextStyle(
                    color: Provider.of<TemaProveedor>(context).esModoOscuro
                        ? Colors.white
                        : Colors.black,
                    fontSize: isMobile ? 18.0 : 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          content: Container(
            width: dialogWidth,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _cantidad,
                      decoration: InputDecoration(
                        labelText: 'Cantidad',
                        labelStyle: TextStyle(
                          color:
                              Provider.of<TemaProveedor>(context).esModoOscuro
                              ? Colors.white
                              : Colors.black,
                          fontSize: isMobile ? 14.0 : 16.0,
                        ),
                        hintText: 'Ingrese la cantidad',
                        filled: true,
                        fillColor:
                            Provider.of<TemaProveedor>(context).esModoOscuro
                            ? const Color.fromRGBO(30, 30, 30, 1)
                            : const Color.fromRGBO(244, 243, 243, 1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color:
                                Provider.of<TemaProveedor>(context).esModoOscuro
                                ? Colors.white
                                : Colors.black,
                            width: 2,
                          ),
                        ),
                        prefixIcon: Icon(
                          Icons.inventory_2_outlined,
                          size: isMobile ? 20.0 : 22.0,
                          color:
                              Provider.of<TemaProveedor>(context).esModoOscuro
                              ? Colors.white
                              : Colors.black,
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.redAccent,
                            width: 2.0,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.redAccent,
                            width: 2.0,
                          ),
                        ),
                        errorStyle: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w500,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: isMobile ? 12.0 : 16.0,
                          horizontal: isMobile ? 12.0 : 16.0,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Por favor, ingrese la cantidad';
                        } else if (value.contains('-')) {
                          return 'Por favor, ingrese un número positivo';
                        }
                        return null;
                      },
                      style: TextStyle(fontSize: isMobile ? 14.0 : 16.0),
                    ),
                    SizedBox(height: isMobile ? 12.0 : 16.0),
                    _buildDropdownMetodoPago(
                      value: _metodoPago,
                      items: _metodosPago,
                      label: 'Método de pago',
                      icon: Icons.payment,
                      onChanged: (value) {
                        setState(() {
                          _metodoPago = value!;
                        });
                      },
                    ),
                    SizedBox(height: isMobile ? 12.0 : 16.0),
                    Text(
                      'Por favor, asegúrese de ingresar la cantidad correcta.',
                      style: TextStyle(
                        fontSize: isMobile ? 12.0 : 14.0,
                        color: Provider.of<TemaProveedor>(context).esModoOscuro
                            ? Colors.white
                            : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actionsPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12.0 : 16.0,
            vertical: isMobile ? 8.0 : 12.0,
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16.0 : 24.0,
                      vertical: isMobile ? 8.0 : 12.0,
                    ),
                  ),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 14.0 : 16.0,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16.0 : 24.0,
                      vertical: isMobile ? 8.0 : 12.0,
                    ),
                  ),
                  child: Text(
                    'Confirmar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 14.0 : 16.0,
                    ),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      addInventory();
                    }
                  },
                ),
              ],
            ),
          ],
        );
      },
    ).then((_) {
      _cantidad.clear();
    });
  }

  Widget _buildDropdownMetodoPago({
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
