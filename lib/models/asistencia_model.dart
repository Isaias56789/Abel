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
      idAsistencia: json['id_asistencia'] as int? ?? 0,
      idHorario: json['id_horario'] as int? ?? 0,
      idEstado: json['id_estado'] as int? ?? 0,
      fechaAsistencia: DateTime.parse(json['fecha_asistencia'] as String? ?? DateTime.now().toString()),
      horaAsistencia: json['hora_asistencia'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_asistencia': idAsistencia,
      'id_horario': idHorario,
      'id_estado': idEstado,
      'fecha_asistencia': fechaAsistencia.toIso8601String(),
      'hora_asistencia': horaAsistencia,
    };
  }
}