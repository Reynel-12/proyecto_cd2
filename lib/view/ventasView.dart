import 'package:proyecto_cd2/view/widgets/modal_print_movil.dart';
import 'package:proyecto_cd2/view/widgets/discount_dialog.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import 'package:proyecto_cd2/controller/repository_producto.dart';
import 'package:proyecto_cd2/controller/repository_venta.dart';
import 'package:proyecto_cd2/model/app_logger.dart';
import 'package:proyecto_cd2/model/detalle_venta.dart';
import 'package:proyecto_cd2/model/preferences.dart';
import 'package:proyecto_cd2/model/producto.dart';
import 'package:proyecto_cd2/model/venta.dart';
import 'package:proyecto_cd2/view/MiFAB.dart';
import 'package:proyecto_cd2/view/widgets/inventario_vacio.dart';
import 'package:proyecto_cd2/view/widgets/loading.dart';
import 'package:proyecto_cd2/view/widgets/thermal_invoice_printer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Ventas extends StatefulWidget {
  const Ventas({super.key});

  @override
  State<Ventas> createState() => _VentasState();
}

class _VentasState extends State<Ventas> {
  final TextEditingController _totalController = TextEditingController();
  final TextEditingController _clienteController = TextEditingController();
  final TextEditingController _cambioController = TextEditingController();
  final TextEditingController _rtnController = TextEditingController();
  final TextEditingController _nombreClienteController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final repositoryProducto = ProductoRepository();
  final repositoryVenta = VentaRepository();
  List<Producto> _productos = [];
  List<Producto> _productosSeleccionados = [];
  List<Producto> _productosFiltrados = [];
  bool isLoading = true;
  final AppLogger _logger = AppLogger.instance;
  double _total = 0.0;
  List<String> _metodosPago = ['Efectivo', 'Tarjeta', 'Transferencia'];
  String _metodoPago = 'Efectivo';

  @override
  void initState() {
    super.initState();
    cargarDatos();
    _clienteController.addListener(_totalPagar);
  }

  void cargarDatos() {
    try {
      setState(() {
        isLoading = true;
      });
      _productos.clear();
      _productosFiltrados.clear();
      repositoryProducto.getProductosActivos().then((productos) {
        setState(() {
          _productos = productos;
          _productosFiltrados = productos;
          isLoading = false;
        });
      });
    } catch (e, st) {
      _logger.log.e('Error al cargar datos', error: e, stackTrace: st);
    }
  }

  void actualizarInventario() {
    try {
      _productos.clear();
      _productosFiltrados.clear();
      repositoryProducto.getProductos().then((productos) {
        setState(() {
          _productos = productos;
          _productosFiltrados = productos;
        });
      });
    } catch (e, st) {
      _logger.log.e('Error al actualizar inventario', error: e, stackTrace: st);
    }
  }

  // Helper para verificar si el stock es insuficiente
  bool _isStockInsufficient(Producto producto) {
    // Calcular cuánto stock ya está siendo usado en el carrito
    int cantidadEnCarrito = 0;
    for (var p in _productosSeleccionados) {
      if (p.id == producto.id) {
        cantidadEnCarrito += p.cantidad;
      }
    }

    // Stock disponible = stock total - cantidad ya en carrito
    int stockDisponible = producto.stock - cantidadEnCarrito + 1;

    // Insuficiente si: stock es 0 o menor, O si no hay suficiente stock disponible
    return producto.stock <= 0 || stockDisponible <= 0;
  }

  void handleOnAddNewProduct(Producto value) {
    setState(() {
      _productosSeleccionados.add(value);
    });
  }

  void searchProductByCode(String code) async {
    // Obtenemos el tamaño de la pantalla
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;

    // Ajustamos tamaños según el dispositivo
    final double childIconSize = isMobile ? 24.0 : (isTablet ? 28.0 : 30.0);
    final double dialogWidth = isMobile
        ? screenSize.width * 0.9
        : (isTablet ? screenSize.width * 0.7 : 500.0);
    final double dialogPadding = isMobile ? 12.0 : (isTablet ? 16.0 : 20.0);
    final double titleFontSize = isMobile ? 16.0 : (isTablet ? 18.0 : 20.0);
    final double contentFontSize = isMobile ? 14.0 : (isTablet ? 15.0 : 16.0);

    if (code == "-1") {
      _mostrarMensaje('Atención', 'Escaneo cancelado', ContentType.warning);
      return;
    }

    final productMatches = _productos
        .where((product) => product.id == code)
        .toList();

    if (productMatches.isNotEmpty) {
      // Si hay más de un producto con el mismo código, mostrar un diálogo de selección
      final selectedProduct = productMatches.length >= 1
          ? await showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  backgroundColor:
                      Provider.of<TemaProveedor>(context).esModoOscuro
                      ? Color.fromRGBO(60, 60, 60, 1)
                      : Color.fromRGBO(220, 220, 220, 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  titlePadding: const EdgeInsets.all(0),
                  title: Container(
                    padding: EdgeInsets.all(dialogPadding),
                    decoration: const BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.shopping_cart,
                          color: Colors.white,
                          size: childIconSize,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Seleccione el producto',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  content: Container(
                    width: dialogWidth,
                    height: screenSize.height * 0.6,
                    padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: productMatches.length,
                            itemBuilder: (context, index) {
                              final producto = productMatches[index];
                              return Card(
                                color:
                                    Provider.of<TemaProveedor>(
                                      context,
                                    ).esModoOscuro
                                    ? const Color.fromRGBO(30, 30, 30, 1)
                                    : Colors.white,
                                margin: EdgeInsets.symmetric(
                                  vertical: isMobile ? 6.0 : 8.0,
                                  horizontal: 0,
                                ),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: isMobile ? 6.0 : 8.0,
                                    horizontal: isMobile ? 12.0 : 16.0,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blueAccent,
                                    radius: isMobile ? 20.0 : 24.0,
                                    child: Text(
                                      producto.nombre[0].toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: isMobile ? 14.0 : 16.0,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    producto.nombre,
                                    style: TextStyle(
                                      fontSize: contentFontSize,
                                      fontWeight: FontWeight.w600,
                                      color: _isStockInsufficient(producto)
                                          ? Colors.red
                                          : Provider.of<TemaProveedor>(
                                              context,
                                            ).esModoOscuro
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${producto.unidadMedida}\nPrecio: ${(producto.precioVenta).toStringAsFixed(2)}\nInventario: ${producto.stock.toString()}',
                                    style: TextStyle(
                                      color: _isStockInsufficient(producto)
                                          ? Colors.red
                                          : Provider.of<TemaProveedor>(
                                              context,
                                            ).esModoOscuro
                                          ? Colors.white
                                          : Colors.black,
                                      fontSize: contentFontSize - 2,
                                    ),
                                  ),
                                  trailing: Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.blueAccent,
                                    size: childIconSize * 0.9,
                                  ),
                                  onTap: () {
                                    Navigator.of(context).pop(producto);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          : productMatches.first;

      if (selectedProduct == null) {
        return; // Si el usuario cerró el diálogo, no hacer nada
      }

      setState(() {
        bool existe = false;
        for (var p in _productosSeleccionados) {
          if (p.id == selectedProduct.id) {
            p.cantidad += 1;
            existe = true;
            break;
          }
        }

        if (!existe) {
          selectedProduct.cantidad = 1;
          _productosSeleccionados.add(selectedProduct);
        }
      });

      _mostrarMensaje(
        'Éxito',
        'Producto agregado: ${selectedProduct.nombre}',
        ContentType.success,
      );
    } else {
      _mostrarMensaje(
        'Atención',
        'Producto no encontrado: $code',
        ContentType.warning,
      );
    }
  }

  void _agregarProductoByName(Producto producto) {
    setState(() {
      // Verificar si el producto ya existe en la lista
      bool existe = false;

      for (var p in _productosSeleccionados) {
        if (p.id == producto.id) {
          p.cantidad += 1; // Si existe, suma 1 a la cantidad
          existe = true;
          break;
        }
      }

      if (!existe) {
        // Si no existe, agregar el producto a la lista
        _productosSeleccionados.add(producto);
      }
    });
  }

  void _agregarProductoByCode(Producto producto) {
    setState(() {
      // Verificar si el producto ya existe en la lista
      bool existe = false;

      for (var p in _productosSeleccionados) {
        if (p.id == producto.id) {
          p.cantidad += 1; // Si existe, suma 1 a la cantidad
          existe = true;
          break;
        }
      }

      if (!existe) {
        // Si no existe, agregar el producto a la lista
        _productosSeleccionados.add(producto);
      }
    });
  }

  // Función para eliminar acentos y caracteres especiales
  String _normalizeString(String str) {
    return removeDiacritics(str.trim().toLowerCase());
  }

  // Función mejorada para filtrar productos por nombre u otras propiedades
  void _filterProducts(String query) {
    String normalizedQuery = _normalizeString(query);

    setState(() {
      if (normalizedQuery.isEmpty) {
        _productosFiltrados =
            _productos; // Mostrar todos los productos si no hay búsqueda
      } else {
        // Filtramos primero por código exacto
        var productosPorCodigo = _productos.where((product) {
          String productCode = _normalizeString(product.id);
          return productCode ==
              normalizedQuery; // Coincidencia exacta por código
        }).toList();

        // Si encontramos coincidencias exactas por código, los asignamos directamente
        if (productosPorCodigo.isNotEmpty) {
          _productosFiltrados = productosPorCodigo;
        } else {
          // Si no, filtramos por nombre o coincidencias parciales
          var productosPorNombre = _productos.where((product) {
            String productName = _normalizeString(product.nombre);
            return productName.contains(
              normalizedQuery,
            ); // Coincidencia parcial por nombre
          }).toList();
          if (productosPorNombre.isNotEmpty) {
            _productosFiltrados = productosPorNombre;
          }
        }
      }
    });
  }

  ///Método para calcular el total
  void _totalPagar() {
    double? cliente = double.tryParse(_clienteController.text) ?? 0.0;
    double? total = double.tryParse(_totalController.text) ?? 0.0;
    if (cliente != 0.0 && total != 0.0) {
      // Realizar la multiplicación
      double resultado = cliente - total;

      // Actualizar el TextFormField del resultado
      setState(() {
        _cambioController.text = resultado.toStringAsFixed(2);
      });
    } else {
      // Si el valor es nulo (no es un número válido), limpiar el campo de resultado
      setState(() {
        _cambioController.text = '0.0';
      });
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

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  Future<void> finalizarVenta(String cambio, String cliente) async {
    try {
      final rtn = _rtnController.text.trim();
      final nombre = _nombreClienteController.text.trim();
      double isv = 0.0;
      double subtotal = 0.0;
      double total = 0.0;

      subtotal = _productosSeleccionados.fold(0.0, (sum, item) {
        double descuentoMonto =
            item.precioVenta * (item.descuentoProducto / 100);
        return sum + ((item.precioVenta - descuentoMonto) * item.cantidad);
      });

      // isv = subtotal * SarService.tasaISV;
      total = subtotal + isv;

      final prefs = await SharedPreferences.getInstance();
      String? cajero = prefs.getString('user_fullname');

      final venta = Venta(
        fecha: DateTime.now().toIso8601String(),
        numeroFactura: '1',
        total: total,
        montoPagado: double.parse(cliente),
        cambio: double.parse(cambio),
        estado: 'EMITIDA',
        cai: '',
        rtnCliente: rtn,
        nombreCliente: nombre,
        isv: isv,
        subtotal: subtotal,
        rtnEmisor: '',
        razonSocialEmisor: '',
        rangoAutorizado: '',
        fechaLimiteCai: '',
        cajero: cajero!,
        metodoPago: _metodoPago,
      );
      final detalleVenta = _productosSeleccionados.map((producto) {
        double descuentoUnitario =
            producto.precioVenta * (producto.descuentoProducto / 100);
        double precioFinal = producto.precioVenta - descuentoUnitario;

        return DetalleVenta(
          productoId: producto.id,
          descripcion: '${producto.nombre} - ${producto.unidadMedida}',
          cantidad: producto.cantidad,
          precioUnitario: producto.precioVenta,
          subtotal: precioFinal * producto.cantidad,
          descuento: descuentoUnitario * producto.cantidad,
          isv: producto.isv,
        );
      }).toList();
      int result = await repositoryVenta.registrarVentaConDetalles(
        venta,
        detalleVenta,
      );
      if (result == -2) {
        _mostrarMensaje(
          'Error',
          'Stock insuficiente para el producto ${detalleVenta.first.descripcion}',
          ContentType.warning,
        );
        return;
      }
      // await _sarService.actualizarCorrelativo(); // Actualizar correlativo SAR

      final data = _crearInvoiceData(detalleVenta, venta);

      // Mostrar el modal y esperar la respuesta
      final bool? shouldPrint = await EnhancedConfirmationModalPrintMovil.show(
        context: context,
        title: '¿Deseas generar factura?',
        confirmText: 'Confirmar',
        cancelText: 'Cancelar',
        icon: Icons.print,
        accentColor: Colors.blueAccent,
      );

      // Si el usuario confirmó, navegar a la pantalla de impresión
      if (shouldPrint == true) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ThermalInvoicePreview(data: data, paperWidthMm: 88),
          ),
        );
      }

      actualizarInventario();
      setState(() {
        _productosSeleccionados.clear();
        _totalController.clear();
        _clienteController.clear();
        _rtnController.clear();
        _nombreClienteController.clear();
      });
      _mostrarMensaje(
        'Éxito',
        'Venta registrada con éxito',
        ContentType.success,
      );
    } catch (e, st) {
      _mostrarMensaje(
        'Error',
        'Error al registrar la venta',
        ContentType.failure,
      );
      _logger.log.e('Error al registrar la venta', error: e, stackTrace: st);
    }
  }

  InvoiceData _crearInvoiceData(List<DetalleVenta> productos, Venta venta) {
    DateTime fechaVenta = DateTime.parse(venta.fecha);
    String fecha =
        "${fechaVenta.day.toString().padLeft(2, '0')}/${fechaVenta.month.toString().padLeft(2, '0')}/${fechaVenta.year}";
    String hora =
        "${fechaVenta.hour.toString().padLeft(2, '0')}:${fechaVenta.minute.toString().padLeft(2, '0')}";
    return InvoiceData(
      typeOrder: 'Venta',
      businessRtn: '',
      businessName: '',
      businessAddress: '',
      businessPhone: '',
      businessEmail: '',
      invoiceNumber: venta.numeroFactura,
      date: fecha,
      hora: hora,
      cashier: venta.cajero,
      customerName: venta.nombreCliente ?? '',
      items: productos.map((item) {
        return InvoiceItem(
          description: item.descripcion,
          quantity: item.cantidad,
          unitPrice: item.precioUnitario,
          discount: item.descuento,
          isvPercent: item.isv,
        );
      }).toList(),
      total: venta.total,
      recibido: venta.montoPagado!,
      metodoPago: _metodoPago,
      notes: '¡Gracias por su compra!',
      cai: venta.cai ?? '',
      rangoAutorizado: "",
      fechaLimite: '',
      rtnCliente: venta.rtnCliente ?? '',
      isv: venta.isv,
      subtotal: venta.subtotal,
    );
  }

  void _calcularTotal() {
    _total = _productosSeleccionados.fold(
      0.0,
      (sum, item) =>
          sum +
          (item.precioVenta *
              item.cantidad *
              (1 - item.descuentoProducto / 100)),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _totalController.text = _total.toStringAsFixed(2);
      });
    });
  }

  // void _mostrarMensaje(String titulo, String mensaje, ContentType type) {
  //   final snackBar = SnackBar(
  //     /// need to set following properties for best effect of awesome_snackbar_content
  //     elevation: 0,
  //     behavior: SnackBarBehavior.floating,
  //     backgroundColor: Colors.transparent,
  //     content: AwesomeSnackbarContent(
  //       title: titulo,
  //       message: mensaje,

  //       /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
  //       contentType: type,
  //     ),
  //   );

  //   ScaffoldMessenger.of(context)
  //     ..hideCurrentSnackBar()
  //     ..showSnackBar(snackBar);
  // }

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

    return isLoading
        ? CargandoInventario()
        : Scaffold(
            backgroundColor: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Colors.black
                : const Color.fromRGBO(244, 243, 243, 1),
            appBar: AppBar(
              title: Text(
                'Ventas',
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
                ? _buildDesktopLayout(contentPadding)
                : _buildMobileTabletLayout(contentPadding),
            floatingActionButton: Platform.isAndroid || Platform.isIOS
                ? MiFAB(
                    onScan: searchProductByCode,
                    productsList: _productos,
                    onProductoSeleccionadoByNombre: _agregarProductoByName,
                    onProductoSeleccionadoByCodigo: _agregarProductoByCode,
                    addNewProduct: handleOnAddNewProduct,
                  )
                : null,
          );
  }

  // Layout para móvil y tablet (diseño vertical)
  Widget _buildMobileTabletLayout(double padding) {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Lista de productos
              Expanded(
                child: ListView.builder(
                  itemCount: _productosSeleccionados.length,
                  itemBuilder: (context, index) {
                    final producto = _productosSeleccionados[index];
                    return cardProductos(producto);
                  },
                ),
              ),
              SizedBox(height: padding),
              // Resumen de venta
              _buildSalesSummary(),
              SizedBox(height: padding),
              // Botón para confirmar venta
              _buildFinishSaleButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(double padding) {
    double screenHeight = MediaQuery.of(
      context,
    ).size.height; // Altura de pantalla

    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final bool isTablet =
        MediaQuery.of(context).size.width >= 600 &&
        MediaQuery.of(context).size.width < 900;

    // Ajustamos tamaños según el dispositivo
    final double contentFontSize = isMobile ? 14.0 : (isTablet ? 15.0 : 16.0);
    final double childIconSize = isMobile ? 20.0 : (isTablet ? 22.0 : 24.0);

    return Padding(
      padding: EdgeInsets.all(padding),
      child: SizedBox(
        height: screenHeight, // Ajustamos todo a la pantalla
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //  Sección izquierda: Productos en carrito
            Expanded(
              flex: 3,
              child: Card(
                color: Provider.of<TemaProveedor>(context).esModoOscuro
                    ? const Color.fromRGBO(30, 30, 30, 1)
                    : Colors.white.withOpacity(0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //  Título y botón refrescar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Productos en carrito',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
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
                      SizedBox(height: padding),

                      //  Lista de productos con altura limitada
                      Expanded(
                        child: ListView.builder(
                          itemCount: _productosSeleccionados.length,
                          itemBuilder: (context, index) {
                            final producto = _productosSeleccionados[index];
                            return cardProductos(producto);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(width: padding),

            //  Sección derecha: Buscar productos y Resumen de Venta
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  //  Tarjeta de búsqueda de productos
                  Expanded(
                    flex: 2,
                    child: _productosFiltrados.isEmpty
                        ? InventarioVacio()
                        : Card(
                            color:
                                Provider.of<TemaProveedor>(context).esModoOscuro
                                ? const Color.fromRGBO(30, 30, 30, 1)
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            child: Padding(
                              padding: EdgeInsets.all(padding),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Buscar productos',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Provider.of<TemaProveedor>(
                                            context,
                                          ).esModoOscuro
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: padding),

                                  //  Campo de búsqueda
                                  TextField(
                                    //controller: searchController,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor:
                                          Provider.of<TemaProveedor>(
                                            context,
                                          ).esModoOscuro
                                          ? const Color.fromRGBO(30, 30, 30, 1)
                                          : Colors.white,
                                      labelText: 'Buscar producto',
                                      labelStyle: TextStyle(
                                        color:
                                            Provider.of<TemaProveedor>(
                                              context,
                                            ).esModoOscuro
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: isMobile ? 14.0 : 16.0,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search,
                                        color:
                                            Provider.of<TemaProveedor>(
                                              context,
                                            ).esModoOscuro
                                            ? Colors.white
                                            : Colors.black,
                                        size: isMobile ? 20.0 : 22.0,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          isMobile ? 10 : 12,
                                        ),
                                        borderSide: BorderSide(
                                          color:
                                              Provider.of<TemaProveedor>(
                                                context,
                                              ).esModoOscuro
                                              ? Colors.white
                                              : Colors.black,
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          isMobile ? 10 : 12,
                                        ),
                                        borderSide: BorderSide(
                                          color:
                                              Provider.of<TemaProveedor>(
                                                context,
                                              ).esModoOscuro
                                              ? Colors.white
                                              : Colors.black,
                                          width: 2.0,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          isMobile ? 10 : 12,
                                        ),
                                        borderSide: BorderSide(
                                          color:
                                              Provider.of<TemaProveedor>(
                                                context,
                                              ).esModoOscuro
                                              ? Colors.white
                                              : Colors.black,
                                          width: 1.0,
                                        ),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: isMobile ? 12.0 : 16.0,
                                        horizontal: isMobile ? 12.0 : 16.0,
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontSize: isMobile ? 14.0 : 16.0,
                                      color:
                                          Provider.of<TemaProveedor>(
                                            context,
                                          ).esModoOscuro
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                    onChanged: (value) {
                                      _filterProducts(value);
                                    },
                                  ),
                                  SizedBox(height: padding),

                                  //  Lista de productos con altura limitada
                                  Flexible(
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: _productosFiltrados.length,
                                      itemBuilder: (context, index) {
                                        final producto =
                                            _productosFiltrados[index];
                                        return Card(
                                          color:
                                              Provider.of<TemaProveedor>(
                                                context,
                                              ).esModoOscuro
                                              ? Colors.black
                                              : const Color.fromRGBO(
                                                  244,
                                                  243,
                                                  243,
                                                  1,
                                                ),
                                          margin: EdgeInsets.symmetric(
                                            vertical: isMobile ? 6.0 : 8.0,
                                            horizontal: 0,
                                          ),
                                          elevation: 3,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: ListTile(
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  vertical: isMobile
                                                      ? 6.0
                                                      : 8.0,
                                                  horizontal: isMobile
                                                      ? 12.0
                                                      : 16.0,
                                                ),
                                            leading: CircleAvatar(
                                              backgroundColor:
                                                  Colors.blueAccent,
                                              radius: isMobile ? 20.0 : 24.0,
                                              child: Text(
                                                producto.nombre.substring(0, 1),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: isMobile
                                                      ? 14.0
                                                      : 16.0,
                                                ),
                                              ),
                                            ),
                                            title: Text(
                                              producto.nombre,
                                              style: TextStyle(
                                                fontSize: contentFontSize,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    _isStockInsufficient(
                                                      producto,
                                                    )
                                                    ? Colors.red
                                                    : Provider.of<
                                                            TemaProveedor
                                                          >(context)
                                                          .esModoOscuro
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                            subtitle: Text(
                                              'Inventario: ${producto.stock}',
                                              style: TextStyle(
                                                color:
                                                    _isStockInsufficient(
                                                      producto,
                                                    )
                                                    ? Colors.red
                                                    : Provider.of<
                                                            TemaProveedor
                                                          >(context)
                                                          .esModoOscuro
                                                    ? Colors.white
                                                    : Colors.black,
                                                fontSize: contentFontSize - 2,
                                              ),
                                            ),
                                            trailing: Icon(
                                              Icons.add_circle_outline,
                                              color: Colors.blueAccent,
                                              size: childIconSize * 0.9,
                                            ),
                                            onTap: () {
                                              setState(() {
                                                var existingIndex =
                                                    _productosSeleccionados
                                                        .indexWhere(
                                                          (p) =>
                                                              p.id ==
                                                              producto.id,
                                                        );
                                                if (existingIndex != -1) {
                                                  _productosSeleccionados[existingIndex]
                                                      .cantidad++;
                                                } else {
                                                  producto.cantidad = 1;
                                                  _productosSeleccionados.add(
                                                    producto,
                                                  );
                                                }
                                              });
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),

                  SizedBox(height: padding),

                  //  Tarjeta de resumen de venta
                  Card(
                    color: Provider.of<TemaProveedor>(context).esModoOscuro
                        ? const Color.fromRGBO(30, 30, 30, 1)
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(padding),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Resumen de venta',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color:
                                    Provider.of<TemaProveedor>(
                                      context,
                                    ).esModoOscuro
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                            SizedBox(height: padding),
                            resumenVenta(
                              'Total productos:',
                              _productosSeleccionados.length.toString(),
                            ),
                            SizedBox(height: 8),
                            resumenVenta(
                              'Subtotal:',
                              _productosSeleccionados.isNotEmpty
                                  ? _productosSeleccionados
                                        .map<double>(
                                          (p) => p.precioVenta * p.cantidad,
                                        )
                                        .reduce((a, b) => a + b)
                                        .toStringAsFixed(2)
                                  : '0.00',
                            ),
                            resumenVenta(
                              'Descuento:',
                              _productosSeleccionados.isNotEmpty
                                  ? _productosSeleccionados
                                        .map<double>(
                                          (p) =>
                                              (p.precioVenta * p.cantidad) *
                                              (p.descuentoProducto / 100),
                                        )
                                        .reduce((a, b) => a + b)
                                        .toStringAsFixed(2)
                                  : '0.00',
                            ),
                            // resumenVenta(
                            //   'ISV:',
                            //   _productosSeleccionados.isNotEmpty
                            //       ? _productosSeleccionados
                            //             .map<double>(
                            //               (p) =>
                            //                   p.precioVenta *
                            //                   p.cantidad *
                            //                   SarService.tasaISV,
                            //             )
                            //             .reduce((a, b) => a + b)
                            //             .toStringAsFixed(2)
                            //       : '0.00',
                            // ),
                            resumenVenta(
                              'Total a pagar:',
                              _productosSeleccionados.isNotEmpty
                                  ? _productosSeleccionados
                                        .map<double>(
                                          (p) =>
                                              (p.precioVenta * p.cantidad) *
                                              (1 - (p.descuentoProducto / 100)),
                                        )
                                        .reduce((a, b) => a + b)
                                        .toStringAsFixed(2)
                                  : '0.00',
                            ),
                            SizedBox(height: 8),
                            Divider(
                              color:
                                  Provider.of<TemaProveedor>(
                                    context,
                                  ).esModoOscuro
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.black.withOpacity(0.2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: padding),

                  //  Botón de confirmar venta
                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: _buildFinishSaleButton(isDesktop: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Resumen de venta
  Widget _buildSalesSummary() {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      decoration: BoxDecoration(
        color: Provider.of<TemaProveedor>(context).esModoOscuro
            ? const Color.fromRGBO(30, 30, 30, 1)
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          resumenVenta(
            'Total Productos:',
            _productosSeleccionados.length.toString(),
          ),
          SizedBox(height: 8),
          resumenVenta(
            'Subtotal:',
            _productosSeleccionados.isNotEmpty
                ? _productosSeleccionados
                      .map<double>((p) => p.precioVenta * p.cantidad)
                      .reduce((a, b) => a + b)
                      .toStringAsFixed(2)
                : '0.00',
          ),
          // resumenVenta(
          //   'ISV:',
          //   _productosSeleccionados.isNotEmpty
          //       ? _productosSeleccionados
          //             .map<double>(
          //               (p) => p.precioVenta * p.cantidad * SarService.tasaISV,
          //             )
          //             .reduce((a, b) => a + b)
          //             .toStringAsFixed(2)
          //       : '0.00',
          // ),
          resumenVenta(
            'Total a Pagar:',
            _productosSeleccionados.isNotEmpty
                ? _productosSeleccionados
                      .map<double>(
                        (p) =>
                            // (p.precioVenta * p.cantidad * SarService.tasaISV) +
                            (p.precioVenta * p.cantidad),
                      )
                      .reduce((a, b) => a + b)
                      .toStringAsFixed(2)
                : '0.00',
          ),
        ],
      ),
    );
  }

  // Botón para finalizar venta
  Widget _buildFinishSaleButton({bool isDesktop = false}) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    _calcularTotal();
    return isDesktop
        ? SizedBox(
            height: 50,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _productosSeleccionados.isEmpty
                    ? _mostrarMensaje(
                        'Atención',
                        'Debe seleccionar al menos un producto',
                        ContentType.warning,
                      )
                    : showDialogVenta();
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: isMobile ? 14.0 : 16.0),
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
                ),
              ),
              icon: Icon(
                Icons.check_circle,
                color: Colors.white,
                size: isMobile ? 20.0 : 24.0,
              ),
              label: Text(
                'Finalizar venta',
                style: TextStyle(
                  fontSize: isMobile ? 16.0 : 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          )
        : SizedBox(
            height: 60,
            child: ElevatedButton.icon(
              onPressed: () async {
                if (Platform.isAndroid || Platform.isIOS) {
                  _productosSeleccionados.isEmpty
                      ? _mostrarMensaje(
                          'Atención',
                          'Debe seleccionar al menos un producto',
                          ContentType.warning,
                        )
                      : showDialogVenta();
                } else {
                  _productosSeleccionados.isEmpty
                      ? _mostrarMensaje(
                          'Atención',
                          'Debe seleccionar al menos un producto',
                          ContentType.warning,
                        )
                      : await finalizarVenta(
                          _cambioController.text,
                          _clienteController.text,
                        );
                  _clienteController.clear();
                  _cambioController.clear();
                }
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: isMobile ? 14.0 : 16.0),
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
                ),
              ),
              icon: Icon(
                Icons.check_circle,
                color: Colors.white,
                size: isMobile ? 20.0 : 24.0,
              ),
              label: Text(
                'Finalizar venta',
                style: TextStyle(
                  fontSize: isMobile ? 16.0 : 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          );
  }

  // Widget para el resumen de venta
  Widget resumenVenta(String label, String value) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final double fontSize = isMobile ? 14.0 : 16.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
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
    );
  }

  // Tarjeta de producto con opción de aplicar y quitar descuento
  Widget cardProductos(Producto producto) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final bool isTablet =
        MediaQuery.of(context).size.width >= 600 &&
        MediaQuery.of(context).size.width < 900;

    // Ajustamos tamaños según el dispositivo
    final double titleFontSize = isMobile ? 16.0 : (isTablet ? 17.0 : 18.0);
    final double subtitleFontSize = isMobile ? 12.0 : (isTablet ? 13.0 : 14.0);
    final double priceFontSize = isMobile ? 14.0 : (isTablet ? 15.0 : 16.0);
    final double iconSize = isMobile ? 22.0 : (isTablet ? 24.0 : 26.0);
    final double cardPadding = isMobile ? 12.0 : 16.0;

    // Obtenemos el tamaño de la pantalla
    final screenSize = MediaQuery.of(context).size;
    final bool isDesktop = screenSize.width >= 900;

    // Calculamos el ancho del awesomeDialog según el tamaño de pantalla
    final double dialogWidth = isDesktop
        ? screenSize.width * 0.3
        : (isTablet ? screenSize.width * 0.5 : screenSize.width * 0.8);

    return Card(
      color: Provider.of<TemaProveedor>(context).esModoOscuro
          ? const Color.fromRGBO(30, 30, 30, 1)
          : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: _isStockInsufficient(producto)
                          ? Colors.red
                          : Provider.of<TemaProveedor>(context).esModoOscuro
                          ? Colors.white
                          : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    producto.unidadMedida ?? '',
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      color: _isStockInsufficient(producto)
                          ? Colors.red
                          : Provider.of<TemaProveedor>(context).esModoOscuro
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  // ISV
                  Text(
                    'ISV: ${(producto.isv).toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: priceFontSize,
                      color: _isStockInsufficient(producto)
                          ? Colors.red
                          : Provider.of<TemaProveedor>(context).esModoOscuro
                          ? const Color.fromRGBO(220, 220, 220, 1)
                          : const Color.fromRGBO(60, 60, 60, 1),
                    ),
                  ),
                  SizedBox(height: 8),
                  // Precio y descuento si aplica
                  if (producto.descuentoProducto > 0) ...[
                    Text(
                      'Precio: L. ${(producto.precioVenta).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: priceFontSize - 2,
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      'Desc: ${producto.descuentoProducto.toStringAsFixed(0)}% -> L. ${(producto.precioVenta * (1 - producto.descuentoProducto / 100)).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: priceFontSize,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ] else
                    Text(
                      'Precio: L. ${producto.precioVenta.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: priceFontSize,
                        color: _isStockInsufficient(producto)
                            ? Colors.red
                            : Provider.of<TemaProveedor>(context).esModoOscuro
                            ? const Color.fromRGBO(220, 220, 220, 1)
                            : const Color.fromRGBO(60, 60, 60, 1),
                      ),
                    ),
                  SizedBox(height: 8),
                  Text(
                    'SubTotal: L. ${(producto.cantidad * (producto.precioVenta * (1 - producto.descuentoProducto / 100))).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: priceFontSize,
                      color: _isStockInsufficient(producto)
                          ? Colors.red
                          : Provider.of<TemaProveedor>(context).esModoOscuro
                          ? const Color.fromRGBO(220, 220, 220, 1)
                          : const Color.fromRGBO(60, 60, 60, 1),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.add_circle,
                    color: Colors.green,
                    size: iconSize,
                  ),
                  onPressed: () {
                    setState(() {
                      producto.cantidad++;
                    });
                  },
                ),
                Text(
                  producto.cantidad.toString(),
                  style: TextStyle(
                    fontSize: priceFontSize,
                    fontWeight: FontWeight.bold,
                    color: Provider.of<TemaProveedor>(context).esModoOscuro
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.remove_circle,
                    color: Colors.redAccent,
                    size: iconSize,
                  ),
                  onPressed: () {
                    setState(() {
                      if (producto.cantidad > 1) {
                        producto.cantidad--;
                      }
                    });
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.local_offer,
                    color: producto.descuentoProducto > 0
                        ? Colors.orange
                        : Colors.grey,
                    size: iconSize,
                  ),
                  onPressed: () async {
                    final result = await showDialog<double>(
                      context: context,
                      builder: (context) => DescuentoProductoDialog(
                        precioOriginal: producto.precioVenta,
                        descuentoActual: producto.descuentoProducto,
                      ),
                    );

                    if (result != null) {
                      setState(() {
                        producto.descuentoProducto = result;
                      });
                    }
                  },
                ),
              ],
            ),
            SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.redAccent, size: iconSize),
              onPressed: () {
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
                  animType: AnimType.scale,
                  dialogType: DialogType.warning,
                  title: 'Atención',
                  desc:
                      '¿Está seguro que desea quitar este producto?\n\nEsta acción no se puede deshacer',
                  btnCancelText: 'Cancelar',
                  btnOkOnPress: () {
                    setState(() {
                      _productosSeleccionados.remove(producto);
                    });
                    _mostrarMensaje(
                      'Exito',
                      'Se removio correctamente el producto',
                      ContentType.success,
                    );
                  },
                  btnCancelOnPress: () {},
                ).show();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future showDialogVenta() {
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;
    final bool isDesktop = screenSize.width >= 900;

    // Calculamos el ancho del diálogo según el tamaño de pantalla
    final double dialogWidth = isDesktop
        ? screenSize.width * 0.4
        : (isTablet ? screenSize.width * 0.6 : screenSize.width * 0.9);

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Provider.of<TemaProveedor>(context).esModoOscuro
              ? Color.fromRGBO(60, 60, 60, 1)
              : Color.fromRGBO(220, 220, 220, 1),
          insetPadding: EdgeInsets.symmetric(
            horizontal: isDesktop ? (screenSize.width - dialogWidth) / 2 : 24.0,
            vertical: 24.0,
          ),
          child: Container(
            width: dialogWidth,
            padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Título con estilo más moderno
                  Text(
                    'Finalizar venta',
                    style: TextStyle(
                      fontSize: isMobile ? 20.0 : 22.0,
                      fontWeight: FontWeight.bold,
                      backgroundColor:
                          Provider.of<TemaProveedor>(context).esModoOscuro
                          ? Color.fromRGBO(60, 60, 60, 1)
                          : Color.fromRGBO(220, 220, 220, 1),
                      color: Provider.of<TemaProveedor>(context).esModoOscuro
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                  SizedBox(height: isMobile ? 16.0 : 24.0),

                  // Formulario
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildDropdownEstado(
                          value: _metodoPago,
                          items: _metodosPago,
                          label: 'Método de pago',
                          icon: Icons.payment,
                          onChanged: (value) {
                            setState(() {
                              _metodoPago = value!;
                              if (_metodoPago != 'Efectivo') {
                                _clienteController.text = _totalController.text;
                              } else {
                                _clienteController.clear();
                                _cambioController.text = '0.0';
                              }
                            });
                          },
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Por favor, seleccione un método de pago';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: isMobile ? 12.0 : 16.0),
                        // Campo Total
                        _buildDialogTextField(
                          _totalController,
                          'Total',
                          Icons.monetization_on_outlined,
                          isNumber: true,
                          readOnly: true,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Por favor, ingrese el total';
                            } else if (double.parse(value) <= 0) {
                              return 'Por favor, ingrese un número positivo';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: isMobile ? 12.0 : 16.0),

                        // Campo Nombre Cliente
                        _buildDialogTextField(
                          _nombreClienteController,
                          'Nombre Cliente (Opcional)',
                          Icons.person,
                        ),
                        SizedBox(height: isMobile ? 12.0 : 16.0),

                        // Campo RTN
                        _buildDialogTextField(
                          _rtnController,
                          'RTN (Opcional)',
                          Icons.badge,
                          isNumber: true,
                          isRTN: true,
                        ),
                        SizedBox(height: isMobile ? 12.0 : 16.0),

                        // Campo Recibido
                        _buildDialogTextField(
                          _clienteController,
                          'Recibido',
                          Icons.person_outline,
                          isNumber: true,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Por favor, ingrese el dinero recibido';
                            } else if (double.parse(value) <= 0) {
                              return 'Por favor, ingrese un número positivo';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: isMobile ? 12.0 : 16.0),

                        // Campo Cambio
                        _buildDialogTextField(
                          _cambioController,
                          'Cambio',
                          Icons.money_off_csred_outlined,
                          readOnly: true,
                          isNumber: true,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Por favor, ingrese el cambio';
                            } else if (double.parse(value) < 0) {
                              return 'Por favor, ingrese un número positivo';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: isMobile ? 16.0 : 20.0),

                        // Texto de advertencia
                        Text(
                          'Por favor, asegúrese de ingresar correctamente los datos.',
                          style: TextStyle(
                            fontSize: isMobile ? 12.0 : 14.0,
                            color:
                                Provider.of<TemaProveedor>(context).esModoOscuro
                                ? Colors.white
                                : Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isMobile ? 20.0 : 24.0),

                  // Botones de acción
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Botón Cancelar
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 16.0 : 24.0,
                            vertical: isMobile ? 10.0 : 12.0,
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
                          _clienteController.clear();
                          _clienteController.clear();
                          _rtnController.clear();
                          _nombreClienteController.clear();
                          Navigator.of(context).pop();
                        },
                      ),

                      // Botón Confirmar
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 16.0 : 24.0,
                            vertical: isMobile ? 10.0 : 12.0,
                          ),
                        ),
                        child: Text(
                          'Confirmar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 14.0 : 16.0,
                          ),
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            Navigator.of(context).pop();
                            await finalizarVenta(
                              _cambioController.text,
                              _clienteController.text,
                            );
                            _clienteController.clear();
                            _cambioController.clear();
                            _rtnController.clear();
                            _nombreClienteController.clear();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
      _clienteController.clear();
      _cambioController.clear();
      _rtnController.clear();
      _nombreClienteController.clear();
    });
  }

  // Campo de texto para el diálogo
  Widget _buildDialogTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool readOnly = false,
    bool isNumber = false,
    bool isRTN = false,
    String? Function(String?)? validator,
  }) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return TextFormField(
      readOnly: readOnly,
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Provider.of<TemaProveedor>(context).esModoOscuro
              ? Colors.white
              : Colors.black,
          fontSize: isMobile ? 14.0 : 16.0,
        ),
        filled: true,
        fillColor: Provider.of<TemaProveedor>(context).esModoOscuro
            ? const Color.fromRGBO(30, 30, 30, 1)
            : const Color.fromRGBO(244, 243, 243, 1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Colors.white
                : Colors.black,
            width: 2,
          ),
        ),
        prefixIcon: Icon(
          icon,
          color: Provider.of<TemaProveedor>(context).esModoOscuro
              ? Colors.white
              : Colors.black,
          size: isMobile ? 20.0 : 22.0,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2.0),
        ),
        errorStyle: TextStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.w500,
          fontSize: isMobile ? 12.0 : 13.0,
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: isMobile ? 12.0 : 15.0,
          horizontal: isMobile ? 8.0 : 10.0,
        ),
      ),
      keyboardType: isNumber
          ? TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: isNumber
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))]
          : isRTN
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      style: TextStyle(
        fontSize: isMobile ? 14.0 : 16.0,
        color: Provider.of<TemaProveedor>(context).esModoOscuro
            ? Colors.white
            : Colors.black,
      ),
      validator: validator,
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
