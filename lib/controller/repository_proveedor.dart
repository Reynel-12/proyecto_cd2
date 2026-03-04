import 'package:proyecto_cd2/controller/database.dart';
import 'package:proyecto_cd2/model/app_logger.dart';
import 'package:proyecto_cd2/model/proveedor.dart';

class ProveedorRepository {
  final dbHelper = DBHelper();
  final AppLogger _logger = AppLogger.instance;

  Future<int> insertProveedor(Proveedor proveedor) async {
    try {
      final db = await dbHelper.database;
      return await db.insert('proveedores', proveedor.toMap());
    } catch (e, st) {
      _logger.log.e('Error al insertar proveedor', error: e, stackTrace: st);
      return -1;
    }
  }

  Future<List<Proveedor>> getProveedores() async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query('proveedores');

      return maps.map((map) => Proveedor.fromMap(map)).toList();
    } catch (e, st) {
      _logger.log.e('Error al obtener proveedores', error: e, stackTrace: st);
      return [];
    }
  }

  Future<List<Proveedor>> getProveedoresByEstado(String estado) async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'proveedores',
        where: 'estado = ?',
        whereArgs: [estado],
      );

      return maps.map((map) => Proveedor.fromMap(map)).toList();
    } catch (e, st) {
      _logger.log.e(
        'Error al obtener proveedores por estado',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  Future<int> updateProveedor(Proveedor proveedor) async {
    try {
      final db = await dbHelper.database;
      return await db.update(
        'proveedores',
        proveedor.toMap(),
        where: 'id_proveedor = ?',
        whereArgs: [proveedor.id],
      );
    } catch (e, st) {
      _logger.log.e('Error al actualizar proveedor', error: e, stackTrace: st);
      return -1;
    }
  }

  Future<int> deleteProveedor(int id) async {
    try {
      final db = await dbHelper.database;
      return await db.delete(
        'proveedores',
        where: 'id_proveedor = ?',
        whereArgs: [id],
      );
    } catch (e, st) {
      _logger.log.e('Error al eliminar proveedor', error: e, stackTrace: st);
      return -1;
    }
  }

  Future<List<Proveedor>> getProveedorById(int id) async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'proveedores',
        where: 'id_proveedor = ?',
        whereArgs: [id],
      );

      return maps.map((map) => Proveedor.fromMap(map)).toList();
    } catch (e, st) {
      _logger.log.e(
        'Error al obtener proveedor por ID',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  // --- Métodos para manejar días de proveedores ---
  Future<List<Map<String, dynamic>>> obtenerDias() async {
    try {
      final db = await dbHelper.database;
      return await db.query('dias', orderBy: 'id_dia ASC');
    } catch (e, st) {
      _logger.log.e('Error al obtener días', error: e, stackTrace: st);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> obtenerDiasProveedor(int proveedorId) async {
    try {
      final db = await dbHelper.database;
      return await db.rawQuery('''
        SELECT d.id_dia, d.nombre FROM dias d 
        INNER JOIN dias_proveedores dp ON d.id_dia = dp.id_dia 
        WHERE dp.id_proveedor = ? 
        ORDER BY d.id_dia ASC''',
        [proveedorId],
      );
    } catch (e, st) {
      _logger.log.e('Error al obtener días del proveedor', error: e, stackTrace: st);
      return [];
    }
  }

  Future<int> insertarDiaProveedor(int proveedorId, int diaId) async {
    try {
      final db = await dbHelper.database;
      return await db.insert('dias_proveedores', {
        'id_proveedor': proveedorId,
        'id_dia': diaId,
      });
    } catch (e, st) {
      _logger.log.e('Error al insertar día proveedor', error: e, stackTrace: st);
      return -1;
    }
  }

  Future<int> eliminarDiaProveedor(int proveedorId, int diaId) async {
    try {
      final db = await dbHelper.database;
      return await db.delete(
        'dias_proveedores',
        where: 'id_proveedor = ? AND id_dia = ?',
        whereArgs: [proveedorId, diaId],
      );
    } catch (e, st) {
      _logger.log.e('Error al eliminar día proveedor', error: e, stackTrace: st);
      return -1;
    }
  }

  Future<void> eliminarTodosDiasProveedor(int proveedorId) async {
    try {
      final db = await dbHelper.database;
      await db.delete(
        'dias_proveedores',
        where: 'id_proveedor = ?',
        whereArgs: [proveedorId],
      );
    } catch (e, st) {
      _logger.log.e('Error al eliminar todos los días del proveedor', error: e, stackTrace: st);
    }
  }
}
