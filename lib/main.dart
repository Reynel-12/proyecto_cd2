import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_cd2/model/app_logger.dart';
import 'package:proyecto_cd2/model/preferences.dart';
import 'package:proyecto_cd2/view/login_view.dart';
import 'package:proyecto_cd2/view/principal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    if (Platform.isWindows) {
      await windowManager.ensureInitialized();

      WindowOptions windowOptions = const WindowOptions(
        size: Size(1920, 1080), // tamaño inicial
        center: true,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
        // fullScreen: true,
      );

      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.maximize(); // abre maximizado
        await windowManager.show();
        await windowManager.focus();
      });
    }
  }

  // Inicializar el logger ANTES de cualquier otra cosa
  await AppLogger.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<Map<String, String>> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');
    String? password = prefs.getString('password');
    String? user = prefs.getString('user');
    String? tipo = prefs.getString('tipo');
    String? estado = prefs.getString('estado');
    String? fullname = prefs.getString('user_fullname');
    return {
      'email': email ?? '',
      'password': password ?? '',
      'user': user ?? '',
      'tipo': tipo ?? '',
      'estado': estado ?? '',
      'user_fullname': fullname ?? '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => TemaProveedor(PreferencesService()),
        ),
      ],
      child: Consumer<TemaProveedor>(
        builder: (context, temaProveedor, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            darkTheme: MisTemas.temaOscuro,
            theme: MisTemas.temaClaro,
            themeMode: temaProveedor.modoTema,
            color: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Colors.black
                : const Color.fromRGBO(244, 243, 243, 1),
            home: FutureBuilder<Map<String, String>>(
              future: loadData(),
              builder: (context, asyncSnapshot) {
                if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  if (asyncSnapshot.hasData &&
                      (asyncSnapshot.data?['email'] ?? '').isNotEmpty &&
                      (asyncSnapshot.data?['password'] ?? '').isNotEmpty &&
                      (asyncSnapshot.data?['user'] ?? '').isNotEmpty &&
                      (asyncSnapshot.data?['tipo'] ?? '').isNotEmpty &&
                      (asyncSnapshot.data?['estado'] ?? '').isNotEmpty &&
                      (asyncSnapshot.data?['user_fullname'] ?? '').isNotEmpty) {
                    return const MyHomePage();
                  } else {
                    return const Login();
                  }
                }
              },
            ),
          );
        },
      ),
    );
  }
}
