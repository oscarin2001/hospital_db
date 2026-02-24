-- Active: 1769781403695@@127.0.0.1@5432@hospitaldb
-- Esquema normalizado - Hospital BI
-- Ejecutar en la base de datos: hospitaldb

BEGIN;

-- Limpieza previa (si se re-ejecuta)
DROP TABLE IF EXISTS receta_detalle CASCADE;
DROP TABLE IF EXISTS receta CASCADE;
DROP TABLE IF EXISTS medicamento CASCADE;
DROP TABLE IF EXISTS diagnostico_procedimiento CASCADE;
DROP TABLE IF EXISTS procedimiento_medico CASCADE;
DROP TABLE IF EXISTS diagnostico CASCADE;
DROP TABLE IF EXISTS pago CASCADE;
DROP TABLE IF EXISTS cita_medica CASCADE;
DROP TABLE IF EXISTS historial_clinico CASCADE;
DROP TABLE IF EXISTS personal CASCADE;
DROP TABLE IF EXISTS paciente CASCADE;
DROP TABLE IF EXISTS persona CASCADE;

DROP TABLE IF EXISTS cat_tipo_registro CASCADE;
DROP TABLE IF EXISTS cat_estado_pago CASCADE;
DROP TABLE IF EXISTS cat_metodo_pago CASCADE;
DROP TABLE IF EXISTS cat_estado_cita CASCADE;
DROP TABLE IF EXISTS cat_gravedad CASCADE;
DROP TABLE IF EXISTS cat_estado_disponibilidad CASCADE;
DROP TABLE IF EXISTS cat_turno CASCADE;
DROP TABLE IF EXISTS cat_cargo CASCADE;
DROP TABLE IF EXISTS cat_especialidad CASCADE;
DROP TABLE IF EXISTS cat_genero CASCADE;

-- Catálogos
CREATE TABLE cat_genero (
	id_genero SMALLSERIAL PRIMARY KEY,
	nombre VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE cat_especialidad (
	id_especialidad SMALLSERIAL PRIMARY KEY,
	nombre VARCHAR(100) NOT NULL UNIQUE,
	piso VARCHAR(20) NOT NULL
);

CREATE TABLE cat_cargo (
	id_cargo SMALLSERIAL PRIMARY KEY,
	nombre VARCHAR(80) NOT NULL UNIQUE
);

CREATE TABLE cat_turno (
	id_turno SMALLSERIAL PRIMARY KEY,
	nombre VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE cat_estado_disponibilidad (
	id_estado_disponibilidad SMALLSERIAL PRIMARY KEY,
	nombre VARCHAR(40) NOT NULL UNIQUE
);

CREATE TABLE cat_gravedad (
	id_gravedad SMALLSERIAL PRIMARY KEY,
	nombre VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE cat_estado_cita (
	id_estado_cita SMALLSERIAL PRIMARY KEY,
	nombre VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE cat_metodo_pago (
	id_metodo_pago SMALLSERIAL PRIMARY KEY,
	nombre VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE cat_estado_pago (
	id_estado_pago SMALLSERIAL PRIMARY KEY,
	nombre VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE cat_tipo_registro (
	id_tipo_registro SMALLSERIAL PRIMARY KEY,
	nombre VARCHAR(30) NOT NULL UNIQUE
);

-- Entidades maestras
CREATE TABLE persona (
	id_persona BIGSERIAL PRIMARY KEY,
	nombre VARCHAR(150) NOT NULL,
	fecha_nacimiento DATE NOT NULL,
	id_genero SMALLINT NOT NULL REFERENCES cat_genero(id_genero),
	telefono VARCHAR(20),
	zona_residencia VARCHAR(80),
	ciudad VARCHAR(80),
	es_personal BOOLEAN NOT NULL DEFAULT FALSE,
	CONSTRAINT ck_persona_fecha_nacimiento CHECK (fecha_nacimiento <= CURRENT_DATE)
);

CREATE TABLE paciente (
	id_paciente BIGSERIAL PRIMARY KEY,
	id_persona BIGINT NOT NULL UNIQUE REFERENCES persona(id_persona) ON DELETE CASCADE
);

CREATE TABLE personal (
	id_personal BIGSERIAL PRIMARY KEY,
	id_persona BIGINT NOT NULL UNIQUE REFERENCES persona(id_persona) ON DELETE CASCADE,
	id_especialidad SMALLINT REFERENCES cat_especialidad(id_especialidad),
	id_cargo SMALLINT NOT NULL REFERENCES cat_cargo(id_cargo),
	id_turno SMALLINT NOT NULL REFERENCES cat_turno(id_turno),
	id_estado_disponibilidad SMALLINT NOT NULL REFERENCES cat_estado_disponibilidad(id_estado_disponibilidad)
);

-- Entidades transaccionales
CREATE TABLE cita_medica (
	id_cita BIGSERIAL PRIMARY KEY,
	id_paciente BIGINT NOT NULL REFERENCES paciente(id_paciente),
	id_personal BIGINT REFERENCES personal(id_personal),
	fecha_cita DATE NOT NULL,
	hora_cita TIME NOT NULL,
	id_estado_cita SMALLINT NOT NULL REFERENCES cat_estado_cita(id_estado_cita),
	orden_llegada INT,
	hora_llegada TIME,
	hora_atencion TIME,
	temperatura NUMERIC(4,1),
	presion VARCHAR(10),
	tiempo_espera_minutos INT GENERATED ALWAYS AS (
		CASE
			WHEN hora_llegada IS NOT NULL AND hora_atencion IS NOT NULL THEN
				GREATEST(0, FLOOR(EXTRACT(EPOCH FROM (hora_atencion - hora_llegada)) / 60)::INT)
			ELSE NULL
		END
	) STORED,
	CONSTRAINT ck_cita_temperatura CHECK (temperatura IS NULL OR temperatura BETWEEN 34.0 AND 42.0),
	CONSTRAINT ck_cita_presion CHECK (presion IS NULL OR presion ~ '^[0-9]{2,3}/[0-9]{2,3}$')
);

CREATE TABLE pago (
	id_pago BIGSERIAL PRIMARY KEY,
	id_cita BIGINT NOT NULL UNIQUE REFERENCES cita_medica(id_cita) ON DELETE CASCADE,
	monto_total NUMERIC(10,2) NOT NULL,
	id_metodo_pago SMALLINT NOT NULL REFERENCES cat_metodo_pago(id_metodo_pago),
	fecha_pago DATE NOT NULL,
	id_estado_pago SMALLINT NOT NULL REFERENCES cat_estado_pago(id_estado_pago),
	CONSTRAINT ck_pago_monto CHECK (monto_total >= 0)
);

CREATE TABLE diagnostico (
	id_diagnostico BIGSERIAL PRIMARY KEY,
	id_cita BIGINT NOT NULL UNIQUE REFERENCES cita_medica(id_cita) ON DELETE CASCADE,
	descripcion TEXT NOT NULL,
	codigo_cie10 VARCHAR(10) NOT NULL,
	id_gravedad SMALLINT NOT NULL REFERENCES cat_gravedad(id_gravedad)
);

CREATE TABLE procedimiento_medico (
	id_procedimiento BIGSERIAL PRIMARY KEY,
	nombre VARCHAR(120) NOT NULL UNIQUE,
	costo_base NUMERIC(10,2) NOT NULL,
	tiempo_estimado_min INT NOT NULL,
	CONSTRAINT ck_procedimiento_costo CHECK (costo_base >= 0),
	CONSTRAINT ck_procedimiento_tiempo CHECK (tiempo_estimado_min > 0)
);

CREATE TABLE diagnostico_procedimiento (
	id_diag_proc BIGSERIAL PRIMARY KEY,
	id_diagnostico BIGINT NOT NULL REFERENCES diagnostico(id_diagnostico) ON DELETE CASCADE,
	id_procedimiento BIGINT NOT NULL REFERENCES procedimiento_medico(id_procedimiento),
	costo_aplicado NUMERIC(10,2) NOT NULL,
	tiempo_estimado_min INT NOT NULL,
	CONSTRAINT uq_diag_proc UNIQUE (id_diagnostico, id_procedimiento),
	CONSTRAINT ck_diag_proc_costo CHECK (costo_aplicado >= 0),
	CONSTRAINT ck_diag_proc_tiempo CHECK (tiempo_estimado_min > 0)
);

CREATE TABLE historial_clinico (
	id_historial BIGSERIAL PRIMARY KEY,
	id_paciente BIGINT NOT NULL REFERENCES paciente(id_paciente) ON DELETE CASCADE,
	fecha_registro DATE NOT NULL,
	id_tipo_registro SMALLINT NOT NULL REFERENCES cat_tipo_registro(id_tipo_registro),
	observaciones TEXT
);

CREATE TABLE medicamento (
	id_medicamento BIGSERIAL PRIMARY KEY,
	nombre_medicamento VARCHAR(120) NOT NULL UNIQUE,
	stock_actual INT NOT NULL,
	costo_unitario NUMERIC(10,2) NOT NULL,
	CONSTRAINT ck_medicamento_stock CHECK (stock_actual >= 0),
	CONSTRAINT ck_medicamento_costo CHECK (costo_unitario >= 0)
);

CREATE TABLE receta (
	id_receta BIGSERIAL PRIMARY KEY,
	id_diagnostico BIGINT NOT NULL REFERENCES diagnostico(id_diagnostico) ON DELETE CASCADE,
	fecha_receta DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE receta_detalle (
	id_receta_detalle BIGSERIAL PRIMARY KEY,
	id_receta BIGINT NOT NULL REFERENCES receta(id_receta) ON DELETE CASCADE,
	id_medicamento BIGINT NOT NULL REFERENCES medicamento(id_medicamento),
	dosis VARCHAR(50) NOT NULL,
	cantidad INT NOT NULL,
	CONSTRAINT ck_receta_detalle_cantidad CHECK (cantidad > 0)
);

COMMIT;
