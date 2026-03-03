class Venta {
  final int? id; // null antes de insertarse
  final String fecha;
  String numeroFactura;
  final double total;
  final double? montoPagado;
  final double? cambio;
  final String? estado; // 'PENDIENTE', 'COMPLETADA', etc.
  // Campos SAR
  final String? cai;
  final String? rtnCliente;
  final String? nombreCliente;
  final double isv;
  final double subtotal;
  final String rtnEmisor;
  final String razonSocialEmisor;
  final String rangoAutorizado;
  final String fechaLimiteCai;
  final String cajero;
  final String metodoPago;

  Venta({
    this.id,
    required this.fecha,
    required this.numeroFactura,
    required this.total,
    this.montoPagado,
    this.cambio,
    this.estado,
    this.cai,
    this.rtnCliente,
    this.nombreCliente,
    this.isv = 0.0,
    this.subtotal = 0.0,
    required this.rtnEmisor,
    required this.razonSocialEmisor,
    required this.rangoAutorizado,
    required this.fechaLimiteCai,
    required this.cajero,
    required this.metodoPago,
  });

  // Map → Venta
  factory Venta.fromMap(Map<String, dynamic> map) {
    return Venta(
      id: map['id_venta'],
      fecha: map['fecha'],
      numeroFactura: map['numero_factura'],
      total: map['total'],
      montoPagado: map['monto_pagado'],
      cambio: map['cambio'],
      estado: map['estado_fiscal'],
      cai: map['cai'],
      rtnCliente: map['rtn_cliente'],
      nombreCliente: map['nombre_cliente'],
      isv: map['isv'] ?? 0.0,
      subtotal: map['subtotal'] ?? 0.0,
      rtnEmisor: map['rtn_emisor'],
      razonSocialEmisor: map['razon_social_emisor'],
      rangoAutorizado: map['rango_autorizado'],
      fechaLimiteCai: map['fecha_limite_cai'],
      cajero: map['cajero'],
      metodoPago: map['metodo_pago'],
    );
  }

  // Venta → Map
  Map<String, dynamic> toMap() {
    return {
      'id_venta': id,
      'fecha': fecha,
      'numero_factura': numeroFactura,
      'total': total,
      'monto_pagado': montoPagado,
      'cambio': cambio,
      'estado_fiscal': estado,
      'cai': cai,
      'rtn_cliente': rtnCliente,
      'nombre_cliente': nombreCliente,
      'isv': isv,
      'subtotal': subtotal,
      'rtn_emisor': rtnEmisor,
      'razon_social_emisor': razonSocialEmisor,
      'rango_autorizado': rangoAutorizado,
      'fecha_limite_cai': fechaLimiteCai,
      'cajero': cajero,
      'metodo_pago': metodoPago,
    };
  }
}

class VentaCompleta {
  final int id;
  final String fecha;
  final double total;
  final String estado;
  final double montoPagado;
  final double cambio;
  final String numeroFactura;
  final List<DetalleItem> detalles;
  final String cai;
  final String rtnCliente;
  final String nombreCliente;
  final String rangoAutorizado;
  final String rtnEmisor;
  final String razonSocialEmisor;
  final String fechaLimiteCai;
  final double isv;
  final double subtotal;
  final String metodoPago;

  VentaCompleta({
    required this.id,
    required this.fecha,
    required this.total,
    required this.estado,
    required this.detalles,
    required this.montoPagado,
    required this.cambio,
    required this.numeroFactura,
    required this.cai,
    required this.rtnCliente,
    required this.nombreCliente,
    required this.rangoAutorizado,
    required this.rtnEmisor,
    required this.razonSocialEmisor,
    required this.fechaLimiteCai,
    required this.isv,
    required this.subtotal,
    required this.metodoPago,
  });
}

class DetalleItem {
  final String producto;
  final String unidadMedida;
  final int cantidad;
  final double precio;
  final double isv;
  final double subtotal;
  final double descuento;

  DetalleItem({
    required this.producto,
    required this.unidadMedida,
    required this.cantidad,
    required this.precio,
    required this.isv,
    required this.subtotal,
    required this.descuento,
  });
}
