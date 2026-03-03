import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:proyecto_cd2/model/preferences.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import 'package:proyecto_cd2/model/producto.dart';
import 'package:proyecto_cd2/view/barcode_scanner_view.dart';
import 'package:proyecto_cd2/view/widgets/inventario_vacio.dart';

// ignore: must_be_immutable
class MiFAB extends StatefulWidget {
  final Function(String) onScan;
  List<Producto> productsList = [];
  Function(Producto) onProductoSeleccionadoByNombre;
  Function(Producto) onProductoSeleccionadoByCodigo;
  Function(Producto) addNewProduct;
  MiFAB({
    super.key,
    required this.onScan,
    required this.productsList,
    required this.onProductoSeleccionadoByNombre,
    required this.onProductoSeleccionadoByCodigo,
    required this.addNewProduct,
  });

  @override
  State<MiFAB> createState() => _MiFABState();
}

class _MiFABState extends State<MiFAB> {
  TextEditingController searchController = TextEditingController();
  final TextEditingController _nombre = TextEditingController();
  final TextEditingController _unidad = TextEditingController();
  final TextEditingController _precio = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  List<Producto> filteredProducts = [];
  List<Producto> foundProduct = [];
  List<Producto> newProduct = [];
  String scanResult = "";

  @override
  void initState() {
    super.initState();
    filteredProducts = widget.productsList;
  }

  @override
  void dispose() {
    searchController.dispose(); // Limpiar el controlador al cerrar el widget
    _nombre.dispose();
    _unidad.dispose();
    _precio.dispose();
    super.dispose();
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
        filteredProducts =
            widget.productsList; // Mostrar todos si no hay búsqueda
      } else {
        // Si no, filtramos por nombre o coincidencias parciales
        var productosPorNombre = widget.productsList.where((product) {
          String productName = _normalizeString(product.nombre);
          return productName.contains(
            normalizedQuery,
          ); // Coincidencia parcial por nombre
        }).toList();
        if (productosPorNombre.isNotEmpty) {
          filteredProducts = productosPorNombre;
        }
      }
    });
  }

  void _filterProductsByCode(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredProducts =
            widget.productsList; // Si no hay texto, mostrar todos
      });
    } else {
      setState(() {
        filteredProducts = widget.productsList
            .where(
              (product) =>
                  product.id.toLowerCase().contains(query.toLowerCase()),
            )
            .toList(); // Filtrar los productos según la búsqueda
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el tamaño de la pantalla
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;

    // Ajustamos tamaños según el dispositivo
    final double mainButtonSize = isMobile ? 56.0 : (isTablet ? 60.0 : 64.0);
    final double childIconSize = isMobile ? 24.0 : (isTablet ? 28.0 : 30.0);
    final double labelFontSize = isMobile ? 14.0 : (isTablet ? 16.0 : 18.0);
    final double dialogWidth = isMobile
        ? screenSize.width * 0.9
        : (isTablet ? screenSize.width * 0.7 : 500.0);
    final double dialogPadding = isMobile ? 12.0 : (isTablet ? 16.0 : 20.0);
    final double titleFontSize = isMobile ? 16.0 : (isTablet ? 18.0 : 20.0);
    final double contentFontSize = isMobile ? 14.0 : (isTablet ? 15.0 : 16.0);

    return SpeedDial(
      icon: Icons.add_shopping_cart,
      activeIcon: Icons.close,
      buttonSize: Size(mainButtonSize, mainButtonSize),
      backgroundColor: Colors.blueAccent,
      foregroundColor: Colors.white,
      overlayColor: Provider.of<TemaProveedor>(context).esModoOscuro
          ? Color.fromRGBO(60, 60, 60, 1)
          : Color.fromRGBO(220, 220, 220, 1),
      overlayOpacity: 0.5,
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(mainButtonSize / 3),
      ),
      spacing: isMobile ? 10 : 12,
      spaceBetweenChildren: isMobile ? 12 : 16,
      children: [
        Platform.isAndroid || Platform.isIOS
            ? SpeedDialChild(
                child: Icon(
                  Icons.qr_code_scanner,
                  size: childIconSize,
                  color: Colors.white,
                ),
                backgroundColor: Colors.greenAccent,
                label: 'Escanear código',
                labelStyle: TextStyle(
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.bold,
                  color: Provider.of<TemaProveedor>(context).esModoOscuro
                      ? Colors.white
                      : Colors.black,
                ),
                labelBackgroundColor:
                    Provider.of<TemaProveedor>(context).esModoOscuro
                    ? Color.fromRGBO(60, 60, 60, 1)
                    : Color.fromRGBO(220, 220, 220, 1),
                onTap: () async {
                  final scannedCode = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BarcodeScannerView()),
                  );

                  if (scannedCode != null) {
                    setState(() {
                      scanResult = scannedCode.toString();
                    });

                    // ✅ Usar directamente scannedCode en lugar de esperar al rebuild
                    widget.onScan(scanResult);
                  }
                },
              )
            : SpeedDialChild(),
        Platform.isAndroid || Platform.isIOS
            ? SpeedDialChild(
                child: Icon(
                  Icons.keyboard,
                  size: childIconSize,
                  color: Colors.white,
                ),
                backgroundColor: Colors.orangeAccent,
                label: 'Escribir código',
                labelStyle: TextStyle(
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.bold,
                  color: Provider.of<TemaProveedor>(context).esModoOscuro
                      ? Colors.white
                      : Colors.black,
                ),
                labelBackgroundColor:
                    Provider.of<TemaProveedor>(context).esModoOscuro
                    ? Color.fromRGBO(60, 60, 60, 1)
                    : Color.fromRGBO(220, 220, 220, 1),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return StatefulBuilder(
                        builder: (context, setState) {
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
                                color: Colors.teal,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.qr_code_scanner,
                                    color: Colors.white,
                                    size: childIconSize,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Buscar por código',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: titleFontSize,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            content: widget.productsList.isEmpty
                                ? InventarioVacio()
                                : Container(
                                    width: dialogWidth,
                                    height: screenSize.height * 0.6,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Campo de búsqueda estilizado
                                        TextField(
                                          controller: searchController,
                                          decoration: InputDecoration(
                                            hintText:
                                                'Ingrese el código del producto',
                                            hintStyle: TextStyle(
                                              fontSize: contentFontSize,
                                            ),
                                            labelStyle: TextStyle(
                                              color:
                                                  Provider.of<TemaProveedor>(
                                                    context,
                                                  ).esModoOscuro
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: contentFontSize,
                                            ),
                                            prefixIcon: Icon(
                                              Icons.search,
                                              color:
                                                  Provider.of<TemaProveedor>(
                                                    context,
                                                  ).esModoOscuro
                                                  ? Colors.white
                                                  : Colors.black,
                                              size: childIconSize * 0.8,
                                            ),
                                            filled: true,
                                            fillColor:
                                                Provider.of<TemaProveedor>(
                                                  context,
                                                ).esModoOscuro
                                                ? const Color.fromRGBO(
                                                    30,
                                                    30,
                                                    30,
                                                    1,
                                                  )
                                                : const Color.fromRGBO(
                                                    244,
                                                    243,
                                                    243,
                                                    1,
                                                  ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
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
                                              borderRadius:
                                                  BorderRadius.circular(12),
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
                                              borderRadius:
                                                  BorderRadius.circular(12),
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
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  vertical: isMobile
                                                      ? 12.0
                                                      : 16.0,
                                                  horizontal: isMobile
                                                      ? 12.0
                                                      : 16.0,
                                                ),
                                          ),
                                          style: TextStyle(
                                            fontSize: contentFontSize,
                                            color:
                                                Provider.of<TemaProveedor>(
                                                  context,
                                                ).esModoOscuro
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              _filterProductsByCode(
                                                value,
                                              ); // Actualizar productos filtrados
                                            });
                                          },
                                        ),
                                        const SizedBox(height: 16),

                                        // Lista de productos con un diseño moderno
                                        Expanded(
                                          child: ListView.builder(
                                            itemCount: filteredProducts.length,
                                            itemBuilder: (context, index) {
                                              final producto =
                                                  filteredProducts[index];
                                              return Card(
                                                color:
                                                    Provider.of<TemaProveedor>(
                                                      context,
                                                    ).esModoOscuro
                                                    ? const Color.fromRGBO(
                                                        30,
                                                        30,
                                                        30,
                                                        1,
                                                      )
                                                    : Colors.white,
                                                margin: EdgeInsets.symmetric(
                                                  vertical: isMobile
                                                      ? 6.0
                                                      : 8.0,
                                                  horizontal: 0,
                                                ),
                                                elevation: 3,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
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
                                                    radius: isMobile
                                                        ? 20.0
                                                        : 24.0,
                                                    child: Text(
                                                      producto.nombre[0]
                                                          .toUpperCase(),
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
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
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          Provider.of<
                                                                TemaProveedor
                                                              >(context)
                                                              .esModoOscuro
                                                          ? Colors.white
                                                          : Colors.black,
                                                    ),
                                                  ),
                                                  subtitle: Text(
                                                    '${producto.unidadMedida}\nCódigo: ${producto.id}\nPrecio: ${producto.precioVenta.toStringAsFixed(2)}\nInventario: ${producto.stock.toString()}',
                                                    style: TextStyle(
                                                      color:
                                                          Provider.of<
                                                                TemaProveedor
                                                              >(context)
                                                              .esModoOscuro
                                                          ? Colors.white
                                                          : Colors.black,
                                                      fontSize:
                                                          contentFontSize - 2,
                                                    ),
                                                  ),
                                                  trailing: Icon(
                                                    Icons.add_circle_outline,
                                                    color: Colors.teal,
                                                    size: childIconSize * 0.9,
                                                  ),
                                                  onTap: () {
                                                    setState(() {
                                                      producto.cantidad = 1;
                                                      foundProduct.add(
                                                        producto,
                                                      );
                                                      widget
                                                          .onProductoSeleccionadoByCodigo(
                                                            producto,
                                                          );
                                                    });
                                                    searchController.clear();
                                                    Navigator.of(context).pop();
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
                      );
                    },
                  ).then((_) {
                    searchController.clear();
                  });
                },
              )
            : SpeedDialChild(),
        Platform.isAndroid || Platform.isIOS
            ? SpeedDialChild(
                child: Icon(
                  Icons.text_fields,
                  size: childIconSize,
                  color: Colors.white,
                ),
                backgroundColor: Colors.purpleAccent,
                label: 'Escribir nombre',
                labelStyle: TextStyle(
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.bold,
                  color: Provider.of<TemaProveedor>(context).esModoOscuro
                      ? Colors.white
                      : Colors.black,
                ),
                labelBackgroundColor:
                    Provider.of<TemaProveedor>(context).esModoOscuro
                    ? Color.fromRGBO(60, 60, 60, 1)
                    : Color.fromRGBO(220, 220, 220, 1),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return StatefulBuilder(
                        builder: (context, setState) {
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
                            content: widget.productsList.isEmpty
                                ? InventarioVacio()
                                : Container(
                                    width: dialogWidth,
                                    height: screenSize.height * 0.6,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Campo de búsqueda estilizado
                                        TextField(
                                          controller: searchController,
                                          decoration: InputDecoration(
                                            hintText:
                                                'Ingrese el nombre del producto',
                                            hintStyle: TextStyle(
                                              fontSize: contentFontSize,
                                            ),
                                            labelStyle: TextStyle(
                                              color:
                                                  Provider.of<TemaProveedor>(
                                                    context,
                                                  ).esModoOscuro
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: contentFontSize,
                                            ),
                                            prefixIcon: Icon(
                                              Icons.search,
                                              color:
                                                  Provider.of<TemaProveedor>(
                                                    context,
                                                  ).esModoOscuro
                                                  ? Colors.white
                                                  : Colors.black,
                                              size: childIconSize * 0.8,
                                            ),
                                            filled: true,
                                            fillColor:
                                                Provider.of<TemaProveedor>(
                                                  context,
                                                ).esModoOscuro
                                                ? const Color.fromRGBO(
                                                    30,
                                                    30,
                                                    30,
                                                    1,
                                                  )
                                                : const Color.fromRGBO(
                                                    244,
                                                    243,
                                                    243,
                                                    1,
                                                  ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
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
                                              borderRadius:
                                                  BorderRadius.circular(12),
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
                                              borderRadius:
                                                  BorderRadius.circular(12),
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
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  vertical: isMobile
                                                      ? 12.0
                                                      : 16.0,
                                                  horizontal: isMobile
                                                      ? 12.0
                                                      : 16.0,
                                                ),
                                          ),
                                          style: TextStyle(
                                            fontSize: contentFontSize,
                                            color:
                                                Provider.of<TemaProveedor>(
                                                  context,
                                                ).esModoOscuro
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              _filterProducts(
                                                value,
                                              ); // Actualizar productos filtrados
                                            });
                                          },
                                        ),
                                        const SizedBox(height: 16),

                                        // Lista de productos con un diseño moderno
                                        Expanded(
                                          child: ListView.builder(
                                            itemCount: filteredProducts.length,
                                            itemBuilder: (context, index) {
                                              final producto =
                                                  filteredProducts[index];
                                              return Card(
                                                color:
                                                    Provider.of<TemaProveedor>(
                                                      context,
                                                    ).esModoOscuro
                                                    ? const Color.fromRGBO(
                                                        30,
                                                        30,
                                                        30,
                                                        1,
                                                      )
                                                    : Colors.white,
                                                margin: EdgeInsets.symmetric(
                                                  vertical: isMobile
                                                      ? 6.0
                                                      : 8.0,
                                                  horizontal: 0,
                                                ),
                                                elevation: 2,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
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
                                                    radius: isMobile
                                                        ? 20.0
                                                        : 24.0,
                                                    child: Text(
                                                      producto.nombre[0]
                                                          .toUpperCase(),
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
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
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          Provider.of<
                                                                TemaProveedor
                                                              >(context)
                                                              .esModoOscuro
                                                          ? Colors.white
                                                          : Colors.black,
                                                    ),
                                                  ),
                                                  subtitle: Text(
                                                    '${producto.unidadMedida}\nPrecio: ${producto.precioVenta.toStringAsFixed(2)}\nInventario: ${producto.stock.toString()}',
                                                    style: TextStyle(
                                                      color:
                                                          Provider.of<
                                                                TemaProveedor
                                                              >(context)
                                                              .esModoOscuro
                                                          ? Colors.white
                                                          : Colors.black,
                                                      fontSize:
                                                          contentFontSize - 2,
                                                    ),
                                                  ),
                                                  trailing: Icon(
                                                    Icons.add_circle_outline,
                                                    color: Colors.blueAccent,
                                                    size: childIconSize * 0.9,
                                                  ),
                                                  onTap: () {
                                                    setState(() {
                                                      producto.cantidad = 1;
                                                      foundProduct.add(
                                                        producto,
                                                      );
                                                      widget
                                                          .onProductoSeleccionadoByNombre(
                                                            producto,
                                                          );
                                                    });
                                                    searchController.clear();
                                                    Navigator.of(context).pop();
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
                      );
                    },
                  ).then((_) {
                    searchController.clear();
                  });
                },
              )
            : SpeedDialChild(),
        // SpeedDialChild(
        //   child: Icon(
        //     Icons.add_shopping_cart,
        //     size: childIconSize,
        //     color: Colors.white,
        //   ),
        //   backgroundColor: Colors.blueAccent,
        //   label: 'Agregar nuevo producto',
        //   labelStyle: TextStyle(
        //     fontSize: labelFontSize,
        //     fontWeight: FontWeight.bold,
        //     color: Provider.of<TemaProveedor>(context).esModoOscuro
        //         ? Colors.white
        //         : Colors.black,
        //   ),
        //   labelBackgroundColor: Provider.of<TemaProveedor>(context).esModoOscuro
        //       ? Color.fromRGBO(60, 60, 60, 1)
        //       : Color.fromRGBO(220, 220, 220, 1),
        //   onTap: () {
        //     fromularioNuevoProducto();
        //   },
        // ),
      ],
    );
  }

  Future fromularioNuevoProducto() {
    // Obtenemos el tamaño de la pantalla
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;
    final bool isDesktop = screenSize.width >= 900;

    // Ajustamos tamaños según el dispositivo
    // final double childIconSize = isMobile ? 24.0 : (isTablet ? 28.0 : 30.0);
    final double dialogPadding = isMobile ? 12.0 : (isTablet ? 16.0 : 20.0);
    // final double titleFontSize = isMobile ? 16.0 : (isTablet ? 18.0 : 20.0);
    final double contentFontSize = isMobile ? 14.0 : (isTablet ? 15.0 : 16.0);

    // Calculamos el ancho del diálogo según el tamaño de pantalla
    final double dialogWidth = isDesktop
        ? screenSize.width * 0.4
        : (isTablet ? screenSize.width * 0.6 : screenSize.width * 0.9);
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
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
                  // Encabezado con icono y fondo estilizado
                  Text(
                    'Ingresar nuevo producto',
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
                  // Contenido del formulario
                  Padding(
                    padding: EdgeInsets.all(dialogPadding),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Campo de Nombre
                          _buildDialogTextField(
                            _nombre,
                            'Nombre del producto',
                            Icons.label,
                            readOnly: false,
                          ),
                          SizedBox(height: isMobile ? 12.0 : 16.0),
                          // Campo de Unidad
                          _buildDialogTextField(
                            _unidad,
                            'Unidad',
                            Icons.inventory,
                            readOnly: false,
                          ),
                          SizedBox(height: isMobile ? 12.0 : 16.0),
                          // Campo de Precio
                          _buildDialogTextField(
                            _precio,
                            'Precio',
                            Icons.attach_money,
                            readOnly: false,
                            isNumber: true,
                          ),
                          SizedBox(height: isMobile ? 12.0 : 16.0),
                          // Mensaje de advertencia
                          Text(
                            'Asegúrese de que los datos sean correctos.',
                            style: TextStyle(
                              fontSize: contentFontSize - 2,
                              color:
                                  Provider.of<TemaProveedor>(
                                    context,
                                  ).esModoOscuro
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            textAlign: TextAlign.center,
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
                                    fontSize: contentFontSize,
                                  ),
                                ),
                                onPressed: () {
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
                                    fontSize: contentFontSize,
                                  ),
                                ),
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    widget.addNewProduct(
                                      Producto(
                                        nombre: _nombre.text,
                                        precio:
                                            double.tryParse(_precio.text) ?? 0,
                                        unidadMedida: _unidad.text,
                                        id: 'N/A',
                                        costo: 0,
                                        cantidad: 1,
                                        estado: 'Activo',
                                        isv: 0,
                                        precioVenta: 0,
                                      ),
                                    );
                                    Navigator.of(context).pop();
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
      // Limpiar los controladores cuando se cierre el diálogo
      _nombre.clear();
      _unidad.clear();
      _precio.clear();
    });
  }

  // Campo de texto para el diálogo
  Widget _buildDialogTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool readOnly = false,
    bool isNumber = false,
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
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber
          ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
          : null,
      style: TextStyle(
        fontSize: isMobile ? 14.0 : 16.0,
        color: Provider.of<TemaProveedor>(context).esModoOscuro
            ? Colors.white
            : Colors.black,
      ),
      validator: (value) {
        if (value!.isEmpty) {
          return 'Por favor, ingrese el ${label.toLowerCase()}';
        } else if (isNumber && value.contains('-')) {
          return 'Por favor, ingrese un número positivo';
        }
        return null;
      },
    );
  }
}
