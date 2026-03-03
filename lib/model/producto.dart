import 'package:proyecto_cd2/model/proveedor.dart';

class Producto {
  final String id; // UUID
  final String nombre;
  final int? proveedorId; // FK a proveedores
  final int? categoriaId; // FK a categorias
  final String? unidadMedida;
  final double precio;
  final double costo;
  final int stock;
  final int stockMinimo; // Nuevo campo para stock mínimo
  final double isv;
  final double precioVenta;
  final String? fechaCreacion;
  final String? fechaActualizacion;
  final String? estado;
  int cantidad;
  double descuentoProducto; // Transitorio para el carrito

  Producto({
    required this.id,
    required this.nombre,
    this.proveedorId,
    this.categoriaId,
    this.unidadMedida,
    required this.precio,
    required this.costo,
    this.stock = 0,
    this.stockMinimo = 0, // Default 0
    required this.isv,
    required this.precioVenta,
    this.fechaCreacion,
    this.fechaActualizacion,
    required this.estado,
    this.cantidad = 0,
    this.descuentoProducto = 0.0,
  });

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id_producto'],
      nombre: map['nombre'],
      proveedorId: map['proveedor_id'],
      categoriaId: map['categoria_id'],
      unidadMedida: map['unidad_medida'],
      precio: map['precio'],
      costo: map['costo'],
      stock: map['stock'],
      stockMinimo: map['stock_minimo'] ?? 0,
      isv: map['isv'],
      precioVenta: map['precio_venta'],
      fechaCreacion: map['fecha_creacion'],
      fechaActualizacion: map['fecha_actualizacion'],
      estado: map['estado'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_producto': id,
      'nombre': nombre,
      'proveedor_id': proveedorId,
      'categoria_id': categoriaId,
      'unidad_medida': unidadMedida,
      'precio': precio,
      'costo': costo,
      'stock': stock,
      'stock_minimo': stockMinimo,
      'isv': isv,
      'precio_venta': precioVenta,
      'fecha_creacion': fechaCreacion,
      'fecha_actualizacion': fechaActualizacion,
      'estado': estado,
    };
  }
}

class ProductoProveedor {
  Producto producto;
  Proveedor proveedor;

  ProductoProveedor({required this.producto, required this.proveedor});

  factory ProductoProveedor.fromMap(Map<String, dynamic> map) {
    return ProductoProveedor(
      producto: Producto.fromMap(map),
      proveedor: Proveedor.fromMap(map),
    );
  }
}
