class Categorias {
  int? idCategoria;
  String? nombre;
  String? descripcion;
  String? estado;
  String? fechaCreacion;
  String? fechaActualizacion;

  Categorias({
    this.idCategoria,
    this.nombre,
    this.descripcion,
    this.estado,
    this.fechaCreacion,
    this.fechaActualizacion,
  });

  factory Categorias.fromMap(Map<String, dynamic> map) {
    return Categorias(
      idCategoria: map['id_categoria'],
      nombre: map['nombre'],
      descripcion: map['descripcion'],
      estado: map['estado'],
      fechaCreacion: map['fecha_creacion'],
      fechaActualizacion: map['fecha_actualizacion'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_categoria': idCategoria,
      'nombre': nombre,
      'descripcion': descripcion,
      'estado': estado,
      'fecha_creacion': fechaCreacion,
      'fecha_actualizacion': fechaActualizacion,
    };
  }
}
