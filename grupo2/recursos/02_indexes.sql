-- Active: 1769781403695@@127.0.0.1@5432@hospitaldb
-- Índices para rendimiento analítico y joins

BEGIN;

CREATE INDEX IF NOT EXISTS ix_persona_genero ON persona(id_genero);
CREATE INDEX IF NOT EXISTS ix_persona_ciudad ON persona(ciudad);

CREATE INDEX IF NOT EXISTS ix_paciente_persona ON paciente(id_persona);

CREATE INDEX IF NOT EXISTS ix_personal_persona ON personal(id_persona);
CREATE INDEX IF NOT EXISTS ix_personal_especialidad ON personal(id_especialidad);
CREATE INDEX IF NOT EXISTS ix_personal_turno ON personal(id_turno);
CREATE INDEX IF NOT EXISTS ix_personal_estado_disp ON personal(id_estado_disponibilidad);

CREATE INDEX IF NOT EXISTS ix_cita_paciente ON cita_medica(id_paciente);
CREATE INDEX IF NOT EXISTS ix_cita_personal ON cita_medica(id_personal);
CREATE INDEX IF NOT EXISTS ix_cita_fecha ON cita_medica(fecha_cita);
CREATE INDEX IF NOT EXISTS ix_cita_estado ON cita_medica(id_estado_cita);
CREATE INDEX IF NOT EXISTS ix_cita_fecha_estado ON cita_medica(fecha_cita, id_estado_cita);

CREATE INDEX IF NOT EXISTS ix_pago_cita ON pago(id_cita);
CREATE INDEX IF NOT EXISTS ix_pago_estado ON pago(id_estado_pago);
CREATE INDEX IF NOT EXISTS ix_pago_fecha ON pago(fecha_pago);

CREATE INDEX IF NOT EXISTS ix_diagnostico_cita ON diagnostico(id_cita);
CREATE INDEX IF NOT EXISTS ix_diagnostico_cie10 ON diagnostico(codigo_cie10);
CREATE INDEX IF NOT EXISTS ix_diagnostico_gravedad ON diagnostico(id_gravedad);

CREATE INDEX IF NOT EXISTS ix_diag_proc_diagnostico ON diagnostico_procedimiento(id_diagnostico);
CREATE INDEX IF NOT EXISTS ix_diag_proc_procedimiento ON diagnostico_procedimiento(id_procedimiento);

CREATE INDEX IF NOT EXISTS ix_historial_paciente ON historial_clinico(id_paciente);
CREATE INDEX IF NOT EXISTS ix_historial_fecha ON historial_clinico(fecha_registro);
CREATE INDEX IF NOT EXISTS ix_historial_tipo ON historial_clinico(id_tipo_registro);

CREATE INDEX IF NOT EXISTS ix_receta_diagnostico ON receta(id_diagnostico);

CREATE INDEX IF NOT EXISTS ix_receta_detalle_receta ON receta_detalle(id_receta);
CREATE INDEX IF NOT EXISTS ix_receta_detalle_medicamento ON receta_detalle(id_medicamento);

COMMIT;
