import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:proyecto_cd2/controller/database.dart';
import 'package:proyecto_cd2/controller/repository_proveedor.dart';
import 'package:proyecto_cd2/controller/repository_venta.dart';
import 'package:proyecto_cd2/model/inventario_optimo.dart';
import 'package:csv/csv.dart';

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

  // ─────────────────────────────────────────────────────────────────────────
  // EXPORTACIONES CSV – sin filtro de fecha, sin agrupaciones
  // ─────────────────────────────────────────────────────────────────────────

  /// Guarda [filas] como CSV en [nombreArchivo] dentro del directorio de
  /// Documentos de la aplicación. Retorna la ruta completa del archivo.
  Future<String> _writeCsv(
    String nombreArchivo,
    List<List<dynamic>> filas,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$nombreArchivo');
    // csv ^7.x exports ListToCsvConverter from 'package:csv/csv.dart'
    final csvData = csv.encode(filas);
    await file.writeAsString(csvData, encoding: utf8);
    return file.path;
  }

  // ── 1. VENTAS ─────────────────────────────────────────────────────────────
  /// Exporta **todas** las ventas con su detalle línea a línea (sin agrupar).
  /// Cada fila = 1 ítem vendido con datos de cabecera de factura,
  /// producto, categoría y proveedor.
  /// Retorna la ruta del archivo generado.
  Future<String> exportarVentasCSV() async {
    final db = await _dbHelper.database;

    final rows = await db.rawQuery('''
      SELECT
        v.id_venta,
        v.numero_factura,
        v.fecha,
        v.tipo_documento,
        v.cajero,
        v.metodo_pago,
        v.nombre_cliente,
        v.moneda,
        v.subtotal       AS subtotal_factura,
        v.isv            AS isv_factura,
        v.total          AS total_factura,
        v.monto_pagado,
        v.cambio,
        v.estado_fiscal,
        dv.id_detalle_venta,
        dv.producto_id,
        dv.descripcion   AS descripcion_linea,
        c.nombre         AS categoria,
        pr.nombre        AS proveedor,
        p.unidad_medida,
        dv.cantidad,
        dv.precio_unitario,
        dv.subtotal      AS subtotal_linea,
        dv.isv           AS isv_linea,
        dv.descuento
      FROM ventas v
      INNER JOIN detalle_ventas dv ON v.id_venta = dv.venta_id
      INNER JOIN productos p       ON dv.producto_id = p.id_producto
      LEFT  JOIN categorias c      ON p.categoria_id = c.id_categoria
      LEFT  JOIN proveedores pr    ON p.proveedor_id = pr.id_proveedor
      ORDER BY v.fecha ASC, v.id_venta ASC, dv.id_detalle_venta ASC
    ''');

    final header = [
      'id_venta',
      'numero_factura',
      'fecha',
      'tipo_documento',
      'cajero',
      'metodo_pago',
      'nombre_cliente',
      'moneda',
      'subtotal_factura',
      'isv_factura',
      'total_factura',
      'monto_pagado',
      'cambio',
      'estado_fiscal',
      'id_detalle_venta',
      'producto_id',
      'descripcion_linea',
      'categoria',
      'proveedor',
      'unidad_medida',
      'cantidad',
      'precio_unitario',
      'subtotal_linea',
      'isv_linea',
      'descuento',
    ];

    final body = rows.map((row) {
      return header.map((col) {
        var value = row[col];

        // Devolvemos el valor o un string vacío si es null para otros campos
        return value ?? '';
      }).toList();
    }).toList();

    return _writeCsv('ventas.csv', [header, ...body]);
  }

  // ── 2. PRODUCTOS ──────────────────────────────────────────────────────────
  /// Exporta el catálogo completo de productos con su categoría y proveedor.
  /// Una fila por producto, todos los productos (activos e inactivos).
  /// Retorna la ruta del archivo generado.
  Future<String> exportarProductosCSV() async {
    final db = await _dbHelper.database;

    final rows = await db.rawQuery('''
      SELECT
        p.id_producto,
        p.nombre,
        c.nombre        AS categoria,
        pr.nombre       AS proveedor,
        pr.id_proveedor AS proveedor_id,
        p.unidad_medida,
        p.precio,
        p.costo,
        p.precio_venta,
        p.isv           AS isv_pct,
        p.stock,
        p.stock_minimo,
        p.estado,
        p.fecha_creacion,
        p.fecha_actualizacion
      FROM productos p
      LEFT JOIN categorias c   ON p.categoria_id = c.id_categoria
      LEFT JOIN proveedores pr ON p.proveedor_id  = pr.id_proveedor
      ORDER BY p.nombre ASC
    ''');

    final header = [
      'id_producto',
      'nombre',
      'categoria',
      'proveedor',
      'proveedor_id',
      'unidad_medida',
      'precio',
      'costo',
      'precio_venta',
      'isv_pct',
      'stock',
      'stock_minimo',
      'estado',
      'fecha_creacion',
      'fecha_actualizacion',
    ];

    final body = rows
        .map((r) => header.map((col) => r[col] ?? '').toList())
        .toList();

    return _writeCsv('productos.csv', [header, ...body]);
  }

  // ── 3. PROVEEDORES ────────────────────────────────────────────────────────
  /// Exporta todos los proveedores con sus días de reposición concatenados
  /// (ej. "Lunes, Miércoles, Viernes"). Una fila por proveedor.
  /// Retorna la ruta del archivo generado.
  Future<String> exportarProveedoresCSV() async {
    final db = await _dbHelper.database;

    // Obtener todos los proveedores
    final proveedores = await db.rawQuery('''
      SELECT
        id_proveedor,
        nombre,
        direccion,
        telefono,
        correo,
        estado,
        fecha_registro,
        fecha_actualizacion
      FROM proveedores
      ORDER BY nombre ASC
    ''');

    // Para cada proveedor, obtener sus días de reposición
    final header = [
      'id_proveedor',
      'nombre',
      'direccion',
      'telefono',
      'correo',
      'estado',
      'fecha_registro',
      'fecha_actualizacion',
      'dias_reposicion',
    ];

    final List<List<dynamic>> body = [];

    for (final prov in proveedores) {
      final provId = prov['id_proveedor'] as int;

      final dias = await db.rawQuery(
        '''
        SELECT d.nombre
        FROM dias d
        INNER JOIN dias_proveedores dp ON d.id_dia = dp.id_dia
        WHERE dp.id_proveedor = ?
        ORDER BY d.id_dia ASC
      ''',
        [provId],
      );

      final diasStr = dias.map((d) => d['nombre'] as String).join(', ');

      body.add([
        prov['id_proveedor'] ?? '',
        prov['nombre'] ?? '',
        prov['direccion'] ?? '',
        prov['telefono'] ?? '',
        prov['correo'] ?? '',
        prov['estado'] ?? '',
        prov['fecha_registro'] ?? '',
        prov['fecha_actualizacion'] ?? '',
        diasStr,
      ]);
    }

    return _writeCsv('proveedores.csv', [header, ...body]);
  }

  /// Exporta los tres CSV (ventas, productos, proveedores) de una sola vez.
  /// Retorna un mapa con las rutas de cada archivo generado.
  Future<Map<String, String>> exportarTodosLosCSV() async {
    final ventas = await exportarVentasCSV();
    final productos = await exportarProductosCSV();
    final proveedores = await exportarProveedoresCSV();
    return {
      'ventas': ventas,
      'productos': productos,
      'proveedores': proveedores,
    };
  }

  /// Compatibilidad con código existente: exporta los tres CSV en background.
  Future<void> exportarDatos() async {
    print(await exportarTodosLosCSV());
  }
}
