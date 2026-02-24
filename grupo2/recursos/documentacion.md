# Documentación Completa - Base de Datos Hospital BI

## Tabla de Contenidos

1. [Introducción](#introducción)
2. [Arquitectura General](#arquitectura-general)
3. [Diccionario de Datos](#diccionario-de-datos)
   - [Tablas de Catálogos](#tablas-de-catálogos)
   - [Tablas Maestras](#tablas-maestras)
   - [Tablas Transaccionales](#tablas-transaccionales)
4. [Relaciones y Dependencias](#relaciones-y-dependencias)
5. [Índices](#índices)
6. [Constraints y Validaciones](#constraints-y-validaciones)
7. [Volumen de Datos](#volumen-de-datos)
8. [Consultas Analíticas](#consultas-analíticas)
9. [Seguridad y Acceso](#seguridad-y-acceso)
10. [Procedimientos de Instalación](#procedimientos-de-instalación)
11. [Validaciones de Integridad](#validaciones-de-integridad)

---

## Introducción

### Propósito
Base de datos normalizada para **Inteligencia de Negocios Hospitalaria** diseñada para soportar análisis de:
- Gestión de citas médicas y tiempos de espera
- Ingresos por patología y método de pago
- Costos operativos por procedimientos médicos
- Distribución de pacientes y personal
- Consumo de medicamentos y recetas
- Historial clínico de pacientes

### Tecnología
- **SGBD**: PostgreSQL 13+
- **Base de datos**: `hospitaldb`
- **Esquema**: `public`
- **Charset**: UTF-8

### Modelo de Datos
- **22 tablas** en total:
  - 10 tablas de catálogos (dimensiones estáticas)
  - 3 tablas maestras (entidades principales)
  - 9 tablas transaccionales (hechos y detalles)

---

## Arquitectura General

### Capas del Modelo

```
┌─────────────────────────────────────────┐
│        CAPA DE CATÁLOGOS (10)           │
│  Dimensiones estáticas y clasificadores │
└─────────────────────────────────────────┘
              ▼
┌─────────────────────────────────────────┐
│        CAPA MAESTRA (3)                 │
│  persona, paciente, personal            │
│  procedimiento_medico, medicamento      │
└─────────────────────────────────────────┘
              ▼
┌─────────────────────────────────────────┐
│     CAPA TRANSACCIONAL (9)              │
│  cita_medica, pago, diagnostico,        │
│  receta, historial_clinico, etc.        │
└─────────────────────────────────────────┘
```

### Flujo de Negocio Principal

1. **Persona** → clasificada como **Paciente** o **Personal**
2. **Paciente** → solicita **Cita Médica** → atendida por **Personal**
3. **Cita** → genera **Diagnóstico** → puede asociar **Procedimientos**
4. **Diagnóstico** → emite **Receta** → con **Medicamentos**
5. **Cita** → genera **Pago** con monto y método
6. **Paciente** → registra **Historial Clínico** continuo

---

## Diccionario de Datos

### Tablas de Catálogos

#### 1. `cat_genero`
**Descripción**: Clasificador de género para personas.

| Columna     | Tipo            | PK | FK | Nulo | Descripción                  |
|-------------|-----------------|----|-------|------|------------------------------|
| id_genero   | SMALLSERIAL     | ✓  |       | NO   | Identificador único          |
| nombre      | VARCHAR(20)     |    |       | NO   | Nombre del género            |

**Constraints**:
- `UNIQUE(nombre)`

**Valores típicos**: Masculino, Femenino, No binario

---

#### 2. `cat_especialidad`
**Descripción**: Especialidades médicas del hospital.

| Columna          | Tipo            | PK | FK | Nulo | Descripción                        |
|------------------|-----------------|----|-------|------|------------------------------------|
| id_especialidad  | SMALLSERIAL     | ✓  |       | NO   | Identificador único                |
| nombre           | VARCHAR(100)    |    |       | NO   | Nombre de la especialidad          |
| piso             | VARCHAR(20)     |    |       | NO   | Ubicación física en el hospital    |

**Constraints**:
- `UNIQUE(nombre)`

**Valores típicos**: Medicina General (Piso 1), Pediatría (Piso 2), Cardiología (Piso 4), etc.

---

#### 3. `cat_cargo`
**Descripción**: Cargos del personal hospitalario.

| Columna    | Tipo            | PK | FK | Nulo | Descripción              |
|------------|-----------------|----|-------|------|--------------------------|
| id_cargo   | SMALLSERIAL     | ✓  |       | NO   | Identificador único      |
| nombre     | VARCHAR(80)     |    |       | NO   | Nombre del cargo         |

**Constraints**:
- `UNIQUE(nombre)`

**Valores típicos**: Médico, Enfermería, Recepción, Laboratorio, Farmacia, Administración

---

#### 4. `cat_turno`
**Descripción**: Turnos de trabajo del personal.

| Columna    | Tipo            | PK | FK | Nulo | Descripción              |
|------------|-----------------|----|-------|------|--------------------------|
| id_turno   | SMALLSERIAL     | ✓  |       | NO   | Identificador único      |
| nombre     | VARCHAR(30)     |    |       | NO   | Nombre del turno         |

**Constraints**:
- `UNIQUE(nombre)`

**Valores típicos**: Mañana, Tarde, Noche

---

#### 5. `cat_estado_disponibilidad`
**Descripción**: Estados de disponibilidad del personal.

| Columna                   | Tipo            | PK | FK | Nulo | Descripción                  |
|---------------------------|-----------------|----|-------|------|------------------------------|
| id_estado_disponibilidad  | SMALLSERIAL     | ✓  |       | NO   | Identificador único          |
| nombre                    | VARCHAR(40)     |    |       | NO   | Nombre del estado            |

**Constraints**:
- `UNIQUE(nombre)`

**Valores típicos**: Disponible, Ocupado, Ausente, Vacaciones

---

#### 6. `cat_gravedad`
**Descripción**: Niveles de gravedad de diagnósticos.

| Columna      | Tipo            | PK | FK | Nulo | Descripción              |
|--------------|-----------------|----|-------|------|--------------------------|
| id_gravedad  | SMALLSERIAL     | ✓  |       | NO   | Identificador único      |
| nombre       | VARCHAR(20)     |    |       | NO   | Nivel de gravedad        |

**Constraints**:
- `UNIQUE(nombre)`

**Valores típicos**: Leve, Moderada, Severa, Crítica

---

#### 7. `cat_estado_cita`
**Descripción**: Estados posibles de una cita médica.

| Columna          | Tipo            | PK | FK | Nulo | Descripción              |
|------------------|-----------------|----|-------|------|--------------------------|
| id_estado_cita   | SMALLSERIAL     | ✓  |       | NO   | Identificador único      |
| nombre           | VARCHAR(30)     |    |       | NO   | Estado de la cita        |

**Constraints**:
- `UNIQUE(nombre)`

**Valores típicos**: Agendada, Atendida, Cancelada, No asistió

---

#### 8. `cat_metodo_pago`
**Descripción**: Métodos de pago aceptados.

| Columna          | Tipo            | PK | FK | Nulo | Descripción              |
|------------------|-----------------|----|-------|------|--------------------------|
| id_metodo_pago   | SMALLSERIAL     | ✓  |       | NO   | Identificador único      |
| nombre           | VARCHAR(30)     |    |       | NO   | Nombre del método        |

**Constraints**:
- `UNIQUE(nombre)`

**Valores típicos**: Efectivo, Tarjeta, Transferencia, Seguro

---

#### 9. `cat_estado_pago`
**Descripción**: Estados de un pago.

| Columna          | Tipo            | PK | FK | Nulo | Descripción              |
|------------------|-----------------|----|-------|------|--------------------------|
| id_estado_pago   | SMALLSERIAL     | ✓  |       | NO   | Identificador único      |
| nombre           | VARCHAR(30)     |    |       | NO   | Estado del pago          |

**Constraints**:
- `UNIQUE(nombre)`

**Valores típicos**: Pendiente, Pagado, Rechazado, Anulado

---

#### 10. `cat_tipo_registro`
**Descripción**: Tipos de registros en historial clínico.

| Columna           | Tipo            | PK | FK | Nulo | Descripción              |
|-------------------|-----------------|----|-------|------|--------------------------|
| id_tipo_registro  | SMALLSERIAL     | ✓  |       | NO   | Identificador único      |
| nombre            | VARCHAR(30)     |    |       | NO   | Tipo de registro         |

**Constraints**:
- `UNIQUE(nombre)`

**Valores típicos**: Ingreso, Alta, Observación, Evolución

---

### Tablas Maestras

#### 11. `persona`
**Descripción**: Entidad base para pacientes y personal. Almacena datos demográficos.

| Columna            | Tipo            | PK | FK                     | Nulo | Descripción                          |
|--------------------|-----------------|----|------------------------|------|--------------------------------------|
| id_persona         | BIGSERIAL       | ✓  |                        | NO   | Identificador único                  |
| nombre             | VARCHAR(150)    |    |                        | NO   | Nombre completo                      |
| fecha_nacimiento   | DATE            |    |                        | NO   | Fecha de nacimiento                  |
| id_genero          | SMALLINT        |    | cat_genero(id_genero)  | NO   | Género de la persona                 |
| telefono           | VARCHAR(20)     |    |                        | SÍ   | Número de teléfono                   |
| zona_residencia    | VARCHAR(80)     |    |                        | SÍ   | Zona de residencia                   |
| ciudad             | VARCHAR(80)     |    |                        | SÍ   | Ciudad de residencia                 |
| es_personal        | BOOLEAN         |    |                        | NO   | Indica si es miembro del personal    |

**Constraints**:
- `CHECK (fecha_nacimiento <= CURRENT_DATE)`
- `DEFAULT es_personal = FALSE`

**Índices**:
- `ix_persona_genero` en `id_genero`
- `ix_persona_ciudad` en `ciudad`

**Relaciones**:
- Relacionada 1:1 con `paciente` (si `es_personal = FALSE`)
- Relacionada 1:1 con `personal` (si `es_personal = TRUE`)

---

#### 12. `paciente`
**Descripción**: Especialización de persona para pacientes del hospital.

| Columna       | Tipo            | PK | FK                     | Nulo | Descripción                  |
|---------------|-----------------|----|------------------------|------|------------------------------|
| id_paciente   | BIGSERIAL       | ✓  |                        | NO   | Identificador único          |
| id_persona    | BIGINT          |    | persona(id_persona)    | NO   | Referencia a persona         |

**Constraints**:
- `UNIQUE(id_persona)`
- `ON DELETE CASCADE` desde persona

**Índices**:
- `ix_paciente_persona` en `id_persona`

**Relaciones**:
- 1 paciente → N citas médicas
- 1 paciente → N registros historial clínico

---

#### 13. `personal`
**Descripción**: Especialización de persona para empleados del hospital.

| Columna                   | Tipo            | PK | FK                                              | Nulo | Descripción                      |
|---------------------------|-----------------|----|------------------------------------------------|------|----------------------------------|
| id_personal               | BIGSERIAL       | ✓  |                                                 | NO   | Identificador único              |
| id_persona                | BIGINT          |    | persona(id_persona)                            | NO   | Referencia a persona             |
| id_especialidad           | SMALLINT        |    | cat_especialidad(id_especialidad)              | SÍ   | Especialidad médica              |
| id_cargo                  | SMALLINT        |    | cat_cargo(id_cargo)                            | NO   | Cargo del personal               |
| id_turno                  | SMALLINT        |    | cat_turno(id_turno)                            | NO   | Turno de trabajo                 |
| id_estado_disponibilidad  | SMALLINT        |    | cat_estado_disponibilidad(id_estado_disponibilidad) | NO   | Estado de disponibilidad actual  |

**Constraints**:
- `UNIQUE(id_persona)`
- `ON DELETE CASCADE` desde persona

**Índices**:
- `ix_personal_persona` en `id_persona`
- `ix_personal_especialidad` en `id_especialidad`
- `ix_personal_turno` en `id_turno`
- `ix_personal_estado_disp` en `id_estado_disponibilidad`

**Relaciones**:
- 1 personal → N citas médicas (como médico tratante)

---

#### 14. `procedimiento_medico`
**Descripción**: Catálogo de procedimientos médicos con costos base.

| Columna               | Tipo            | PK | FK | Nulo | Descripción                      |
|-----------------------|-----------------|----|-------|------|----------------------------------|
| id_procedimiento      | BIGSERIAL       | ✓  |       | NO   | Identificador único              |
| nombre                | VARCHAR(120)    |    |       | NO   | Nombre del procedimiento         |
| costo_base            | NUMERIC(10,2)   |    |       | NO   | Costo estándar del procedimiento |
| tiempo_estimado_min   | INT             |    |       | NO   | Duración estimada en minutos     |

**Constraints**:
- `UNIQUE(nombre)`
- `CHECK (costo_base >= 0)`
- `CHECK (tiempo_estimado_min > 0)`

**Valores típicos**: Radiografía ($120, 20min), Electrocardiograma ($150, 25min), Tomografía ($550, 45min)

---

#### 15. `medicamento`
**Descripción**: Inventario de medicamentos disponibles.

| Columna             | Tipo            | PK | FK | Nulo | Descripción                  |
|---------------------|-----------------|----|-------|------|------------------------------|
| id_medicamento      | BIGSERIAL       | ✓  |       | NO   | Identificador único          |
| nombre_medicamento  | VARCHAR(120)    |    |       | NO   | Nombre del medicamento       |
| stock_actual        | INT             |    |       | NO   | Cantidad en inventario       |
| costo_unitario      | NUMERIC(10,2)   |    |       | NO   | Costo por unidad             |

**Constraints**:
- `UNIQUE(nombre_medicamento)`
- `CHECK (stock_actual >= 0)`
- `CHECK (costo_unitario >= 0)`

**Índices**:
- Ninguno adicional (búsquedas por nombre usan UNIQUE index)

---

### Tablas Transaccionales

#### 16. `cita_medica`
**Descripción**: Registro de citas médicas agendadas y atendidas.

| Columna                  | Tipo            | PK | FK                            | Nulo | Descripción                          |
|--------------------------|-----------------|----|-------------------------------|------|--------------------------------------|
| id_cita                  | BIGSERIAL       | ✓  |                               | NO   | Identificador único                  |
| id_paciente              | BIGINT          |    | paciente(id_paciente)         | NO   | Paciente de la cita                  |
| id_personal              | BIGINT          |    | personal(id_personal)         | SÍ   | Personal que atiende                 |
| fecha_cita               | DATE            |    |                               | NO   | Fecha programada                     |
| hora_cita                | TIME            |    |                               | NO   | Hora programada                      |
| id_estado_cita           | SMALLINT        |    | cat_estado_cita(id_estado_cita) | NO   | Estado de la cita                    |
| orden_llegada            | INT             |    |                               | SÍ   | Orden de llegada del paciente        |
| hora_llegada             | TIME            |    |                               | SÍ   | Hora real de llegada                 |
| hora_atencion            | TIME            |    |                               | SÍ   | Hora de inicio de atención           |
| temperatura              | NUMERIC(4,1)    |    |                               | SÍ   | Temperatura corporal (°C)            |
| presion                  | VARCHAR(10)     |    |                               | SÍ   | Presión arterial (sistólica/diastólica) |
| tiempo_espera_minutos    | INT             |    |                               | SÍ   | **COLUMNA GENERADA** (hora_atencion - hora_llegada) |

**Constraints**:
- `CHECK (temperatura IS NULL OR temperatura BETWEEN 34.0 AND 42.0)`
- `CHECK (presion IS NULL OR presion ~ '^[0-9]{2,3}/[0-9]{2,3}$')`
- `GENERATED ALWAYS AS (...) STORED` para `tiempo_espera_minutos`

**Índices**:
- `ix_cita_paciente` en `id_paciente`
- `ix_cita_personal` en `id_personal`
- `ix_cita_fecha` en `fecha_cita`
- `ix_cita_estado` en `id_estado_cita`
- `ix_cita_fecha_estado` compuesto en `(fecha_cita, id_estado_cita)`

**Relaciones**:
- 1 cita → 1 pago (opcional)
- 1 cita → 1 diagnóstico (opcional)

---

#### 17. `pago`
**Descripción**: Pagos asociados a citas médicas.

| Columna          | Tipo            | PK | FK                              | Nulo | Descripción                  |
|------------------|-----------------|----|--------------------------------|------|------------------------------|
| id_pago          | BIGSERIAL       | ✓  |                                 | NO   | Identificador único          |
| id_cita          | BIGINT          |    | cita_medica(id_cita)           | NO   | Cita relacionada             |
| monto_total      | NUMERIC(10,2)   |    |                                 | NO   | Monto total del pago         |
| id_metodo_pago   | SMALLINT        |    | cat_metodo_pago(id_metodo_pago) | NO   | Método de pago usado         |
| fecha_pago       | DATE            |    |                                 | NO   | Fecha del pago               |
| id_estado_pago   | SMALLINT        |    | cat_estado_pago(id_estado_pago) | NO   | Estado del pago              |

**Constraints**:
- `UNIQUE(id_cita)` — una cita tiene máximo un pago
- `CHECK (monto_total >= 0)`
- `ON DELETE CASCADE` desde cita_medica

**Índices**:
- `ix_pago_cita` en `id_cita`
- `ix_pago_estado` en `id_estado_pago`
- `ix_pago_fecha` en `fecha_pago`

**Relaciones**:
- N pagos → 1 método de pago
- N pagos → 1 estado de pago

---

#### 18. `diagnostico`
**Descripción**: Diagnósticos médicos emitidos en citas.

| Columna          | Tipo            | PK | FK                            | Nulo | Descripción                      |
|------------------|-----------------|----|-------------------------------|------|----------------------------------|
| id_diagnostico   | BIGSERIAL       | ✓  |                               | NO   | Identificador único              |
| id_cita          | BIGINT          |    | cita_medica(id_cita)          | NO   | Cita donde se emitió             |
| descripcion      | TEXT            |    |                               | NO   | Descripción detallada            |
| codigo_cie10     | VARCHAR(10)     |    |                               | NO   | Código CIE-10 del diagnóstico    |
| id_gravedad      | SMALLINT        |    | cat_gravedad(id_gravedad)     | NO   | Nivel de gravedad                |

**Constraints**:
- `UNIQUE(id_cita)` — una cita tiene máximo un diagnóstico
- `ON DELETE CASCADE` desde cita_medica

**Índices**:
- `ix_diagnostico_cita` en `id_cita`
- `ix_diagnostico_cie10` en `codigo_cie10`
- `ix_diagnostico_gravedad` en `id_gravedad`

**Relaciones**:
- 1 diagnóstico → N procedimientos (a través de `diagnostico_procedimiento`)
- 1 diagnóstico → N recetas

---

#### 19. `diagnostico_procedimiento`
**Descripción**: Relación N:M entre diagnósticos y procedimientos médicos aplicados.

| Columna               | Tipo            | PK | FK                                      | Nulo | Descripción                          |
|-----------------------|-----------------|----|----------------------------------------|------|--------------------------------------|
| id_diag_proc          | BIGSERIAL       | ✓  |                                         | NO   | Identificador único                  |
| id_diagnostico        | BIGINT          |    | diagnostico(id_diagnostico)            | NO   | Diagnóstico relacionado              |
| id_procedimiento      | BIGINT          |    | procedimiento_medico(id_procedimiento) | NO   | Procedimiento aplicado               |
| costo_aplicado        | NUMERIC(10,2)   |    |                                         | NO   | Costo real aplicado (puede variar)   |
| tiempo_estimado_min   | INT             |    |                                         | NO   | Tiempo estimado del procedimiento    |

**Constraints**:
- `UNIQUE(id_diagnostico, id_procedimiento)` — un procedimiento no se repite por diagnóstico
- `CHECK (costo_aplicado >= 0)`
- `CHECK (tiempo_estimado_min > 0)`
- `ON DELETE CASCADE` desde diagnostico

**Índices**:
- `ix_diag_proc_diagnostico` en `id_diagnostico`
- `ix_diag_proc_procedimiento` en `id_procedimiento`

**Relaciones**:
- Tabla asociativa entre `diagnostico` y `procedimiento_medico`

---

#### 20. `historial_clinico`
**Descripción**: Registros históricos del paciente (ingresos, altas, observaciones).

| Columna           | Tipo            | PK | FK                                  | Nulo | Descripción                  |
|-------------------|-----------------|----|-------------------------------------|------|------------------------------|
| id_historial      | BIGSERIAL       | ✓  |                                      | NO   | Identificador único          |
| id_paciente       | BIGINT          |    | paciente(id_paciente)               | NO   | Paciente relacionado         |
| fecha_registro    | DATE            |    |                                      | NO   | Fecha del registro           |
| id_tipo_registro  | SMALLINT        |    | cat_tipo_registro(id_tipo_registro) | NO   | Tipo de registro             |
| observaciones     | TEXT            |    |                                      | SÍ   | Notas del registro           |

**Constraints**:
- `ON DELETE CASCADE` desde paciente

**Índices**:
- `ix_historial_paciente` en `id_paciente`
- `ix_historial_fecha` en `fecha_registro`
- `ix_historial_tipo` en `id_tipo_registro`

**Relaciones**:
- N registros → 1 paciente

---

#### 21. `receta`
**Descripción**: Recetas médicas emitidas a partir de un diagnóstico.

| Columna          | Tipo            | PK | FK                              | Nulo | Descripción                  |
|------------------|-----------------|----|--------------------------------|------|------------------------------|
| id_receta        | BIGSERIAL       | ✓  |                                 | NO   | Identificador único          |
| id_diagnostico   | BIGINT          |    | diagnostico(id_diagnostico)    | NO   | Diagnóstico que genera receta|
| fecha_receta     | DATE            |    |                                 | NO   | Fecha de emisión             |

**Constraints**:
- `ON DELETE CASCADE` desde diagnostico
- `DEFAULT fecha_receta = CURRENT_DATE`

**Índices**:
- `ix_receta_diagnostico` en `id_diagnostico`

**Relaciones**:
- 1 receta → N detalles de receta (medicamentos)

---

#### 22. `receta_detalle`
**Descripción**: Detalle de medicamentos en una receta.

| Columna            | Tipo            | PK | FK                              | Nulo | Descripción                  |
|--------------------|-----------------|----|--------------------------------|------|------------------------------|
| id_receta_detalle  | BIGSERIAL       | ✓  |                                 | NO   | Identificador único          |
| id_receta          | BIGINT          |    | receta(id_receta)              | NO   | Receta relacionada           |
| id_medicamento     | BIGINT          |    | medicamento(id_medicamento)    | NO   | Medicamento prescrito        |
| dosis              | VARCHAR(50)     |    |                                 | NO   | Dosis (ej: "1 cada 8 horas") |
| cantidad           | INT             |    |                                 | NO   | Cantidad a dispensar         |

**Constraints**:
- `CHECK (cantidad > 0)`
- `ON DELETE CASCADE` desde receta

**Índices**:
- `ix_receta_detalle_receta` en `id_receta`
- `ix_receta_detalle_medicamento` en `id_medicamento`

**Relaciones**:
- N detalles → 1 receta
- N detalles → 1 medicamento

---

## Relaciones y Dependencias

### Diagrama de Dependencias (vista simplificada)

```
cat_genero ───┐
              ├──→ persona ──┬──→ paciente ──┬──→ cita_medica ──┬──→ pago
cat_especialidad ─┤           │               │                  │
cat_cargo ────────┤           │               ├──→ historial_clinico
cat_turno ────────┤           │               │
cat_estado_disp ──┤           │               └──→ diagnostico ──┬──→ diagnostico_procedimiento
                  └──→ personal ──────────────┘                  │       ↑
                                                                  └──→ receta ──→ receta_detalle
                                                                           │              │
cat_gravedad ────────────────────────────────────────────────────────────┘              │
cat_estado_cita ─────────────────────────────────────────────────────────────────────┘
cat_metodo_pago ──→ pago                                                                 │
cat_estado_pago ──→ pago                                                                 │
cat_tipo_registro ──→ historial_clinico                                                  │
                                                                                         │
procedimiento_medico ─────────────────────────────────────────────────────────────────┘
medicamento ──────────────────────────────────────────────────────────────────────────┘
```

### Cascadas ON DELETE

Las siguientes relaciones tienen `ON DELETE CASCADE`:

- `persona` → `paciente` y `personal` (eliminar persona elimina su rol)
- `cita_medica` → `pago`, `diagnostico` (eliminar cita elimina transacciones asociadas)
- `diagnostico` → `diagnostico_procedimiento`, `receta`
- `receta` → `receta_detalle`
- `paciente` → `historial_clinico`

---

## Índices

### Índices de Integridad Referencial (FK)

| Tabla                       | Índice                          | Columnas                      | Propósito                     |
|-----------------------------|---------------------------------|-------------------------------|-------------------------------|
| persona                     | ix_persona_genero               | id_genero                     | JOIN con cat_genero           |
| persona                     | ix_persona_ciudad               | ciudad                        | Filtros por ciudad            |
| paciente                    | ix_paciente_persona             | id_persona                    | JOIN con persona              |
| personal                    | ix_personal_persona             | id_persona                    | JOIN con persona              |
| personal                    | ix_personal_especialidad        | id_especialidad               | JOIN con cat_especialidad     |
| personal                    | ix_personal_turno               | id_turno                      | Filtros por turno             |
| personal                    | ix_personal_estado_disp         | id_estado_disponibilidad      | Filtros por disponibilidad    |
| cita_medica                 | ix_cita_paciente                | id_paciente                   | JOIN con paciente             |
| cita_medica                 | ix_cita_personal                | id_personal                   | JOIN con personal             |
| cita_medica                 | ix_cita_fecha                   | fecha_cita                    | Filtros temporales            |
| cita_medica                 | ix_cita_estado                  | id_estado_cita                | Filtros por estado            |
| cita_medica                 | ix_cita_fecha_estado            | fecha_cita, id_estado_cita    | Consultas analíticas          |
| pago                        | ix_pago_cita                    | id_cita                       | JOIN con cita_medica          |
| pago                        | ix_pago_estado                  | id_estado_pago                | Filtros por estado            |
| pago                        | ix_pago_fecha                   | fecha_pago                    | Informes financieros          |
| diagnostico                 | ix_diagnostico_cita             | id_cita                       | JOIN con cita_medica          |
| diagnostico                 | ix_diagnostico_cie10            | codigo_cie10                  | Agrupaciones por patología    |
| diagnostico                 | ix_diagnostico_gravedad         | id_gravedad                   | Filtros por gravedad          |
| diagnostico_procedimiento   | ix_diag_proc_diagnostico        | id_diagnostico                | JOIN con diagnostico          |
| diagnostico_procedimiento   | ix_diag_proc_procedimiento      | id_procedimiento              | JOIN con procedimiento_medico |
| historial_clinico           | ix_historial_paciente           | id_paciente                   | JOIN con paciente             |
| historial_clinico           | ix_historial_fecha              | fecha_registro                | Filtros temporales            |
| historial_clinico           | ix_historial_tipo               | id_tipo_registro              | Filtros por tipo              |
| receta                      | ix_receta_diagnostico           | id_diagnostico                | JOIN con diagnostico          |
| receta_detalle              | ix_receta_detalle_receta        | id_receta                     | JOIN con receta               |
| receta_detalle              | ix_receta_detalle_medicamento   | id_medicamento                | JOIN con medicamento          |

### Índices Únicos (UNIQUE)

Todos los catálogos tienen `UNIQUE(nombre)`:
- cat_genero, cat_especialidad, cat_cargo, cat_turno, cat_estado_disponibilidad, cat_gravedad, cat_estado_cita, cat_metodo_pago, cat_estado_pago, cat_tipo_registro

Tablas maestras y transaccionales:
- `persona.id_persona` → `paciente.id_persona` (UNIQUE)
- `persona.id_persona` → `personal.id_persona` (UNIQUE)
- `procedimiento_medico.nombre` (UNIQUE)
- `medicamento.nombre_medicamento` (UNIQUE)
- `cita_medica.id_cita` → `pago.id_cita` (UNIQUE)
- `cita_medica.id_cita` → `diagnostico.id_cita` (UNIQUE)
- `diagnostico_procedimiento(id_diagnostico, id_procedimiento)` (UNIQUE compuesto)

---

## Constraints y Validaciones

### Constraints CHECK

| Tabla                     | Constraint                        | Validación                                           |
|---------------------------|-----------------------------------|------------------------------------------------------|
| persona                   | ck_persona_fecha_nacimiento       | `fecha_nacimiento <= CURRENT_DATE`                   |
| cita_medica               | ck_cita_temperatura               | `temperatura BETWEEN 34.0 AND 42.0`                  |
| cita_medica               | ck_cita_presion                   | `presion ~ '^[0-9]{2,3}/[0-9]{2,3}$'`               |
| pago                      | ck_pago_monto                     | `monto_total >= 0`                                   |
| procedimiento_medico      | ck_procedimiento_costo            | `costo_base >= 0`                                    |
| procedimiento_medico      | ck_procedimiento_tiempo           | `tiempo_estimado_min > 0`                            |
| diagnostico_procedimiento | ck_diag_proc_costo                | `costo_aplicado >= 0`                                |
| diagnostico_procedimiento | ck_diag_proc_tiempo               | `tiempo_estimado_min > 0`                            |
| medicamento               | ck_medicamento_stock              | `stock_actual >= 0`                                  |
| medicamento               | ck_medicamento_costo              | `costo_unitario >= 0`                                |
| receta_detalle            | ck_receta_detalle_cantidad        | `cantidad > 0`                                       |

### Columnas Generadas (GENERATED STORED)

- **`cita_medica.tiempo_espera_minutos`**:
  ```sql
  GENERATED ALWAYS AS (
    CASE
      WHEN hora_llegada IS NOT NULL AND hora_atencion IS NOT NULL THEN
        GREATEST(0, FLOOR(EXTRACT(EPOCH FROM (hora_atencion - hora_llegada)) / 60)::INT)
      ELSE NULL
    END
  ) STORED
  ```
  Calcula automáticamente el tiempo de espera del paciente en minutos.

### Defaults

- `persona.es_personal` → `FALSE`
- `receta.fecha_receta` → `CURRENT_DATE`

---

## Volumen de Datos

### Distribución Objetivo (script `04_seed_50k.sql`)

| Tabla                       | Filas Objetivo | Descripción                                          |
|-----------------------------|----------------|------------------------------------------------------|
| persona                     | 22,000         | Pool de pacientes y personal                         |
| paciente                    | 19,000         | Pacientes registrados                                |
| personal                    | 3,000          | Empleados del hospital                               |
| cita_medica                 | 16,000         | Citas agendadas/atendidas                            |
| pago                        | 16,000         | Pagos asociados a citas                              |
| diagnostico                 | 10,000         | Diagnósticos emitidos                                |
| diagnostico_procedimiento   | 7,000          | Procedimientos aplicados a diagnósticos              |
| historial_clinico           | 4,000          | Registros históricos de pacientes                    |
| receta                      | 2,500          | Recetas médicas                                      |
| receta_detalle              | 2,500          | Medicamentos en recetas                              |
| **TOTAL TRANSACCIONAL**     | **~102,000**   | Aproximado (sin contar catálogos)                    |

### Catálogos (datos fijos)

| Catálogo                        | Filas |
|---------------------------------|-------|
| cat_genero                      | 3     |
| cat_especialidad                | 8     |
| cat_cargo                       | 6     |
| cat_turno                       | 3     |
| cat_estado_disponibilidad       | 4     |
| cat_gravedad                    | 4     |
| cat_estado_cita                 | 4     |
| cat_metodo_pago                 | 4     |
| cat_estado_pago                 | 4     |
| cat_tipo_registro               | 4     |
| procedimiento_medico (maestro)  | 8     |
| medicamento (maestro)           | 12    |

### Generación de Datos

Los datos se generan mediante:
```sql
generate_series(1, N)
```
Con asignaciones aleatorias para:
- Género (random 1-3)
- Fechas de nacimiento (1955-2023)
- Ciudades (La Paz, Cochabamba, Santa Cruz, Sucre, Tarija)
- Temperaturas (35.5 - 39.5°C)
- Presiones (100-140 / 60-90 mmHg)
- Códigos CIE-10 (A00-Z99 simulados)

---

## Consultas Analíticas

### 1. Patologías por Ingresos Totales

**Objetivo**: Identificar diagnósticos que generan más ingresos.

```sql
SELECT
  d.id_diagnostico,
  d.codigo_cie10,
  d.descripcion,
  COALESCE(SUM(p.monto_total),0)::numeric(18,2) AS total_ingresos,
  COUNT(DISTINCT d.id_cita) AS citas_con_diagnostico
FROM diagnostico d
LEFT JOIN pago p ON p.id_cita = d.id_cita
GROUP BY d.id_diagnostico, d.codigo_cie10, d.descripcion
ORDER BY total_ingresos DESC
LIMIT 50;
```

### 2. Patologías por Costo Operativo

**Objetivo**: Identificar diagnósticos con mayor costo en procedimientos.

```sql
SELECT
  d.id_diagnostico,
  d.codigo_cie10,
  d.descripcion,
  COUNT(dp.id_procedimiento) AS procedimientos_relacionados,
  COALESCE(SUM(pm.costo_base),0)::numeric(18,2) AS total_costo_procedimientos
FROM diagnostico d
LEFT JOIN diagnostico_procedimiento dp ON dp.id_diagnostico = d.id_diagnostico
LEFT JOIN procedimiento_medico pm ON pm.id_procedimiento = dp.id_procedimiento
GROUP BY d.id_diagnostico, d.codigo_cie10, d.descripcion
ORDER BY total_costo_procedimientos DESC
LIMIT 50;
```

### 3. Tiempo de Espera Promedio por Especialidad

```sql
SELECT
  e.nombre AS especialidad,
  COUNT(*) AS total_citas,
  ROUND(AVG(c.tiempo_espera_minutos),2) AS tiempo_espera_promedio_min,
  MAX(c.tiempo_espera_minutos) AS tiempo_espera_max_min
FROM cita_medica c
JOIN personal p ON p.id_personal = c.id_personal
JOIN cat_especialidad e ON e.id_especialidad = p.id_especialidad
WHERE c.tiempo_espera_minutos IS NOT NULL
GROUP BY e.nombre
ORDER BY tiempo_espera_promedio_min DESC;
```

### 4. Distribución de Pagos por Método

```sql
SELECT
  mp.nombre AS metodo_pago,
  COUNT(*) AS cantidad_pagos,
  SUM(p.monto_total)::numeric(18,2) AS total_ingresos,
  ROUND(AVG(p.monto_total),2) AS monto_promedio
FROM pago p
JOIN cat_metodo_pago mp ON mp.id_metodo_pago = p.id_metodo_pago
GROUP BY mp.nombre
ORDER BY total_ingresos DESC;
```

### 5. Top 10 Medicamentos Más Recetados

```sql
SELECT
  m.nombre_medicamento,
  COUNT(*) AS veces_recetado,
  SUM(rd.cantidad) AS cantidad_total_dispensada,
  m.stock_actual
FROM receta_detalle rd
JOIN medicamento m ON m.id_medicamento = rd.id_medicamento
GROUP BY m.id_medicamento, m.nombre_medicamento, m.stock_actual
ORDER BY veces_recetado DESC
LIMIT 10;
```

---

## Seguridad y Acceso

### Usuario de Solo Lectura (`lector`)

**Propósito**: Acceso seguro en LAN para consultas analíticas sin permisos de modificación.

**Creación** (script `06_readonly_user.sql`):
```sql
CREATE ROLE lector LOGIN PASSWORD 'lector123456';
GRANT CONNECT ON DATABASE hospitaldb TO lector;
GRANT USAGE ON SCHEMA public TO lector;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO lector;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO lector;
REVOKE CREATE ON SCHEMA public FROM lector;
```

**Permisos**:
- ✅ SELECT en todas las tablas
- ✅ CONNECT a `hospitaldb`
- ❌ INSERT, UPDATE, DELETE
- ❌ CREATE objetos

### Configuración de Acceso Remoto

#### 1. Habilitar escucha en red
Editar `postgresql.conf`:
```ini
listen_addresses = '*'
```

#### 2. Configurar autenticación
Editar `pg_hba.conf`:
```
# Permitir acceso desde red local
host    hospitaldb    lector    192.168.1.0/24    md5
host    hospitaldb    lector    172.16.0.0/16     md5
```

#### 3. Recargar configuración
```sql
SELECT pg_reload_conf();
```

#### 4. Firewall (Windows)
```powershell
netsh advfirewall firewall add rule name="PostgreSQL" dir=in action=allow protocol=TCP localport=5432
```

### Conexión SSH Tunnel (opcional)

Para pgAdmin desde equipo remoto:
```bash
ssh -L 5432:localhost:5432 usuario@servidor_postgresql
```

---

## Procedimientos de Instalación

### Orden de Ejecución de Scripts

```bash
# 1. Crear base de datos (si no existe)
createdb -U postgres hospitaldb

# 2. Ejecutar scripts en orden
psql -U postgres -d hospitaldb -f recursos/01_schema.sql
psql -U postgres -d hospitaldb -f recursos/02_indexes.sql
psql -U postgres -d hospitaldb -f recursos/03_seed_catalogos.sql
psql -U postgres -d hospitaldb -f recursos/04_seed_50k.sql
psql -U postgres -d hospitaldb -f recursos/05_validaciones.sql
psql -U postgres -d hospitaldb -f recursos/06_readonly_user.sql
```

### Desde VS Code (con extensión Database Client)

1. Conectar a `hospitaldb`
2. Abrir cada script en orden
3. Ejecutar (Ctrl+E o Run Selected Query)
4. Verificar log de ejecución

### Desde pgAdmin 4

1. Crear base `hospitaldb`
2. Tools → Query Tool
3. Abrir script → Ejecutar (F5)
4. Repetir para cada archivo

---

## Validaciones de Integridad

### Script `05_validaciones.sql`

#### 1. Conteo por Tabla
Verifica volúmenes cargados:
```sql
SELECT 'persona' AS tabla, COUNT(*) AS total FROM persona
UNION ALL SELECT 'paciente', COUNT(*) FROM paciente
-- ... (otras tablas)
ORDER BY tabla;
```

#### 2. Total General
```sql
SELECT
  (SUM de conteos individuales) AS total_general_aprox;
```
Objetivo: ~100,000 filas.

#### 3. Orfandad de FK
Detecta registros huérfanos:
```sql
SELECT COUNT(*) AS citas_sin_paciente
FROM cita_medica c
LEFT JOIN paciente p ON p.id_paciente = c.id_paciente
WHERE p.id_paciente IS NULL;
```
Resultado esperado: **0** en todas.

#### 4. Calidad de Datos Clínicos
```sql
SELECT
  COUNT(*) FILTER (WHERE temperatura < 34 OR temperatura > 42) AS temp_fuera_rango,
  COUNT(*) FILTER (WHERE presion !~ '^[0-9]{2,3}/[0-9]{2,3}$') AS presion_formato_invalido
FROM cita_medica;
```
Resultado esperado: **0, 0**.

#### 5. Distribución Analítica
```sql
-- Estados de citas
SELECT ec.nombre, COUNT(*) FROM cita_medica c
JOIN cat_estado_cita ec ON ec.id_estado_cita = c.id_estado_cita
GROUP BY ec.nombre;

-- Top 10 CIE-10
SELECT codigo_cie10, COUNT(*) FROM diagnostico
GROUP BY codigo_cie10
ORDER BY COUNT(*) DESC LIMIT 10;
```

---

## Consultas de Metadatos

### Script `08-documentacion.sql`

#### 1. Listar Todas las Tablas
```sql
SELECT
  schemaname,
  tablename,
  tableowner
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
```

#### 2. Columnas con Tipos y Constraints
```sql
SELECT
  c.table_name,
  c.column_name,
  c.data_type,
  c.character_maximum_length,
  c.is_nullable,
  CASE WHEN pk.column_name IS NOT NULL THEN 'PK' ELSE '' END AS es_pk,
  CASE WHEN fk.column_name IS NOT NULL THEN 'FK' ELSE '' END AS es_fk
FROM information_schema.columns c
LEFT JOIN (
  SELECT ku.table_name, ku.column_name
  FROM information_schema.table_constraints tc
  JOIN information_schema.key_column_usage ku
    ON tc.constraint_name = ku.constraint_name
  WHERE tc.constraint_type = 'PRIMARY KEY'
) pk ON pk.table_name = c.table_name AND pk.column_name = c.column_name
LEFT JOIN (
  SELECT ku.table_name, ku.column_name
  FROM information_schema.table_constraints tc
  JOIN information_schema.key_column_usage ku
    ON tc.constraint_name = ku.constraint_name
  WHERE tc.constraint_type = 'FOREIGN KEY'
) fk ON fk.table_name = c.table_name AND fk.column_name = c.column_name
WHERE c.table_schema = 'public'
ORDER BY c.table_name, c.ordinal_position;
```

#### 3. Tamaños de Tablas
```sql
SELECT
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS tamaño_total
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

#### 4. Conteos Aproximados
```sql
SELECT
  schemaname,
  tablename,
  n_live_tup AS filas_aproximadas
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY n_live_tup DESC;
```

---

## Apéndice: Resumen Rápido

| Aspecto               | Detalle                                                  |
|-----------------------|----------------------------------------------------------|
| **Total Tablas**      | 22 (10 catálogos + 12 maestras/transaccionales)          |
| **Filas Objetivo**    | ~100,000 (transaccionales + maestras)                    |
| **Índices**           | 27 índices adicionales (FK, fecha, estado)               |
| **Constraints CHECK** | 11 validaciones de rango y formato                       |
| **Columnas Generadas**| 1 (`tiempo_espera_minutos`)                              |
| **ON DELETE CASCADE** | 6 relaciones (persona, cita, diagnostico, receta)        |
| **Usuario Lectura**   | `lector` (solo SELECT)                                   |
| **Scripts SQL**       | 8 archivos en carpeta `recursos`                         |

---

## Versionado

| Versión | Fecha       | Cambios                                          |
|---------|-------------|--------------------------------------------------|
| 1.0     | 18/02/2026  | Documentación inicial completa                   |

---

**Autor**: Equipo BI Hospital  
**Contacto**: pablogr2928@gmail.com  
**Repositorio**: [GitHub - pablez/hospital_DB](https://github.com/pablez/hospital_DB)

---

## Notas Finales

- Esta documentación cubre el modelo completo implementado en `01_schema.sql`.
- Para cambios en la estructura, actualizar este documento y scripts correspondientes.
- Los datos son sintéticos generados con `generate_series()` y `random()`.
- Para producción, ajustar constraintsentre y volúmenes según necesidades reales.
- Consultar `README.md` en carpeta `recursos` para guía de ejecución rápida.

**Fin de la Documentación**
