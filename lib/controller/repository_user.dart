import 'package:proyecto_cd2/controller/database.dart';
import 'package:sqflite/sqflite.dart';
import 'package:proyecto_cd2/model/app_logger.dart';
import 'package:proyecto_cd2/model/user.dart';

class RepositoryUser {
  final dbHelper = DBHelper();
  final AppLogger _logger = AppLogger.instance;

  Future<int> insertUser(User user) async {
    try {
      final db = await dbHelper.database;
      return await db.insert(DBHelper.usuariosTable, user.toMap());
    } catch (e, st) {
      _logger.log.e('Error al insertar usuario', error: e, stackTrace: st);
      return -1;
    }
  }

  Future<List<User>> getAllUsers() async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DBHelper.usuariosTable,
      );
      return List.generate(maps.length, (i) {
        return User(
          id: maps[i]['id_usuario'],
          nombre: maps[i]['nombre'],
          apellido: maps[i]['apellido'],
          telefono: maps[i]['telefono'],
          correo: maps[i]['correo'],
          contrasena: maps[i]['contrasena'],
          tipo: maps[i]['tipo'],
          estado: maps[i]['estado'],
          fechaCreacion: maps[i]['fecha_creacion'],
          fechaActualizacion: maps[i]['fecha_actualizacion'],
        );
      });
    } catch (e, st) {
      _logger.log.e('Error al obtener usuarios', error: e, stackTrace: st);
      return [];
    }
  }

  Future<User?> getUserById(int id) async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DBHelper.usuariosTable,
        where: 'id_usuario = ?',
        whereArgs: [id],
      );
      if (maps.isEmpty) {
        return null;
      }
      return User(
        id: maps[0]['id_usuario'],
        nombre: maps[0]['nombre'],
        apellido: maps[0]['apellido'],
        telefono: maps[0]['telefono'],
        correo: maps[0]['correo'],
        contrasena: maps[0]['contrasena'],
        tipo: maps[0]['tipo'],
        estado: maps[0]['estado'],
        fechaCreacion: maps[0]['fecha_creacion'],
        fechaActualizacion: maps[0]['fecha_actualizacion'],
      );
    } catch (e, st) {
      _logger.log.e(
        'Error al obtener usuario por ID',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<int> updateUser(int id, Map<String, dynamic> user) async {
    try {
      final db = await dbHelper.database;
      return await db.update(
        DBHelper.usuariosTable,
        user,
        where: 'id_usuario = ?',
        whereArgs: [id],
      );
    } catch (e, st) {
      _logger.log.e('Error al actualizar usuario', error: e, stackTrace: st);
      return -1;
    }
  }

  Future<int> deleteUser(int id) async {
    try {
      final db = await dbHelper.database;
      return await db.delete(
        DBHelper.usuariosTable,
        where: 'id_usuario = ?',
        whereArgs: [id],
      );
    } catch (e, st) {
      _logger.log.e('Error al eliminar usuario', error: e, stackTrace: st);
      return -1;
    }
  }

  Future<User?> getUserByEmail(String correo) async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DBHelper.usuariosTable,
        where: 'correo = ?',
        whereArgs: [correo],
      );
      if (maps.isEmpty) {
        return null;
      }
      return User(
        id: maps[0]['id_usuario'],
        nombre: maps[0]['nombre'],
        apellido: maps[0]['apellido'],
        telefono: maps[0]['telefono'],
        correo: maps[0]['correo'],
        contrasena: maps[0]['contrasena'],
        tipo: maps[0]['tipo'],
        estado: maps[0]['estado'],
        fechaCreacion: maps[0]['fecha_creacion'],
        fechaActualizacion: maps[0]['fecha_actualizacion'],
      );
    } catch (e, st) {
      _logger.log.e(
        'Error al obtener usuario por correo',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<User?> signInWithEmailAndPassword(
    String correo,
    String contrasena,
  ) async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DBHelper.usuariosTable,
        where: 'correo = ? AND contrasena = ?',
        whereArgs: [correo, contrasena],
      );
      if (maps.isEmpty) {
        return null;
      }
      return User(
        id: maps[0]['id_usuario'],
        nombre: maps[0]['nombre'],
        apellido: maps[0]['apellido'],
        telefono: maps[0]['telefono'],
        correo: maps[0]['correo'],
        contrasena: maps[0]['contrasena'],
        tipo: maps[0]['tipo'],
        estado: maps[0]['estado'],
        fechaCreacion: maps[0]['fecha_creacion'],
        fechaActualizacion: maps[0]['fecha_actualizacion'],
      );
    } catch (e, st) {
      _logger.log.e(
        'Error al iniciar sesión con correo y contrasena',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<void> resetPassword(String correo, String contrasena) async {
    try {
      final db = await dbHelper.database;
      await db.update(
        DBHelper.usuariosTable,
        {
          'contrasena': contrasena,
          'fecha_actualizacion': DateTime.now().toIso8601String(),
        },
        where: 'correo = ?',
        whereArgs: [correo],
      );
    } catch (e, st) {
      _logger.log.e(
        'Error al restablecer contrasena',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<bool> hasUsers() async {
    try {
      final db = await dbHelper.database;
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${DBHelper.usuariosTable}'),
      );
      return (count ?? 0) > 0;
    } catch (e, st) {
      _logger.log.e(
        'Error al verificar existencia de usuarios',
        error: e,
        stackTrace: st,
      );
      return false; // Asumimos false para obligar a verificar o porque no hay conexión
    }
  }
}
