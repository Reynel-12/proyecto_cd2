import 'package:proyecto_cd2/controller/database.dart';
import 'package:proyecto_cd2/model/app_logger.dart';
import 'package:proyecto_cd2/model/categorias.dart';

class RepositoryCategoria {
  final dbHelper = DBHelper();
  final AppLogger _logger = AppLogger.instance;

  Future<int> insertCategoria(Categorias categorias) async {
    try {
      final db = await dbHelper.database;
      return await db.insert('categorias', categorias.toMap());
    } catch (e, st) {
      _logger.log.e('Error al insertar categorias', error: e, stackTrace: st);
      return -1;
    }
  }

  Future<List<Categorias>> getCategorias() async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query('categorias');

      return maps.map((map) => Categorias.fromMap(map)).toList();
    } catch (e, st) {
      _logger.log.e('Error al obtener categorias', error: e, stackTrace: st);
      return [];
    }
  }

  Future<List<Categorias>> getCategoriaById(int id) async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'categorias',
        where: 'id_categoria = ?',
        whereArgs: [id],
      );

      return maps.map((map) => Categorias.fromMap(map)).toList();
    } catch (e, st) {
      _logger.log.e(
        'Error al obtener categorias por ID',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  Future<List<Categorias>> getCategoriasByEstado(String estado) async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'categorias',
        where: 'estado = ?',
        whereArgs: [estado],
      );

      return maps.map((map) => Categorias.fromMap(map)).toList();
    } catch (e, st) {
      _logger.log.e(
        'Error al obtener categorias por estado',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  Future<List<Categorias>> getCategoriasActivos() async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'categorias',
        where: 'estado = ?',
        whereArgs: ['Activo'],
      );

      return maps.map((map) => Categorias.fromMap(map)).toList();
    } catch (e, st) {
      _logger.log.e(
        'Error al obtener categorias activos',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  Future<int> updateCategoria(Categorias categorias) async {
    try {
      final db = await dbHelper.database;
      return await db.update(
        'categorias',
        categorias.toMap(),
        where: 'id_categoria = ?',
        whereArgs: [categorias.idCategoria],
      );
    } catch (e, st) {
      _logger.log.e('Error al actualizar categorias', error: e, stackTrace: st);
      return -1;
    }
  }

  Future<int> deleteCategoria(int id) async {
    try {
      final db = await dbHelper.database;
      return await db.delete(
        'categorias',
        where: 'id_categoria = ?',
        whereArgs: [id],
      );
    } catch (e, st) {
      _logger.log.e('Error al eliminar categorias', error: e, stackTrace: st);
      return -1;
    }
  }
}
