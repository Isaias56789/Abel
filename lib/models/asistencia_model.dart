class Asistencia {
  final int idAsistencia;
  final int idHorario;
  final int idEstado;
  final DateTime fechaAsistencia;
  final String horaAsistencia;

  Asistencia({
    required this.idAsistencia,
    required this.idHorario,
    required this.idEstado,
    required this.fechaAsistencia,
    required this.horaAsistencia,
  });

  factory Asistencia.fromJson(Map<String, dynamic> json) {
    return Asistencia(
      idAsistencia: json['id_asistencia'] as int? ?? 0, // Handle null case
      idHorario: json['id_horario'] as int? ?? 0,       // Handle null case
      idEstado: json['id_estado'] as int? ?? 0,         // Handle null case
      fechaAsistencia: DateTime.parse(json['fecha_asistencia'] as String? ?? DateTime.now().toString()),
      horaAsistencia: json['hora_asistencia'] as String? ?? '',
    );
  }
}