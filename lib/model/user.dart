class User {
  int? id;
  final String nombre;
  final String apellido;
  final String telefono;
  final String correo;
  final String contrasena;
  final String tipo;
  final String estado;
  final String fechaCreacion;
  final String fechaActualizacion;

  User({
    this.id,
    required this.nombre,
    required this.apellido,
    required this.telefono,
    required this.correo,
    required this.contrasena,
    required this.tipo,
    required this.estado,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_usuario': id,
      'nombre': nombre,
      'apellido': apellido,
      'telefono': telefono,
      'correo': correo,
      'contrasena': contrasena,
      'tipo': tipo,
      'estado': estado,
      'fecha_creacion': fechaCreacion,
      'fecha_actualizacion': fechaActualizacion,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id_usuario'],
      nombre: map['nombre'],
      apellido: map['apellido'],
      telefono: map['telefono'],
      correo: map['correo'],
      contrasena: map['contrasena'],
      tipo: map['tipo'],
      estado: map['estado'],
      fechaCreacion: map['fecha_creacion'],
      fechaActualizacion: map['fecha_actualizacion'],
    );
  }
}
