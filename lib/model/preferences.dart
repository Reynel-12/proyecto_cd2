import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _keyTemaOscuro = "es_tema_oscuro";

  Future<ThemeMode> obtenerTemaInicial() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool? esTemaOscuro = prefs.getBool(_keyTemaOscuro);
    return esTemaOscuro == true ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> guardarTema(bool esTemaOscuro) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTemaOscuro, esTemaOscuro);
  }

  Future<void> eliminarTema() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyTemaOscuro);
  }
}

class TemaProveedor extends ChangeNotifier {
  TemaProveedor(this._preferencesService) {
    _inicializarTema();
  }

  final PreferencesService _preferencesService;
  ThemeMode _modoTema = ThemeMode.light;

  ThemeMode get modoTema => _modoTema;
  bool get esModoOscuro => _modoTema == ThemeMode.dark;

  Future<void> _inicializarTema() async {
    _modoTema = await _preferencesService.obtenerTemaInicial();
    notifyListeners();
  }

  Future<void> cambiarTema() async {
    // Alternar el estado del tema
    _modoTema = _modoTema == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;

    notifyListeners(); // Notificar a los oyentes sobre el cambio

    // Guardar el estado del tema en preferencias
    if (_modoTema == ThemeMode.dark) {
      await _preferencesService.guardarTema(true);
    } else {
      await _preferencesService.eliminarTema();
    }
  }
}

class MisTemas {
  static final ThemeData temaClaro = ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black),
      bodyMedium: TextStyle(color: Colors.black),
    ),
  );

  static final ThemeData temaOscuro = ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
    ),
  );
}
