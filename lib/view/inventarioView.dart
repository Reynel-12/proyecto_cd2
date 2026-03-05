import 'package:proyecto_cd2/view/inventario_optimo.dart';
import 'package:proyecto_cd2/view/productoForm.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proyecto_cd2/controller/repository_producto.dart';
import 'package:proyecto_cd2/model/app_logger.dart';
import 'package:proyecto_cd2/model/preferences.dart';
import 'package:proyecto_cd2/model/producto.dart';
import 'package:proyecto_cd2/view/barcode_scanner_view.dart';
import 'package:proyecto_cd2/view/perfilProductoView.dart';
import 'package:proyecto_cd2/view/widgets/inventario_vacio.dart';
import 'package:proyecto_cd2/view/widgets/loading.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;

class Inventario extends StatefulWidget {
  const Inventario({super.key});

  @override
  State<Inventario> createState() => _InventarioState();
}

class _InventarioState extends State<Inventario> {
  TextEditingController searchController = TextEditingController();
  final repositoryProducto = ProductoRepository();
  final AppLogger _logger = AppLogger.instance;
  List<Producto> _productos = [];
  List<Producto> _productosFiltrados = [];
  bool isLoading = false;
  String scanResult = '';

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  void cargarDatos() {
    try {
      setState(() {
        isLoading = true;
      });
      repositoryProducto.getProductos().then((productos) {
        setState(() {
          _productos = productos;
          _productosFiltrados = productos;
          isLoading = false;
        });
      });
    } catch (e, stackTrace) {
      _logger.log.e('Error al cargar datos', error: e, stackTrace: stackTrace);
    }
  }

  // Función para eliminar acentos y caracteres especiales
  String _normalizeString(String str) {
    return removeDiacritics(str.trim().toLowerCase());
  }

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

  void _filterProductsByCode(String query) {
    if (query == "-1") {
      // El usuario canceló el escaneo
      //_mostrarMensaje('Atención', 'Escaneo cancelado', SnackbarType.warning);
      return; // No hace nada más si se cancela
    }
    if (query.isEmpty) {
      setState(() {
        _productosFiltrados = _productos; // Si no hay texto, mostrar todos
      });
    } else {
      setState(() {
        _productosFiltrados = _productos
            .where(
              (product) =>
                  product.id.toLowerCase().contains(query.toLowerCase()),
            )
            .toList(); // Filtrar los productos según la búsqueda
      });
      if (_productosFiltrados.isEmpty) {
        setState(() {
          _productosFiltrados = _productos;
        });
        _mostrarMensaje(
          'Atención',
          'Producto con código: $query no encontrado',
          ContentType.warning,
        );
      }
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

    return isLoading
        ? CargandoInventario()
        : Scaffold(
            backgroundColor: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Colors.black
                : const Color.fromRGBO(244, 243, 243, 1),
            appBar: AppBar(
              title: Text(
                'Inventario',
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
                _productosFiltrados.isEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.add,
                          color:
                              Provider.of<TemaProveedor>(context).esModoOscuro
                              ? Colors.white
                              : Colors.black,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => Nuevoproducto()),
                          ).then((value) {
                            if (value == true) {
                              cargarDatos();
                            }
                          });
                        },
                      )
                    : PopupMenuButton(
                        color: Provider.of<TemaProveedor>(context).esModoOscuro
                            ? const Color.fromRGBO(30, 30, 30, 1)
                            : const Color.fromRGBO(244, 243, 243, 1),
                        icon: Icon(
                          Icons.more_vert,
                          color:
                              Provider.of<TemaProveedor>(context).esModoOscuro
                              ? Colors.white
                              : Colors.black,
                          // Tamaño responsivo del icono
                          size: isMobile ? 22.0 : 24.0,
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'agregar_producto',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.add,
                                  color:
                                      Provider.of<TemaProveedor>(
                                        context,
                                        listen: false,
                                      ).esModoOscuro
                                      ? Colors.white
                                      : Colors.black,
                                  // Tamaño responsivo del icono
                                  size: isMobile ? 20.0 : 22.0,
                                ),
                                SizedBox(width: isMobile ? 6.0 : 8.0),
                                Text(
                                  'Agregar producto',
                                  style: TextStyle(
                                    fontSize: isMobile ? 14.0 : 16.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'valor_inventario',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.price_change,
                                  color:
                                      Provider.of<TemaProveedor>(
                                        context,
                                        listen: false,
                                      ).esModoOscuro
                                      ? Colors.white
                                      : Colors.black,
                                  // Tamaño responsivo del icono
                                  size: isMobile ? 20.0 : 22.0,
                                ),
                                SizedBox(width: isMobile ? 6.0 : 8.0),
                                Text(
                                  'Valor del inventario',
                                  style: TextStyle(
                                    fontSize: isMobile ? 14.0 : 16.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'inventario_optimo',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.price_change,
                                  color:
                                      Provider.of<TemaProveedor>(
                                        context,
                                        listen: false,
                                      ).esModoOscuro
                                      ? Colors.white
                                      : Colors.black,
                                  // Tamaño responsivo del icono
                                  size: isMobile ? 20.0 : 22.0,
                                ),
                                SizedBox(width: isMobile ? 6.0 : 8.0),
                                Text(
                                  'Inventario óptimo',
                                  style: TextStyle(
                                    fontSize: isMobile ? 14.0 : 16.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) async {
                          switch (value) {
                            case 'valor_inventario':
                              String total = '0.0';

                              total = _productos
                                  .map<double>((p) => (p.costo * p.stock))
                                  .reduce((a, b) => a + b)
                                  .toStringAsFixed(2);
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    backgroundColor:
                                        Provider.of<TemaProveedor>(
                                          context,
                                        ).esModoOscuro
                                        ? Color.fromRGBO(60, 60, 60, 1)
                                        : Color.fromRGBO(220, 220, 220, 1),
                                    child: Container(
                                      width: isDesktop
                                          ? screenSize.width * 0.3
                                          : (isTablet
                                                ? screenSize.width * 0.6
                                                : screenSize.width * 0.8),
                                      padding: EdgeInsets.all(
                                        isMobile ? 16.0 : 20.0,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.inventory_2_outlined,
                                            size: isMobile ? 50 : 60,
                                            color:
                                                Provider.of<TemaProveedor>(
                                                  context,
                                                ).esModoOscuro
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                          SizedBox(
                                            height: isMobile ? 16.0 : 20.0,
                                          ),
                                          Text(
                                            'Valor total del inventario',
                                            style: TextStyle(
                                              fontSize: isMobile ? 18.0 : 22.0,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  Provider.of<TemaProveedor>(
                                                    context,
                                                  ).esModoOscuro
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                          SizedBox(
                                            height: isMobile ? 12.0 : 16.0,
                                          ),
                                          Text(
                                            'El valor total del inventario es de: $total Lempiras',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: isMobile ? 14.0 : 16.0,
                                              color:
                                                  Provider.of<TemaProveedor>(
                                                    context,
                                                  ).esModoOscuro
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                          SizedBox(
                                            height: isMobile ? 24.0 : 30.0,
                                          ),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.blueAccent,
                                                padding: EdgeInsets.symmetric(
                                                  vertical: isMobile
                                                      ? 12.0
                                                      : 14.0,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(30),
                                                ),
                                              ),
                                              child: Text(
                                                'Aceptar',
                                                style: TextStyle(
                                                  fontSize: isMobile
                                                      ? 14.0
                                                      : 16.0,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                              break;
                            case 'agregar_producto':
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => Nuevoproducto(),
                                ),
                              ).then((value) {
                                if (value == true) {
                                  cargarDatos();
                                }
                              });
                              break;
                            case 'inventario_optimo':
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => InventarioOptimo(),
                                ),
                              ).then((value) {
                                if (value == true) {
                                  cargarDatos();
                                }
                              });
                              break;
                          }
                        },
                      ),
              ],
            ),
            body: _productosFiltrados.isEmpty
                ? InventarioVacio()
                : Padding(
                    padding: EdgeInsets.all(contentPadding),
                    child: Column(
                      children: [
                        // Campo de búsqueda responsivo
                        TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor:
                                Provider.of<TemaProveedor>(context).esModoOscuro
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
                            suffixIcon: IconButton(
                              icon: Icon(
                                Icons.barcode_reader,
                                color:
                                    Provider.of<TemaProveedor>(
                                      context,
                                    ).esModoOscuro
                                    ? Colors.white
                                    : Colors.black,
                                size: isMobile ? 20.0 : 22.0,
                              ),
                              onPressed: () async {
                                if (Platform.isAndroid || Platform.isIOS) {
                                  final scannedCode = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BarcodeScannerView(),
                                    ),
                                  );

                                  if (scannedCode != null) {
                                    setState(() {
                                      scanResult = scannedCode.toString();
                                    });

                                    // ✅ Usar directamente scannedCode en lugar de esperar al rebuild
                                    _filterProductsByCode(scanResult);
                                  }
                                }
                              },
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
                                Provider.of<TemaProveedor>(context).esModoOscuro
                                ? Colors.white
                                : Colors.black,
                          ),
                          onChanged: (value) {
                            _filterProducts(value);
                          },
                        ),
                        SizedBox(height: isMobile ? 12.0 : 16.0),

                        // Lista de productos con diseño responsivo
                        Expanded(
                          child: isDesktop
                              ? _buildGridView(cardElevation)
                              : _buildListView(cardElevation),
                        ),
                      ],
                    ),
                  ),
          );
  }

  // Vista de lista para móvil y tablet
  Widget _buildListView(double elevation) {
    return ListView.builder(
      itemCount: _productosFiltrados.length,
      itemBuilder: (context, index) {
        final producto = _productosFiltrados[index];
        return cardProductos(
          producto.id,
          producto.nombre,
          producto.unidadMedida!,
          producto.stock,
          producto.precioVenta,
          producto.costo,
          producto.proveedorId!,
          producto.estado!,
          producto.categoriaId!,
          elevation,
        );
      },
    );
  }

  // Vista de cuadrícula para escritorio
  Widget _buildGridView(double elevation) {
    // Obtenemos el tamaño de la pantalla
    final screenSize = MediaQuery.of(context).size;
    final bool isDesktop = screenSize.width >= 900 && screenSize.width < 1100;
    final bool isDesktopL = screenSize.width >= 1100;
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 columnas en escritorio
        childAspectRatio: isDesktop
            ? 2.5
            : isDesktopL
            ? 3.2
            : 3.2, // Proporción ancho/alto
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      ),
      itemCount: _productosFiltrados.length,
      itemBuilder: (context, index) {
        final producto = _productosFiltrados[index];
        return cardProductos(
          producto.id,
          producto.nombre,
          producto.unidadMedida!,
          producto.stock,
          producto.precioVenta,
          producto.costo,
          producto.proveedorId!,
          producto.estado!,
          producto.categoriaId!,
          elevation,
        );
      },
    );
  }

  Widget cardProductos(
    String id,
    String nombre,
    String tipo,
    int stock,
    double precio,
    double costos,
    int proveedor,
    String estado,
    int categoria,
    double elevation,
  ) {
    // Obtenemos el tamaño de la pantalla
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;

    // Ajustamos tamaños según el dispositivo
    final double titleFontSize = isMobile ? 16.0 : (isTablet ? 18.0 : 20.0);
    final double subtitleFontSize = isMobile ? 12.0 : (isTablet ? 13.0 : 14.0);
    final double infoFontSize = isMobile ? 14.0 : (isTablet ? 15.0 : 16.0);
    final double iconSize = isMobile ? 24.0 : (isTablet ? 28.0 : 30.0);
    final double avatarRadius = isMobile ? 25.0 : (isTablet ? 28.0 : 30.0);
    final double cardPadding = isMobile ? 16.0 : (isTablet ? 18.0 : 20.0);

    Color stockColor;
    String stockLabel;

    // Establece el color y la etiqueta del stock según la cantidad
    if (stock > 10) {
      stockColor = Colors.green;
      stockLabel = "Stock";
    } else if (stock > 5) {
      stockColor = Colors.amber;
      stockLabel = "Stock";
    } else {
      stockColor = Colors.red;
      stockLabel = "Stock";
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PerfilProducto(
              docID: id,
              idProveedor: proveedor,
              idCategoria: categoria,
            ),
          ),
        ).then((value) {
          if (value == true) {
            cargarDatos();
          }
        });
      },
      child: Card(
        color: Provider.of<TemaProveedor>(context).esModoOscuro
            ? const Color.fromRGBO(30, 30, 30, 1)
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isMobile ? 16.0 : 20.0),
        ),
        elevation: elevation,
        margin: EdgeInsets.symmetric(
          vertical: isMobile ? 8.0 : 10.0,
          horizontal: isMobile ? 12.0 : 16.0,
        ),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isMobile ? 16.0 : 20.0),
          ),
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono o imagen del producto
                CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  radius: avatarRadius,
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    size: iconSize,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: isMobile ? 12.0 : 16.0),
                // Información del producto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                          color:
                              Provider.of<TemaProveedor>(context).esModoOscuro
                              ? Colors.white
                              : Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isMobile ? 2.0 : 4.0),
                      Text(
                        tipo,
                        style: TextStyle(
                          fontSize: subtitleFontSize,
                          color:
                              Provider.of<TemaProveedor>(context).esModoOscuro
                              ? Color.fromRGBO(244, 243, 243, 1)
                              : Color.fromRGBO(30, 30, 30, 1),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isMobile ? 8.0 : 12.0),
                      // Precio
                      Row(
                        children: [
                          Icon(
                            Icons.price_change_outlined,
                            color:
                                Provider.of<TemaProveedor>(context).esModoOscuro
                                ? Colors.white
                                : Colors.black,
                            size: isMobile ? 18.0 : 20.0,
                          ),
                          SizedBox(width: isMobile ? 4.0 : 6.0),
                          Text(
                            'Precio: L. ${precio.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: infoFontSize,
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
                      SizedBox(height: isMobile ? 8.0 : 12.0),
                      // Costo
                      Row(
                        children: [
                          Icon(
                            Icons.price_change_outlined,
                            color:
                                Provider.of<TemaProveedor>(context).esModoOscuro
                                ? Colors.white
                                : Colors.black,
                            size: isMobile ? 18.0 : 20.0,
                          ),
                          SizedBox(width: isMobile ? 4.0 : 6.0),
                          Text(
                            'Costo: L. ${costos.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: infoFontSize,
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
                      SizedBox(height: isMobile ? 8.0 : 12.0),
                      // Inventario
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            color: stockColor,
                            size: isMobile ? 18.0 : 20.0,
                          ),
                          SizedBox(width: isMobile ? 4.0 : 6.0),
                          Text(
                            '$stockLabel: $stock',
                            style: TextStyle(
                              fontSize: infoFontSize,
                              fontWeight: FontWeight.bold,
                              color: stockColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Flecha que indica más detalles
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.blueAccent,
                  size: isMobile ? 16.0 : 20.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
