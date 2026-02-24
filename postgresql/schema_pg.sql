-- ================================================================
-- ESQUEMA UNIFICADO: HOSPITAL (PostgreSQL 17)
-- Normalizado en 3FN - Sin ciclos en FK
-- Integra: Grupo 3 (base) + Grupo 2 (catalogos y extensiones)
-- ================================================================

BEGIN;

-- ============================================
-- CATALOGOS (Grupo 2)
-- ============================================

CREATE TABLE IF NOT EXISTS cat_genero (
    id_genero SMALLSERIAL PRIMARY KEY,
    nombre VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS cat_cargo (
    id_cargo SMALLSERIAL PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS cat_turno (
    id_turno SMALLSERIAL PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS cat_estado_disponibilidad (
    id_estado_disponibilidad SMALLSERIAL PRIMARY KEY,
    nombre VARCHAR(40) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS cat_gravedad (
    id_gravedad SMALLSERIAL PRIMARY KEY,
    nombre VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS cat_estado_cita (
    id_estado_cita SMALLSERIAL PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS cat_metodo_pago (
    id_metodo_pago SMALLSERIAL PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS cat_estado_pago (
    id_estado_pago SMALLSERIAL PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS cat_tipo_registro (
    id_tipo_registro SMALLSERIAL PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL UNIQUE
);

-- ============================================
-- TABLAS BASE (Grupo 3)
-- ============================================

CREATE TABLE IF NOT EXISTS zona (
    id_zona SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    ciudad VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS especialidad (
    id_especialidad SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS tipo_diagnostico (
    id_tipo_diagnostico SERIAL PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    categoria VARCHAR(100) NOT NULL
);

-- ============================================
-- TABLAS MAESTRAS
-- ============================================

-- persona: datos basicos de cualquier individuo
-- SIN id_especialidad (3NF: la especialidad pertenece al rol medico, no a la persona)
CREATE TABLE IF NOT EXISTS persona (
    id_persona SERIAL PRIMARY KEY,
    ci VARCHAR(20) NOT NULL,
    nombre VARCHAR(200) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    sexo CHAR(1) NOT NULL CHECK (sexo IN ('M', 'F')),
    direccion VARCHAR(300) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    matricula VARCHAR(50),
    id_zona INTEGER NOT NULL REFERENCES zona(id_zona)
);

-- paciente: rol paciente (persona sin matricula)
CREATE TABLE IF NOT EXISTS paciente (
    id_paciente SERIAL PRIMARY KEY,
    id_persona INTEGER NOT NULL UNIQUE REFERENCES persona(id_persona)
);

-- personal: rol medico/empleado (persona con matricula)
-- La especialidad va AQUI, no en persona (3NF)
CREATE TABLE IF NOT EXISTS personal (
    id_personal SERIAL PRIMARY KEY,
    id_persona INTEGER NOT NULL UNIQUE REFERENCES persona(id_persona),
    id_especialidad INTEGER REFERENCES especialidad(id_especialidad),
    id_cargo SMALLINT NOT NULL REFERENCES cat_cargo(id_cargo),
    id_turno SMALLINT NOT NULL REFERENCES cat_turno(id_turno),
    id_estado_disponibilidad SMALLINT NOT NULL REFERENCES cat_estado_disponibilidad(id_estado_disponibilidad)
);

-- ============================================
-- TABLAS OPERACIONALES (Grupo 3)
-- ============================================

CREATE TABLE IF NOT EXISTS horario_medico (
    id_horario SERIAL PRIMARY KEY,
    dia_semana INTEGER NOT NULL CHECK (dia_semana BETWEEN 1 AND 7),
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    cupo_maximo INTEGER NOT NULL CHECK (cupo_maximo > 0),
    id_persona INTEGER NOT NULL REFERENCES persona(id_persona)
);

CREATE TABLE IF NOT EXISTS cita_medica (
    id_cita SERIAL PRIMARY KEY,
    fecha_registro DATE NOT NULL,
    fecha_cita DATE NOT NULL,
    hora TIME NOT NULL,
    numero_turno INTEGER NOT NULL,
    estado VARCHAR(50) NOT NULL,
    id_paciente INTEGER NOT NULL REFERENCES persona(id_persona),
    id_medico INTEGER NOT NULL REFERENCES persona(id_persona)
);

CREATE TABLE IF NOT EXISTS diagnostico (
    id_diagnostico SERIAL PRIMARY KEY,
    descripcion TEXT NOT NULL,
    observaciones TEXT NOT NULL,
    tipo_procedimiento VARCHAR(100),
    id_cita INTEGER NOT NULL REFERENCES cita_medica(id_cita),
    id_tipo_diagnostico INTEGER NOT NULL REFERENCES tipo_diagnostico(id_tipo_diagnostico)
);

CREATE TABLE IF NOT EXISTS receta (
    id_receta SERIAL PRIMARY KEY,
    medicamentos TEXT NOT NULL,
    indicaciones TEXT NOT NULL,
    id_diagnostico INTEGER NOT NULL REFERENCES diagnostico(id_diagnostico)
);

-- ============================================
-- TABLAS DE EXTENSION (Grupo 2)
-- ============================================

CREATE TABLE IF NOT EXISTS procedimiento_medico (
    id_procedimiento SERIAL PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL UNIQUE,
    costo_base NUMERIC(10,2) NOT NULL CHECK (costo_base >= 0),
    tiempo_estimado_min INTEGER NOT NULL CHECK (tiempo_estimado_min > 0)
);

CREATE TABLE IF NOT EXISTS medicamento (
    id_medicamento SERIAL PRIMARY KEY,
    nombre_medicamento VARCHAR(150) NOT NULL UNIQUE,
    stock_actual INTEGER NOT NULL CHECK (stock_actual >= 0),
    costo_unitario NUMERIC(10,2) NOT NULL CHECK (costo_unitario >= 0)
);

CREATE TABLE IF NOT EXISTS pago (
    id_pago SERIAL PRIMARY KEY,
    id_cita INTEGER NOT NULL UNIQUE REFERENCES cita_medica(id_cita),
    monto_total NUMERIC(10,2) NOT NULL CHECK (monto_total >= 0),
    id_metodo_pago SMALLINT NOT NULL REFERENCES cat_metodo_pago(id_metodo_pago),
    fecha_pago DATE NOT NULL,
    id_estado_pago SMALLINT NOT NULL REFERENCES cat_estado_pago(id_estado_pago)
);

CREATE TABLE IF NOT EXISTS diagnostico_procedimiento (
    id_diag_proc SERIAL PRIMARY KEY,
    id_diagnostico INTEGER NOT NULL REFERENCES diagnostico(id_diagnostico),
    id_procedimiento INTEGER NOT NULL REFERENCES procedimiento_medico(id_procedimiento),
    costo_aplicado NUMERIC(10,2) NOT NULL CHECK (costo_aplicado >= 0),
    tiempo_estimado_min INTEGER NOT NULL CHECK (tiempo_estimado_min > 0),
    UNIQUE (id_diagnostico, id_procedimiento)
);

CREATE TABLE IF NOT EXISTS historial_clinico (
    id_historial SERIAL PRIMARY KEY,
    id_paciente INTEGER NOT NULL REFERENCES paciente(id_paciente),
    fecha_registro DATE NOT NULL,
    id_tipo_registro SMALLINT NOT NULL REFERENCES cat_tipo_registro(id_tipo_registro),
    observaciones TEXT
);

CREATE TABLE IF NOT EXISTS receta_detalle (
    id_receta_detalle SERIAL PRIMARY KEY,
    id_receta INTEGER NOT NULL REFERENCES receta(id_receta),
    id_medicamento INTEGER NOT NULL REFERENCES medicamento(id_medicamento),
    dosis VARCHAR(100) NOT NULL,
    cantidad INTEGER NOT NULL CHECK (cantidad > 0)
);

COMMIT;
