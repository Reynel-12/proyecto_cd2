import 'package:proyecto_cd2/controller/database.dart';
import 'package:proyecto_cd2/model/app_logger.dart';
import 'package:proyecto_cd2/model/detalle_venta.dart';
import 'package:proyecto_cd2/model/venta.dart';
import 'package:sqflite/sqflite.dart';

class VentaRepository {
  final dbHelper = DBHelper();
  final AppLogger _logger = AppLogger.instance;

  Future<String> _generarNumeroFactura(Transaction txn) async {
    try {
      final now = DateTime.now();
      final datePart =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

      final query =
          '''
      SELECT numero_factura 
      FROM ${DBHelper.ventasTable}
      WHERE numero_factura LIKE 'FAC-$datePart-%'
      ORDER BY id_venta DESC
      LIMIT 1
    ''';

      final List<Map<String, dynamic>> result = await txn.rawQuery(query);

      int correlativo = 1;

      if (result.isNotEmpty) {
        final lastInvoice = result.first['numero_factura']?.toString();

        if (lastInvoice != null && lastInvoice.contains('-')) {
          final parts = lastInvoice.split('-');

          if (parts.length == 3) {
            final parsed = int.tryParse(parts[2]);
            if (parsed != null) {
              correlativo = parsed + 1;
            } else {}
          } else {}
        }
      }

      return 'FAC-$datePart-${correlativo.toString().padLeft(4, '0')}';
    } catch (e, st) {
      _logger.log.e(
        'Error al generar numero de factura',
        error: e,
        stackTrace: st,
      );
      // 🔥 fallback seguro para evitar romper la transacción
      final fallback = DateTime.now().millisecondsSinceEpoch;
      return 'FAC-ERR-$fallback';
    }
  }

  Future<int> registrarVentaConDetalles(
    Venta venta,
    List<DetalleVenta> detalles,
  ) async {
    try {
      final db = await dbHelper.database;
      return await db.transaction<int>((txn) async {
        // 1. Verificar stock producto por producto
        for (final detalle in detalles) {
          if (detalle.productoId == 'N/A') {
            continue;
          }
          final result = await txn.rawQuery(
            '''
        SELECT stock FROM productos WHERE id_producto = ?
        ''',
            [detalle.productoId],
          );

          if (result.isEmpty) {
            throw Exception("El producto ${detalle.productoId} no existe.");
          }

          final int stockActual = result.first['stock'] as int;

          if (stockActual < detalle.cantidad) {
            _logger.log.w(
              'Stock insuficiente para el producto ${detalle.productoId}. Stock actual: $stockActual, requerido: ${detalle.cantidad}',
            );
            return -2;
          }
        }

        final numeroFactura = await _generarNumeroFactura(txn);
        venta.numeroFactura = numeroFactura;

        // 2. Si todo ok, insertar venta
        final int ventaId = await txn.insert('ventas', venta.toMap());

        // 3. Insertar detalles + actualizar stock
        for (final detalle in detalles) {
          final detalleFix = detalle;
          detalleFix.ventaId = ventaId;

          // Insertar detalle
          await txn.insert('detalle_ventas', detalleFix.toMap());

          // Descontar stock
          await txn.rawUpdate(
            '''
        UPDATE productos
        SET stock = stock - ?
        WHERE id_producto = ?
        ''',
            [detalle.cantidad, detalle.productoId],
          );
        }

        return ventaId;
      });
    } catch (e, st) {
      _logger.log.e('Error al registrar venta', error: e, stackTrace: st);
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> getHistorialVentasDetallado() async {
    try {
      final db = await dbHelper.database; // Tu instancia de sqflite

      return await db.rawQuery('''
    SELECT 
      v.id_venta AS venta_id,
      v.fecha,
      v.total AS venta_total,
      v.estado_fiscal,
      v.cambio,
      v.monto_pagado,
      v.numero_factura,
      v.cai,
      v.rtn_cliente,
      v.nombre_cliente,
      v.rango_autorizado,
      v.rtn_emisor,
      v.razon_social_emisor,
      v.fecha_limite_cai,
      v.isv,
      v.subtotal,
      v.metodo_pago,
      dv.cantidad,
      dv.precio_unitario,
      dv.subtotal,
      dv.isv AS isv_detalle,
      dv.descuento,
      p.nombre AS producto_nombre,
      p.unidad_medida
    FROM ventas v
    INNER JOIN detalle_ventas dv ON v.id_venta = dv.venta_id
    INNER JOIN productos p ON dv.producto_id = p.id_producto
    ORDER BY v.fecha DESC
  ''');
    } catch (e, st) {
      _logger.log.e(
        'Error al obtener historial de ventas detallado',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  Future<List<VentaCompleta>> getVentasAgrupadas() async {
    try {
      final res = await getHistorialVentasDetallado();

      // Usamos un Map para agrupar detalles por ID de venta
      Map<int, VentaCompleta> ventasMap = {};

      for (var row in res) {
        int idVenta = row['venta_id'];

        if (!ventasMap.containsKey(idVenta)) {
          ventasMap[idVenta] = VentaCompleta(
            id: idVenta,
            fecha: row['fecha'],
            total: row['venta_total'],
            estado: row['estado_fiscal'],
            cambio: row['cambio'],
            montoPagado: row['monto_pagado'],
            numeroFactura: row['numero_factura'],
            cai: row['cai'],
            rtnCliente: row['rtn_cliente'],
            nombreCliente: row['nombre_cliente'],
            rangoAutorizado: row['rango_autorizado'],
            rtnEmisor: row['rtn_emisor'],
            razonSocialEmisor: row['razon_social_emisor'],
            fechaLimiteCai: row['fecha_limite_cai'],
            isv: row['isv'],
            subtotal: row['subtotal'],
            metodoPago: row['metodo_pago'],
            detalles: [],
          );
        }

        ventasMap[idVenta]!.detalles.add(
          DetalleItem(
            producto: row['producto_nombre'],
            unidadMedida: row['unidad_medida'],
            cantidad: row['cantidad'],
            precio: row['precio_unitario'],
            isv: row['isv_detalle'],
            subtotal: row['subtotal'],
            descuento: row['descuento'],
          ),
        );
      }

      return ventasMap.values.toList();
    } catch (e, st) {
      _logger.log.e(
        'Error al obtener ventas agrupadas',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  Future<double> getTotalVentasByProducto(String productoId) async {
    try {
      final db = await dbHelper.database;
      final result = await db.rawQuery(
        '''
      SELECT SUM(cantidad) as total
      FROM ${DBHelper.detalleVentasTable}
      WHERE producto_id = ?
    ''',
        [productoId],
      );

      if (result.isNotEmpty && result.first['total'] != null) {
        return (result.first['total'] as num).toDouble();
      }
      return 0.0;
    } catch (e, st) {
      _logger.log.e(
        'Error al obtener total de ventas por producto',
        error: e,
        stackTrace: st,
      );
      return 0.0;
    }
  }

  Future<List<Map<String, dynamic>>> getUltimasVentasByProducto(
    String productoId, {
    int limit = 5,
  }) async {
    try {
      final db = await dbHelper.database;
      return await db.rawQuery(
        '''
      SELECT 
        v.fecha,
        dv.cantidad,
        dv.precio_unitario,
        dv.subtotal
      FROM ${DBHelper.ventasTable} v
      INNER JOIN ${DBHelper.detalleVentasTable} dv ON v.id_venta = dv.venta_id
      WHERE dv.producto_id = ?
      ORDER BY v.fecha DESC
      LIMIT ?
    ''',
        [productoId, limit],
      );
    } catch (e, st) {
      _logger.log.e(
        'Error al obtener últimas ventas por producto',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  // --- Mètodos para Estadísticas ---

  Future<List<Map<String, dynamic>>> getTopProductosVendidos({
    int limit = 10,
  }) async {
    try {
      final db = await dbHelper.database;
      return await db.rawQuery(
        '''
        SELECT 
          p.nombre,
          p.unidad_medida,
          SUM(dv.cantidad) as total_vendido,
          SUM(dv.subtotal) as total_ingresos
        FROM ${DBHelper.detalleVentasTable} dv
        INNER JOIN ${DBHelper.productosTable} p ON dv.producto_id = p.id_producto
        GROUP BY dv.producto_id
        ORDER BY total_vendido DESC
        LIMIT ?
      ''',
        [limit],
      );
    } catch (e, st) {
      _logger.log.e(
        'Error al obtener top productos vendidos',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTopCategoriasVendidas({
    int limit = 5,
  }) async {
    try {
      final db = await dbHelper.database;
      return await db.rawQuery(
        '''
        SELECT 
          c.nombre,
          SUM(dv.cantidad) as total_vendido
        FROM ${DBHelper.detalleVentasTable} dv
        INNER JOIN ${DBHelper.productosTable} p ON dv.producto_id = p.id_producto
        INNER JOIN ${DBHelper.categoriasTable} c ON p.categoria_id = c.id_categoria
        GROUP BY c.id_categoria
        ORDER BY total_vendido DESC
        LIMIT ?
      ''',
        [limit],
      );
    } catch (e, st) {
      _logger.log.e(
        'Error al obtener top categorias vendidas',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  /// Retorna cada venta individual por producto para la API de inventario.
  /// Sin agrupación: si el mismo producto se vendió varias veces el mismo día,
  /// aparece una fila por cada venta.
  /// Filtra solo los últimos [semanas] semanas para no sobrecargar la API.
  Future<List<Map<String, dynamic>>> getVentasSemanalesPorProducto({
    int semanas = 12,
  }) async {
    try {
      final db = await dbHelper.database;
      final fechaLimite = DateTime.now()
          .subtract(Duration(days: semanas * 7))
          .toIso8601String()
          .substring(0, 10);

      return await db.rawQuery(
        '''
        SELECT
          dv.producto_id AS codigo_producto,
          date(v.fecha) AS fecha,
          dv.cantidad AS cantidad_vendida
        FROM ${DBHelper.ventasTable} v
        INNER JOIN ${DBHelper.detalleVentasTable} dv ON v.id_venta = dv.venta_id
        WHERE date(v.fecha) >= ?
        ORDER BY dv.producto_id, v.fecha ASC
        ''',
        [fechaLimite],
      );
    } catch (e, st) {
      _logger.log.e(
        'Error al obtener ventas por producto',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  Future<Map<String, double>> getResumenVentas() async {
    try {
      final db = await dbHelper.database;
      final now = DateTime.now();

      // Fechas para hoy
      final startToday = DateTime(
        now.year,
        now.month,
        now.day,
      ).toIso8601String();
      final endToday = DateTime(
        now.year,
        now.month,
        now.day,
        23,
        59,
        59,
      ).toIso8601String();

      // Fechas para semana actual (Lunes a Domingo)
      // En Dart weekday 1 = Lunes, 7 = Domingo
      final startWeekDate = now.subtract(Duration(days: now.weekday - 1));
      final startWeek = DateTime(
        startWeekDate.year,
        startWeekDate.month,
        startWeekDate.day,
      ).toIso8601String();

      // Fechas para mes actual
      final startMonth = DateTime(now.year, now.month, 1).toIso8601String();

      // Consultas
      final resHoy = await db.rawQuery(
        "SELECT SUM(total) as total FROM ${DBHelper.ventasTable} WHERE fecha BETWEEN ? AND ?",
        [startToday, endToday],
      );

      final resSemana = await db.rawQuery(
        "SELECT SUM(total) as total FROM ${DBHelper.ventasTable} WHERE fecha >= ?",
        [startWeek],
      );

      final resMes = await db.rawQuery(
        "SELECT SUM(total) as total FROM ${DBHelper.ventasTable} WHERE fecha >= ?",
        [startMonth],
      );

      return {
        'hoy': (resHoy.first['total'] as num?)?.toDouble() ?? 0.0,
        'semana': (resSemana.first['total'] as num?)?.toDouble() ?? 0.0,
        'mes': (resMes.first['total'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e, st) {
      _logger.log.e(
        'Error al obtener resumen de ventas',
        error: e,
        stackTrace: st,
      );
      return {'hoy': 0.0, 'semana': 0.0, 'mes': 0.0};
    }
  }
}
