class DetalleVenta {
  int? id; // null antes de insertarse
  int? ventaId; // FK
  final String productoId; // FK
  final int cantidad;
  final double precioUnitario;
  final double subtotal;
  final double descuento;
  final String descripcion;
  final double isv;

  DetalleVenta({
    this.id,
    this.ventaId,
    required this.productoId,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    this.descuento = 0.0,
    required this.descripcion,
    this.isv = 0.0,
  });

  // Map → DetalleVenta
  factory DetalleVenta.fromMap(Map<String, dynamic> map) {
    return DetalleVenta(
      id: map['id_detalle_venta'],
      ventaId: map['venta_id'],
      productoId: map['producto_id'],
      cantidad: map['cantidad'],
      precioUnitario: map['precio_unitario'],
      subtotal: map['subtotal'],
      descuento: map['descuento'] ?? 0.0,
      descripcion: map['descripcion'],
      isv: map['isv'] != null ? (map['isv'] as num).toDouble() : 0.0,
    );
  }

  // DetalleVenta → Map
  Map<String, dynamic> toMap() {
    return {
      'id_detalle_venta': id,
      'venta_id': ventaId,
      'producto_id': productoId,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'subtotal': subtotal,
      'descuento': descuento,
      'descripcion': descripcion,
      'isv': isv,
    };
  }
}
