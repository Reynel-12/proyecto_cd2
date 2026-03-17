import 'dart:io';

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:proyecto_cd2/controller/repository_inventario_optimo.dart';
import 'package:proyecto_cd2/controller/repository_producto.dart';
import 'package:proyecto_cd2/model/app_logger.dart';
import 'package:proyecto_cd2/model/inventario_optimo.dart';
import 'package:proyecto_cd2/model/preferences.dart';
import 'package:proyecto_cd2/model/producto.dart';
import 'package:proyecto_cd2/view/barcode_scanner_view.dart';
import 'package:proyecto_cd2/view/widgets/loading.dart';
import 'package:provider/provider.dart';

class InventarioOptimo extends StatefulWidget {
  const InventarioOptimo({super.key});

  @override
  State<InventarioOptimo> createState() => _InventarioOptimoState();
}

class _InventarioOptimoState extends State<InventarioOptimo> {
  TextEditingController searchController = TextEditingController();
  final _repositoryProducto = ProductoRepository();
  final _repositoryInventarioOptimo = InventarioOptimoRepository();
  final AppLogger _logger = AppLogger.instance;

  bool _isLoading = false;
  InventarioOptimoResultado? _resultado;

  /// Mapa de código_producto → Producto para enriquecer resultados
  Map<String, Producto> _productosMap = {};
  Map<String, Producto> _productosMapFiltrados = {};

  String scanResult = '';

  @override
  void initState() {
    super.initState();
    _cargarInventarioOptimo();
  }

  Future<void> _cargarInventarioOptimo() async {
    setState(() => _isLoading = true);

    try {
      // Cargar todos los productos primero para enriquecer resultados
      final productos = await _repositoryProducto.getProductos();
      final map = {for (final p in productos) p.id: p};

      // Llamar a la API
      final resultado = await _repositoryInventarioOptimo.getInventarioOptimo();

      if (!mounted) return;
      setState(() {
        _productosMap = map;
        _productosMapFiltrados = map;
        _resultado = resultado;
        _isLoading = false;
      });
    } on ApiNoDisponibleException catch (e) {
      _logger.log.w('API no disponible: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      _mostrarMensaje(
        'API no disponible',
        'Servidor no disponible, intente más tarde',
        ContentType.failure,
      );
    } on DatosInsuficientesException catch (e) {
      _logger.log.w('Datos insuficientes: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      _mostrarMensaje('Datos insuficientes', e.mensaje, ContentType.warning);
    } on ApiErrorException catch (e) {
      _logger.log.e('Error de API: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      _mostrarMensaje(
        'Error del servidor (${e.statusCode})',
        e.mensaje,
        ContentType.failure,
      );
    } catch (e, st) {
      _logger.log.e('Error inesperado', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _isLoading = false);
      _mostrarMensaje(
        'Error inesperado',
        'Ocurrió un error al cargar el inventario óptimo: $e',
        ContentType.failure,
      );
    }
  }

  // Función para eliminar acentos y caracteres especiales
  String _normalizeString(String str) {
    return removeDiacritics(str.trim().toLowerCase());
  }

  void _filterProducts(String query) {
    final normalizedQuery = _normalizeString(query);

    setState(() {
      if (normalizedQuery.isEmpty) {
        _productosMapFiltrados = Map.from(_productosMap);
      } else {
        // 1. Buscamos coincidencias por código (contains, no exact match)
        var resultados = _productosMap.entries.where((entry) {
          return _normalizeString(entry.key).contains(normalizedQuery);
        }).toList();

        // 2. Si no hubo por código, buscamos por nombre
        if (resultados.isEmpty) {
          resultados = _productosMap.entries.where((entry) {
            return _normalizeString(
              entry.value.nombre,
            ).contains(normalizedQuery);
          }).toList();
        }

        // Si no hay coincidencia, el mapa queda vacío → la lista mostrará vacío
        _productosMapFiltrados = Map.fromEntries(resultados);
      }
    });
  }

  void _filterProductsByCode(String query) {
    if (query == "-1") {
      // El usuario canceló el escaneo
      return;
    }
    if (query.isEmpty) {
      setState(() {
        _productosMapFiltrados = Map.from(_productosMap);
      });
      return;
    }

    final filtered = Map.fromEntries(
      _productosMap.entries.where(
        (entry) => entry.key.toLowerCase().contains(query.toLowerCase()),
      ),
    );

    setState(() {
      _productosMapFiltrados = filtered;
    });

    if (filtered.isEmpty) {
      _mostrarMensaje(
        'Atención',
        'Producto con código: $query no encontrado',
        ContentType.warning,
      );
    }
  }

  /// Filtra las recomendaciones para mostrar sólo las que coinciden con
  /// los productos actualmente en [_productosMapFiltrados], y además ordena
  /// el resultado alfabéticamente por nombre del producto (o por código si
  /// no se encuentra el producto).
  List<RecomendacionCompra> get _recomendacionesFiltradas {
    if (_resultado == null) return [];

    final lista = _resultado!.recomendaciones
        .where((r) => _productosMapFiltrados.containsKey(r.codigoProducto))
        .toList();

    // ordenar por nombre o, en su defecto, por código
    lista.sort((a, b) {
      final nombreA =
          _productosMapFiltrados[a.codigoProducto]?.nombre ?? a.codigoProducto;
      final nombreB =
          _productosMapFiltrados[b.codigoProducto]?.nombre ?? b.codigoProducto;
      return nombreA.toLowerCase().compareTo(nombreB.toLowerCase());
    });

    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;
    final bool isDesktop = screenSize.width >= 900;
    final double titleFontSize = isMobile ? 18.0 : (isTablet ? 20.0 : 22.0);
    final double contentPadding = isMobile ? 12.0 : (isTablet ? 16.0 : 24.0);
    final bool esModoOscuro = Provider.of<TemaProveedor>(context).esModoOscuro;

    if (_isLoading) return const CargandoInventario();

    return Scaffold(
      backgroundColor: esModoOscuro
          ? Colors.black
          : const Color.fromRGBO(244, 243, 243, 1),
      appBar: AppBar(
        title: Text(
          'Inventario óptimo',
          style: TextStyle(
            color: esModoOscuro ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: titleFontSize,
          ),
        ),
        centerTitle: true,
        backgroundColor: esModoOscuro
            ? Colors.black
            : const Color.fromRGBO(244, 243, 243, 1),
        iconTheme: IconThemeData(
          color: esModoOscuro ? Colors.white : Colors.black,
        ),
        actions: [
          // Botón de recarga
          IconButton(
            tooltip: 'Recalcular inventario',
            icon: Icon(
              Icons.refresh_rounded,
              color: esModoOscuro ? Colors.white : Colors.black,
            ),
            onPressed: _cargarInventarioOptimo,
          ),
        ],
      ),
      body: _resultado == null || _resultado!.recomendaciones.isEmpty
          ? _buildEmpty(esModoOscuro)
          : Padding(
              padding: EdgeInsets.all(contentPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Indicador de precisión del modelo (MAE)
                  // _buildMaeIndicador(_resultado!.mae, esModoOscuro, isMobile),
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
                        color: Provider.of<TemaProveedor>(context).esModoOscuro
                            ? Colors.white
                            : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 14.0 : 16.0,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Provider.of<TemaProveedor>(context).esModoOscuro
                            ? Colors.white
                            : Colors.black,
                        size: isMobile ? 20.0 : 22.0,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.barcode_reader,
                          color:
                              Provider.of<TemaProveedor>(context).esModoOscuro
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
                        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                        borderSide: BorderSide(
                          color:
                              Provider.of<TemaProveedor>(context).esModoOscuro
                              ? Colors.white
                              : Colors.black,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                        borderSide: BorderSide(
                          color:
                              Provider.of<TemaProveedor>(context).esModoOscuro
                              ? Colors.white
                              : Colors.black,
                          width: 2.0,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                        borderSide: BorderSide(
                          color:
                              Provider.of<TemaProveedor>(context).esModoOscuro
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
                      color: Provider.of<TemaProveedor>(context).esModoOscuro
                          ? Colors.white
                          : Colors.black,
                    ),
                    onChanged: (value) {
                      _filterProducts(value);
                    },
                  ),
                  SizedBox(height: isMobile ? 12.0 : 16.0),
                  Expanded(
                    child: isDesktop
                        ? _buildGridView(_recomendacionesFiltradas)
                        : _buildListView(_recomendacionesFiltradas),
                  ),
                ],
              ),
            ),
    );
  }

  // ----- Widgets de contenido -----

  // Widget _buildMaeIndicador(double mae, bool esModoOscuro, bool isMobile) {
  //   final Color maeColor = mae < 2.0
  //       ? Colors.green
  //       : mae < 5.0
  //       ? Colors.amber
  //       : Colors.red;

  //   return Container(
  //     padding: EdgeInsets.symmetric(
  //       horizontal: isMobile ? 14.0 : 18.0,
  //       vertical: isMobile ? 10.0 : 12.0,
  //     ),
  //     decoration: BoxDecoration(
  //       color: maeColor.withValues(alpha: 0.12),
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: maeColor.withValues(alpha: 0.4)),
  //     ),
  //     child: Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Icon(
  //           Icons.insights_rounded,
  //           color: maeColor,
  //           size: isMobile ? 18 : 22,
  //         ),
  //         const SizedBox(width: 8),
  //         Text(
  //           'Precisión del modelo (MAE): ${mae.toStringAsFixed(2)}',
  //           style: TextStyle(
  //             color: maeColor,
  //             fontWeight: FontWeight.bold,
  //             fontSize: isMobile ? 13.0 : 15.0,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildEmpty(bool esModoOscuro) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 72,
            color: esModoOscuro ? Colors.white38 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            'Sin recomendaciones disponibles',
            style: TextStyle(
              fontSize: 16,
              color: esModoOscuro ? Colors.white54 : Colors.black45,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
            onPressed: _cargarInventarioOptimo,
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<RecomendacionCompra> recomendaciones) {
    return ListView.builder(
      itemCount: recomendaciones.length,
      itemBuilder: (context, index) {
        return _cardRecomendacion(recomendaciones[index], 3.0, false);
      },
    );
  }

  Widget _buildGridView(List<RecomendacionCompra> recomendaciones) {
    final screenSize = MediaQuery.of(context).size;
    final bool isDesktopL = screenSize.width >= 1100;
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: isDesktopL ? 3.2 : 2.5,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      ),
      itemCount: recomendaciones.length,
      itemBuilder: (context, index) {
        return _cardRecomendacion(recomendaciones[index], 5.0, true);
      },
    );
  }

  Widget _cardRecomendacion(
    RecomendacionCompra rec,
    double elevation,
    bool isDesktop,
  ) {
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;
    final bool esModoOscuro = Provider.of<TemaProveedor>(
      context,
      listen: false,
    ).esModoOscuro;

    final double titleFontSize = isMobile ? 16.0 : (isTablet ? 18.0 : 20.0);
    final double subtitleFontSize = isMobile ? 12.0 : (isTablet ? 13.0 : 14.0);
    final double infoFontSize = isMobile ? 13.0 : (isTablet ? 14.0 : 15.0);
    final double iconSize = isMobile ? 22.0 : (isTablet ? 26.0 : 28.0);
    final double avatarRadius = isMobile ? 25.0 : (isTablet ? 28.0 : 30.0);
    final double cardPadding = isMobile ? 14.0 : (isTablet ? 16.0 : 18.0);

    // Enriquecer con datos del producto
    final producto = _productosMapFiltrados[rec.codigoProducto];
    final String nombre = producto?.nombre ?? rec.codigoProducto;
    final double precio = producto?.precioVenta ?? 0.0;
    final double costo = producto?.costo ?? 0.0;
    final int cantidadAComprar = rec.cantidadAComprar;

    // Color del stock sugerido
    final Color stockColor = cantidadAComprar == 0
        ? Colors.green
        : cantidadAComprar <= 5
        ? Colors.amber
        : Colors.red;

    return Card(
      color: esModoOscuro ? const Color.fromRGBO(30, 30, 30, 1) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 16.0 : 20.0),
      ),
      elevation: elevation,
      margin: EdgeInsets.symmetric(
        vertical: isMobile ? 8.0 : 10.0,
        horizontal: isMobile ? 4.0 : 0.0,
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              backgroundColor: Colors.blueAccent,
              radius: avatarRadius,
              child: Icon(
                Icons.shopping_cart_checkout_rounded,
                size: iconSize,
                color: Colors.white,
              ),
            ),
            SizedBox(width: isMobile ? 12.0 : 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre del producto
                  Text(
                    nombre,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: esModoOscuro ? Colors.white : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isMobile ? 2.0 : 4.0),
                  // Código producto
                  Text(
                    'Código: ${rec.codigoProducto}',
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      color: esModoOscuro
                          ? const Color.fromRGBO(200, 200, 200, 1)
                          : const Color.fromRGBO(90, 90, 90, 1),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isMobile ? 8.0 : 10.0),
                  // Precio de venta
                  _buildInfoRow(
                    Icons.price_change_outlined,
                    'Precio: L. ${precio.toStringAsFixed(2)}',
                    esModoOscuro ? Colors.white : Colors.black,
                    infoFontSize,
                    isMobile,
                  ),
                  SizedBox(height: isMobile ? 4.0 : 6.0),
                  // Costo
                  _buildInfoRow(
                    Icons.monetization_on_outlined,
                    'Costo: L. ${costo.toStringAsFixed(2)}',
                    esModoOscuro ? Colors.white : Colors.black,
                    infoFontSize,
                    isMobile,
                  ),
                  SizedBox(height: isMobile ? 4.0 : 6.0),
                  // Cantidad a comprar
                  _buildInfoRow(
                    Icons.add_shopping_cart_rounded,
                    cantidadAComprar == 0
                        ? 'Stock suficiente'
                        : 'Comprar: $cantidadAComprar unidades',
                    stockColor,
                    infoFontSize,
                    isMobile,
                    bold: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String texto,
    Color color,
    double fontSize,
    bool isMobile, {
    bool bold = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: isMobile ? 16.0 : 18.0),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ----- Mensajes -----

  void _mostrarMensaje(String titulo, String mensaje, ContentType type) {
    if (!mounted) return;
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
}
