import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:proyecto_cd2/controller/database.dart';
import 'package:proyecto_cd2/controller/repository_proveedor.dart';
import 'package:proyecto_cd2/controller/repository_venta.dart';
import 'package:proyecto_cd2/model/inventario_optimo.dart';

class InventarioOptimoRepository {
  final String _baseUrl = 'http://127.0.0.1:5000';

  final _ventaRepo = VentaRepository();
  final _proveedorRepo = ProveedorRepository();
  final _dbHelper = DBHelper();

  /// Construye el body y hace POST a /predecir_compra.
  /// Lanza [ApiNoDisponibleException], [DatosInsuficientesException] o
  /// [ApiErrorException] según el tipo de error.
  Future<InventarioOptimoResultado> getInventarioOptimo() async {
    // 1. Obtener ventas semanales por producto
    final ventasRaw = await _ventaRepo.getVentasSemanalesPorProducto();

    if (ventasRaw.isEmpty) {
      throw DatosInsuficientesException(
        'No hay ventas registradas para generar una predicción. '
        'Registra al menos algunas ventas primero.',
      );
    }

    // 2. Obtener productos con stock y stock mínimo
    final db = await _dbHelper.database;
    final productosRaw = await db.rawQuery('''
      SELECT id_producto, stock, stock_minimo, proveedor_id
      FROM productos
      WHERE proveedor_id IS NOT NULL
      AND id_producto IN (
        SELECT DISTINCT producto_id FROM detalle_ventas
      )
    ''');

    if (productosRaw.isEmpty) {
      throw DatosInsuficientesException(
        'No hay productos con proveedor asignado o sin ventas asociadas.',
      );
    }

    // 3. Obtener días de reposición para cada proveedor único
    final proveedoresIds = productosRaw
        .map((p) => p['proveedor_id'] as int?)
        .whereType<int>()
        .toSet();

    final Map<int, String> diasPorProveedor = {};
    for (final provId in proveedoresIds) {
      final dias = await _proveedorRepo.obtenerDiasProveedor(provId);
      final diasNombres = dias
          .map((d) => (d['nombre'] as String).toLowerCase())
          .toList();
      diasPorProveedor[provId] = diasNombres.isEmpty
          ? 'lunes'
          : diasNombres.join(', ');
    }

    // 4. Construir el body JSON
    // Obtener solo los códigos de productos que tienen proveedor asignado
    final productosConProveedor = productosRaw
        .map((p) => p['id_producto'] as String)
        .toSet();

    // Filtrar ventas: solo incluir productos que estén en stock (tienen proveedor)
    // Si se envían productos sin proveedor, la API no puede cruzar datos y produce 0 samples
    final List<Map<String, dynamic>> ventasJson = ventasRaw
        .where((v) => productosConProveedor.contains(v['codigo_producto']))
        .map(
          (v) => {
            'codigo_producto': v['codigo_producto'] as String,
            'fecha': v['fecha'] as String,
            'cantidad_vendida': (v['cantidad_vendida'] as num).toInt(),
          },
        )
        .toList();

    if (ventasJson.isEmpty) {
      throw DatosInsuficientesException(
        'Los productos vendidos no tienen proveedor asignado. '
        'Asigna un proveedor a los productos para generar predicciones.',
      );
    }

    final List<Map<String, dynamic>> stockJson = productosRaw
        .map(
          (p) => {
            'codigo_producto': p['id_producto'] as String,
            'stock_actual': (p['stock'] as num).toInt(),
            'stock_minimo': (p['stock_minimo'] as num?)?.toInt() ?? 0,
            'proveedor_id': p['proveedor_id'] as int,
          },
        )
        .toList();

    final List<Map<String, dynamic>> proveedoresJson = proveedoresIds
        .map(
          (id) => {
            'proveedor_id': id,
            'dias_reposicion': diasPorProveedor[id] ?? 'lunes',
          },
        )
        .toList();

    final body = jsonEncode({
      'ventas': ventasJson,
      'stock': stockJson,
      'proveedores': proveedoresJson,
    });

    print('body: $body');

    // 5. Hacer el POST a la API
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/predecir_compra'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return InventarioOptimoResultado.fromJson(json);
      } else {
        // Intentar extraer el mensaje de error del response body
        String mensaje = 'Error del servidor';
        try {
          final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
          mensaje =
              errorJson['message']?.toString() ??
              errorJson['error']?.toString() ??
              response.body;
        } catch (_) {
          mensaje = response.body;
        }

        // Error 400 de RandomForest = pocos datos históricos (0 samples)
        if (response.statusCode == 400 &&
            mensaje.contains('0 sample') &&
            mensaje.contains('RandomForest')) {
          throw DatosInsuficientesException(
            'No hay suficientes ventas históricas para generar una predicción. '
            'Registra más ventas de los productos con proveedor asignado '
            'y vuelve a intentarlo.',
          );
        }

        throw ApiErrorException(response.statusCode, mensaje);
      }
    } on SocketException {
      throw ApiNoDisponibleException(
        'La API local no está disponible. '
        'Asegúrate de que el servidor Flask esté corriendo en $_baseUrl.',
      );
    } on HttpException {
      throw ApiNoDisponibleException(
        'Error de red al conectar con la API. '
        'Verifica que el servidor esté activo en $_baseUrl.',
      );
    }
  }
}
