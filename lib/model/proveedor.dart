class Proveedor {
  final int? id; // null cuando todavía no se ha insertado
  final String nombre;
  final String? direccion;
  final String? telefono;
  final String? correo;
  final String? fechaRegistro;
  final String? fechaActualizacion;
  final String? estado;

  Proveedor({
    this.id,
    required this.nombre,
    this.direccion,
    this.telefono,
    this.correo,
    required this.fechaRegistro,
    required this.fechaActualizacion,
    required this.estado,
  });

  // Convertir Map → Objeto
  factory Proveedor.fromMap(Map<String, dynamic> map) {
    return Proveedor(
      id: map['id_proveedor'],
      nombre: map['nombre'],
      direccion: map['direccion'],
      telefono: map['telefono'],
      correo: map['correo'],
      fechaRegistro: map['fecha_registro'],
      fechaActualizacion: map['fecha_actualizacion'],
      estado: map['estado'],
    );
  }

  // Convertir Objeto → Map
  Map<String, dynamic> toMap() {
    return {
      'id_proveedor': id,
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono,
      'correo': correo,
      'fecha_registro': fechaRegistro,
      'fecha_actualizacion': fechaActualizacion,
      'estado': estado,
    };
  }
}
