/// Representa una recomendación individual de la API
class RecomendacionCompra {
  final String codigoProducto;
  final int cantidadAComprar;

  RecomendacionCompra({
    required this.codigoProducto,
    required this.cantidadAComprar,
  });

  factory RecomendacionCompra.fromJson(Map<String, dynamic> json) {
    return RecomendacionCompra(
      codigoProducto: json['codigo_producto'] as String,
      cantidadAComprar: (json['cantidad_a_comprar'] as num).toInt(),
    );
  }
}

/// Resultado completo devuelto por la API de inventario óptimo
class InventarioOptimoResultado {
  final String status;
  final double mae;
  final List<RecomendacionCompra> recomendaciones;

  InventarioOptimoResultado({
    required this.status,
    required this.mae,
    required this.recomendaciones,
  });

  factory InventarioOptimoResultado.fromJson(Map<String, dynamic> json) {
    final List<dynamic> recs = json['recomendaciones'] ?? [];
    return InventarioOptimoResultado(
      status: json['status'] as String? ?? 'unknown',
      mae: (json['mae'] as num?)?.toDouble() ?? 0.0,
      recomendaciones: recs
          .map((r) => RecomendacionCompra.fromJson(r))
          .toList(),
    );
  }
}

// --- Excepciones tipadas para manejo de errores en la vista ---

/// La API local no está disponible (ConnectionRefused / timeout)
class ApiNoDisponibleException implements Exception {
  final String mensaje;
  ApiNoDisponibleException([
    this.mensaje = 'No se pudo conectar con la API local.',
  ]);
  @override
  String toString() => mensaje;
}

/// La API respondió con un error HTTP (4xx / 5xx)
class ApiErrorException implements Exception {
  final int statusCode;
  final String mensaje;
  ApiErrorException(this.statusCode, this.mensaje);
  @override
  String toString() => 'Error $statusCode: $mensaje';
}

/// No hay suficientes datos de ventas para generar una predicción
class DatosInsuficientesException implements Exception {
  final String mensaje;
  DatosInsuficientesException([
    this.mensaje =
        'No hay suficientes datos de ventas para generar una predicción.',
  ]);
  @override
  String toString() => mensaje;
}
