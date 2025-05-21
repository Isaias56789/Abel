class Horario {
  final int idHorario;
  final String dia;
  final String horaInicio;  // Changed to String
  final String horaFin;     // Changed to String
  final String asignatura;
  final String maestro;
  final String aula;
  final String grupo;
  final String carrera;
  final bool asistenciaRegistrada;
  final int? idEstado;
  final String? estadoAsistencia;
  final String? horaRegistro;
   final int? idAsistencia;

  Horario({
    required this.idHorario,
    required this.dia,
    required this.horaInicio,
    required this.horaFin,
    required this.asignatura,
    required this.maestro,
    required this.aula,
    required this.grupo,
    required this.carrera,
    required this.asistenciaRegistrada,
    this.estadoAsistencia,
    this.horaRegistro,
     this.idAsistencia, 
     this.idEstado,
  });

  factory Horario.fromJson(Map<String, dynamic> json) {
    // Convert numeric times to formatted strings
    String formatTime(dynamic time) {
      if (time == null) return '00:00';
      if (time is String) return time;
      if (time is num) {
        // Convert seconds to HH:MM format
        final hours = (time / 3600).floor();
        final minutes = ((time % 3600) / 60).floor();
        return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
      }
      return time.toString();
    }

    return Horario(
      idHorario: json['id_horario'] as int,
      dia: json['dia'] as String,
      horaInicio: formatTime(json['hora_inicio']),
      horaFin: formatTime(json['hora_fin']),
      asignatura: json['nombre_asignatura'] as String,
      maestro: '${json['maestro_nombre']} ${json['maestro_apellido']}',
      aula: json['aula'] as String,
      grupo: json['grupo'] as String,
      carrera: json['carrera'] as String,
      asistenciaRegistrada: json['asistencia_registrada'] as bool? ?? false,
      estadoAsistencia: json['estado_asistencia'] as String?,
      horaRegistro: json['hora_registro'] as String?, 
      idAsistencia: json['id_asistencia'] as int?,
      idEstado: json['id_estado'],
    );
  }
}