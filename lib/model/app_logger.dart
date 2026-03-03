import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

/// Output personalizado para escribir logs en un archivo
class FileOutput extends LogOutput {
  final File file;
  final bool overrideExisting;

  FileOutput({required this.file, this.overrideExisting = false});

  @override
  void output(OutputEvent event) {
    try {
      // Escribir cada línea del log en el archivo
      for (var line in event.lines) {
        // En modo release, solo escribimos en el archivo
        // En modo debug, también se verá en consola gracias a ConsoleOutput
        file.writeAsStringSync(
          '${DateTime.now().toIso8601String()} - $line\n',
          mode: FileMode.append,
          flush: true, // Asegurar que se escriba inmediatamente
        );
      }
    } catch (e) {
      // Si falla la escritura, al menos intentar mostrar en consola
      debugPrint('Error escribiendo log en archivo: $e');
    }
  }
}

class AppLogger {
  static AppLogger? _instance;

  /// Obtiene la instancia del logger.
  /// IMPORTANTE: Debe llamarse `await AppLogger.init()` en el main() antes de usar esta propiedad.
  static AppLogger get instance {
    if (_instance == null) {
      throw StateError(
        'AppLogger no ha sido inicializado. '
        'Asegúrate de llamar await AppLogger.init() en el main() antes de runApp().',
      );
    }
    return _instance!;
  }

  static Future<void> init() async {
    if (_instance == null) {
      _instance = AppLogger._internal();
      await _instance!._init();
    }
  }

  late Logger _logger;
  File? _logFile;

  AppLogger._internal();

  Future<void> _init() async {
    // Si ya fue inicializado
    if (_logFile != null) return;

    try {
      final dir = await getApplicationSupportDirectory();
      _logFile = File('${dir.path}/app_logs.txt');

      if (!await _logFile!.exists()) {
        await _logFile!.create(recursive: true);
      }

      // Escribir encabezado inicial
      await _logFile!.writeAsString(
        '\n\n========== Nueva sesión: ${DateTime.now()} ========== \n',
        mode: FileMode.append,
        flush: true,
      );

      // Crear el FileOutput personalizado
      final fileOutput = FileOutput(file: _logFile!);

      // Configurar el Logger
      _logger = Logger(
        // ¡CRÍTICO! Usar ProductionFilter para permitir logs en release
        // Por defecto usa DevelopmentFilter que solo funciona con asserts (debug)
        filter: ProductionFilter(),
        level: Level.trace, // Capturar todos los niveles de log
        printer: kReleaseMode
            ? SimplePrinter(printTime: true)
            : PrettyPrinter(
                methodCount: 2,
                errorMethodCount: 8,
                lineLength: 120,
                colors: true,
                printEmojis: true,
                printTime: true,
              ),
        output: kReleaseMode
            ? fileOutput // Solo archivo en release
            : MultiOutput([
                ConsoleOutput(), // Consola en debug
                fileOutput, // Y también archivo en debug
              ]),
      );

      // Log inicial para confirmar que funciona
      _logger.i(
        'Logger inicializado correctamente en modo ${kReleaseMode ? "RELEASE" : "DEBUG"}',
      );
      _logger.i('Archivo de logs: ${_logFile!.path}');
    } catch (e, stackTrace) {
      debugPrint('Error al inicializar logger: $e');
      debugPrint('StackTrace: $stackTrace');
    }
  }

  // Getter para usar el logger
  Logger get log => _logger;

  // Método útil para obtener la ruta del archivo de logs
  String? get logFilePath => _logFile?.path;

  // Método para leer los logs (útil para mostrar en la UI)
  Future<String> readLogs() async {
    if (_logFile == null || !await _logFile!.exists()) {
      return 'No hay logs disponibles';
    }
    try {
      return await _logFile!.readAsString();
    } catch (e) {
      return 'Error al leer logs: $e';
    }
  }

  // Método para limpiar logs antiguos
  Future<void> clearLogs() async {
    if (_logFile != null && await _logFile!.exists()) {
      await _logFile!.writeAsString(
        '========== Logs limpiados: ${DateTime.now()} ========== \n',
        flush: true,
      );
    }
  }
}
