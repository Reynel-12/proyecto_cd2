import 'package:proyecto_cd2/controller/database.dart';
import 'package:proyecto_cd2/model/app_logger.dart';
import 'package:proyecto_cd2/model/producto.dart';

class ProductoRepository {
  final dbHelper = DBHelper();
  final AppLogger _logger = AppLogger.instance;

  Future<int> insertProducto(Producto producto) async {
    try {
      final db = await dbHelper.database;
      return await db.insert('productos', producto.toMap());
    } catch (e, st) {
      _logger.log.e('Error al insertar producto', error: e, stackTrace: st);
      return -1;
    }
  }

  Future<List<Producto>> getProductos() async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query('productos');

      return maps.map((map) => Producto.fromMap(map)).toList();
    } catch (e, st) {
      _logger.log.e('Error al obtener productos', error: e, stackTrace: st);
      return [];
    }
  }

  Future<List<Producto>> getProductosActivos() async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'productos',
        where: 'estado = ?',
        whereArgs: ['Activo'],
      );

      return maps.map((map) => Producto.fromMap(map)).toList();
    } catch (e, st) {
      _logger.log.e(
        'Error al obtener productos activos',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  Future<List<Producto>> getProductosByProveedor(int idProveedor) async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'productos',
        where: 'proveedor_id = ?',
        whereArgs: [idProveedor],
      );

      return maps.map((map) => Producto.fromMap(map)).toList();
    } catch (e, st) {
      _logger.log.e(
        'Error al obtener productos por proveedor',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  Future<List<Producto>> getProductosByCategoria(int idCategoria) async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'productos',
        where: 'categoria_id = ?',
        whereArgs: [idCategoria],
      );

      return maps.map((map) => Producto.fromMap(map)).toList();
    } catch (e, st) {
      _logger.log.e(
        'Error al obtener productos por categoria',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  Future<Producto?> getProductoByID(String id) async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'productos',
        where: 'id_producto = ?',
        whereArgs: [id],
      );

      return maps.map((map) => Producto.fromMap(map)).toList().firstOrNull;
    } catch (e, st) {
      _logger.log.e(
        'Error al obtener producto por ID',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<int> updateProducto(Producto producto) async {
    try {
      final db = await dbHelper.database;
      return await db.update(
        'productos',
        producto.toMap(),
        where: 'id_producto = ?',
        whereArgs: [producto.id],
      );
    } catch (e, st) {
      _logger.log.e('Error al actualizar producto', error: e, stackTrace: st);
      return -1;
    }
  }

  Future<int> deleteProducto(String id) async {
    try {
      final db = await dbHelper.database;
      return await db.delete(
        'productos',
        where: 'id_producto = ?',
        whereArgs: [id],
      );
    } catch (e, st) {
      _logger.log.e('Error al eliminar producto', error: e, stackTrace: st);
      return -1;
    }
  }

  Future<int> addInventario(String id, int cantidad) async {
    try {
      final db = await dbHelper.database;
      return await db.rawUpdate(
        'UPDATE productos SET stock = stock + ? WHERE id_producto = ?',
        [cantidad, id],
      );
    } catch (e, st) {
      _logger.log.e('Error al agregar inventario', error: e, stackTrace: st);
      return -1;
    }
  }

  Future<int> editInventario(String id, int cantidad) async {
    try {
      final db = await dbHelper.database;
      return await db.update(
        'productos',
        {'stock': cantidad},
        where: 'id_producto = ?',
        whereArgs: [id],
      );
    } catch (e, st) {
      _logger.log.e('Error al editar inventario', error: e, stackTrace: st);
      return -1;
    }
  }
}
