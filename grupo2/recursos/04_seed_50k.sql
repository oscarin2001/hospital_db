-- Active: 1769781403695@@127.0.0.1@5432@hospitaldb
-- Carga masiva aproximada a 100k filas totales
-- Ejecutar después de 01_schema.sql, 02_indexes.sql y 03_seed_catalogos.sql

BEGIN;

-- Reinicio de datos transaccionales y maestros dinámicos
TRUNCATE TABLE
  receta_detalle,
  receta,
  diagnostico_procedimiento,
  diagnostico,
  pago,
  cita_medica,
  historial_clinico,
  personal,
  paciente,
  persona
RESTART IDENTITY CASCADE;

-- Parámetros de volumen
-- Total aproximado objetivo: ~100,000 filas (sin contar catálogos)
-- persona 22,000
-- paciente 19,000
-- personal 3,000
-- cita_medica 16,000
-- pago 16,000
-- diagnostico 10,000
-- diagnostico_procedimiento 7,000
-- historial_clinico 4,000
-- receta 2,500
-- receta_detalle 2,500

-- 1) Personas
INSERT INTO persona (
  nombre,
  fecha_nacimiento,
  id_genero,
  telefono,
  zona_residencia,
  ciudad,
  es_personal
)
SELECT
  ('Persona ' || gs)::VARCHAR(150),
  (DATE '1955-01-01' + ((random() * 25000)::INT))::DATE,
  (1 + floor(random() * 3))::SMALLINT,
  ('7' || lpad((floor(random() * 9999999))::TEXT, 7, '0'))::VARCHAR(20),
  ('Zona ' || (1 + floor(random() * 12))::INT)::VARCHAR(80),
  (ARRAY['La Paz','Cochabamba','Santa Cruz','Sucre','Tarija'])[(1 + floor(random() * 5))::INT]::VARCHAR(80),
  (gs <= 3000)
FROM generate_series(1, 22000) AS gs;

-- 2) Pacientes (personas no personal)
INSERT INTO paciente (id_persona)
SELECT id_persona
FROM persona
WHERE es_personal = FALSE
ORDER BY id_persona
LIMIT 19000;

-- 3) Personal (personas marcadas como personal)
INSERT INTO personal (
  id_persona,
  id_especialidad,
  id_cargo,
  id_turno,
  id_estado_disponibilidad
)
SELECT
  p.id_persona,
  (1 + floor(random() * 8))::SMALLINT,
  (1 + floor(random() * 6))::SMALLINT,
  (1 + floor(random() * 3))::SMALLINT,
  (1 + floor(random() * 4))::SMALLINT
FROM persona p
WHERE p.es_personal = TRUE
ORDER BY p.id_persona
LIMIT 3000;

-- 4) Citas médicas
INSERT INTO cita_medica (
  id_paciente,
  id_personal,
  fecha_cita,
  hora_cita,
  id_estado_cita,
  orden_llegada,
  hora_llegada,
  hora_atencion,
  temperatura,
  presion
)
SELECT
  (1 + floor(random() * 19000))::BIGINT,
  (1 + floor(random() * 3000))::BIGINT,
  (CURRENT_DATE - (floor(random() * 730))::INT),
  (TIME '07:00' + ((floor(random() * 660))::TEXT || ' minutes')::INTERVAL)::TIME,
  CASE
    WHEN random() < 0.70 THEN 2 -- Atendida
    WHEN random() < 0.85 THEN 1 -- Agendada
    WHEN random() < 0.95 THEN 3 -- Cancelada
    ELSE 4                      -- No asistió
  END::SMALLINT,
  gs,
  (TIME '07:00' + ((floor(random() * 660))::TEXT || ' minutes')::INTERVAL)::TIME,
  (TIME '07:10' + ((floor(random() * 660))::TEXT || ' minutes')::INTERVAL)::TIME,
  (36.0 + random() * 3.5)::NUMERIC(4,1),
  ((90 + floor(random() * 60))::INT::TEXT || '/' || (60 + floor(random() * 40))::INT::TEXT)::VARCHAR(10)
FROM generate_series(1, 16000) AS gs;

-- 5) Pagos (1 por cita)
INSERT INTO pago (
  id_cita,
  monto_total,
  id_metodo_pago,
  fecha_pago,
  id_estado_pago
)
SELECT
  c.id_cita,
  (50 + random() * 950)::NUMERIC(10,2),
  (1 + floor(random() * 4))::SMALLINT,
  c.fecha_cita,
  CASE
    WHEN c.id_estado_cita = 2 THEN 2
    WHEN c.id_estado_cita = 3 THEN 4
    ELSE 1
  END::SMALLINT
FROM cita_medica c;

-- 6) Diagnóstico (solo para parte de citas atendidas)
INSERT INTO diagnostico (
  id_cita,
  descripcion,
  codigo_cie10,
  id_gravedad
)
SELECT
  c.id_cita,
  ('Diagnóstico clínico generado para cita ' || c.id_cita),
  (ARRAY['J00','J06.9','K29.7','M54.5','I10','E11.9','N39.0','L20.9'])[(1 + floor(random() * 8))::INT],
  (1 + floor(random() * 4))::SMALLINT
FROM cita_medica c
WHERE c.id_estado_cita = 2
ORDER BY c.id_cita
LIMIT 10000;

-- 7) Procedimientos por diagnóstico
INSERT INTO diagnostico_procedimiento (
  id_diagnostico,
  id_procedimiento,
  costo_aplicado,
  tiempo_estimado_min
)
SELECT
  d.id_diagnostico,
  (1 + floor(random() * 8))::BIGINT,
  (40 + random() * 900)::NUMERIC(10,2),
  (10 + floor(random() * 70))::INT
FROM diagnostico d
ORDER BY d.id_diagnostico
LIMIT 7000;

-- 8) Historial clínico
INSERT INTO historial_clinico (
  id_paciente,
  fecha_registro,
  id_tipo_registro,
  observaciones
)
SELECT
  (1 + floor(random() * 18000))::BIGINT,
  (CURRENT_DATE - (floor(random() * 730))::INT),
  (1 + floor(random() * 4))::SMALLINT,
  ('Registro clínico automático #' || gs)
FROM generate_series(1, 4000) AS gs;

-- 9) Recetas
INSERT INTO receta (
  id_diagnostico,
  fecha_receta
)
SELECT
  d.id_diagnostico,
  (CURRENT_DATE - (floor(random() * 365))::INT)
FROM diagnostico d
ORDER BY d.id_diagnostico
LIMIT 2500;

-- 10) Detalle de recetas
INSERT INTO receta_detalle (
  id_receta,
  id_medicamento,
  dosis,
  cantidad
)
SELECT
  r.id_receta,
  (1 + floor(random() * 12))::BIGINT,
  (ARRAY['1 cada 8h','1 cada 12h','1 diaria','2 diarias'])[(1 + floor(random() * 4))::INT],
  (5 + floor(random() * 25))::INT
FROM receta r
ORDER BY r.id_receta
LIMIT 2500;

COMMIT;
