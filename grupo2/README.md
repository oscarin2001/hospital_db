Proyecto: Esquema PostgreSQL + Carga masiva (documentación)

Objetivo
-------
Documentar y proporcionar los scripts necesarios para crear un esquema normalizado de un hospital, poblarlo con datos sintéticos (volumen objetivo ~50k registros) y validar la integridad y calidad de los datos. Todos los artefactos están en la carpeta `recursos`.

Contenido del directorio `recursos`
- `01_schema.sql`: DDL del esquema normalizado (catálogos, tablas maestras y transaccionales, constraints).
- `02_indexes.sql`: Índices recomendados para rendimiento en consultas analíticas.
- `03_seed_catalogos.sql`: Insert inicial de catálogos y datos maestros.
- `04_seed_50k.sql`: Script de carga masiva que genera datos con `generate_series()` y funciones SQL.
- `05_validaciones.sql`: Consultas de validación (conteos, orfandad FK, rangos clínicos, calidad de datos).
- `06_readonly_user.sql`: Script para crear el rol `lector` y otorgar permisos de solo lectura.
- `07_pathologia_ingresos_costos.sql`: Consultas analíticas ejemplo (patologías por ingresos y por costo de procedimientos).
- `diagrama.puml`: Diagrama PlantUML del modelo.

Requisitos
---------
- PostgreSQL (recomendado 13+; probado en 17 en este entorno).
- Cliente `psql` o `pgAdmin`/`DBeaver` para ejecutar los scripts.
- Acceso al sistema de archivos para leer los archivos de `recursos`.

Orden de ejecución (recomendado)
--------------------------------
1. Crear la base de datos (si no existe) y conectarse:

```bash
createdb hospitaldb
psql -d hospitaldb -f recursos/01_schema.sql
psql -d hospitaldb -f recursos/02_indexes.sql
psql -d hospitaldb -f recursos/03_seed_catalogos.sql
psql -d hospitaldb -f recursos/04_seed_50k.sql
psql -d hospitaldb -f recursos/05_validaciones.sql
```

2. (Opcional) Crear rol lector para usuarios de solo lectura:

```bash
psql -d hospitaldb -f recursos/06_readonly_user.sql
```

Descripción breve de cada script
--------------------------------
- `01_schema.sql`: crea catálogos (`cat_genero`, `cat_especialidad`, etc.), tablas maestras (`persona`, `procedimiento_medico`, `medicamento`), transaccionales (`cita_medica`, `pago`, `diagnostico`, `diagnostico_procedimiento`, `receta`, `receta_detalle`, `historial_clinico`) y constraints (PK, FK, CHECK). Contiene `GENERATED` column para `tiempo_espera_minutos`.
- `02_indexes.sql`: añade índices `CREATE INDEX IF NOT EXISTS` para columnas de join y filtro (ej. `cita_medica(fecha_cita)`, `diagnostico(codigo_cie10)`, `pago(fecha_pago)`).
- `03_seed_catalogos.sql`: inserta filas mínimas en catálogos y algunos registros base en maestros.
- `04_seed_50k.sql`: genera datos con `generate_series()` y expresiones aleatorias; respeta orden de dependencias (persona → paciente/personal → citas → pago/diagnostico → procedimientos/recetas).
- `05_validaciones.sql`: agrupaciones y checks para verificar conteos esperados, orfandad, formatos (presión/temperatura), distribuciones y top-K.
- `06_readonly_user.sql`: crea rol `lector` con contraseña y le otorga `CONNECT` y `SELECT` en `public`.
- `07_pathologia_ingresos_costos.sql`: consultas analíticas que muestran patologías (CIE10) ordenadas por ingresos y por costo de procedimientos.

Cómo ejecutar de forma segura
----------------------------
- Ejecuta `01_schema.sql` una sola vez en la base vacía; si lo re-ejecutas se eliminan tablas existentes (el script contiene DROP TABLE IF EXISTS).
- Considera ejecutar `04_seed_50k.sql` por etapas si tu machine tiene recursos limitados (dividir generate_series ranges).
- Si necesitas regenerar con otro volumen: editar la constante/series en `04_seed_50k.sql` (comentarios dentro del archivo indican qué cambiar).

Conexión remota y túnel SSH (resumen)
-----------------------------------
- Puedes exponer Postgres en LAN (no recomendado sin firewall/PG_HBA seguro) o usar túnel SSH desde el cliente:

Ejemplo túnel manual (cliente Windows/WSL):
```powershell
ssh -i C:\Users\<tu_usuario>\.ssh\pgadmin_rsa -L 15432:localhost:5432 pablex@<IP_VM>
psql -h localhost -p 15432 -U lector -d hospitaldb
```

- En `pgAdmin` puedes usar la pestaña **SSH Tunnel** del servidor y seleccionar la `Identity file` (clave privada RSA en formato PEM) para que pgAdmin abra el túnel automáticamente.

Validaciones y pruebas sugeridas
--------------------------------
- Ejecuta `recursos/05_validaciones.sql` y revisa:
	- Totales por tabla.
	- Orfandad FK (esperamos 0).
	- Registros con formatos inválidos (presión fuera de patrón, temperatura fuera de rango).
- Ejemplos de consultas analíticas incluidos en `07_pathologia_ingresos_costos.sql`.

Notas de seguridad
------------------
- No almacenes claves privadas en rutas públicas compartidas.
- Si habilitas acceso LAN, asegúrate de `pg_hba.conf` y `listen_addresses` adecuados y reglas de firewall.
- El rol `lector` creado en `06_readonly_user.sql` tiene permisos de solo lectura; revísalo y ajusta la contraseña antes de compartir.

Regenerar diagrama PlantUML
---------------------------
- El archivo `diagrama.puml` contiene la representación del esquema. Para generar PNG con PlantUML:

```bash
plantuml diagrama.puml
```

Próximos pasos y soporte
------------------------
- ¿Quieres que ejecute los scripts en `hospitaldb` ahora y te muestre resultados? (p. ej. ejecutar validaciones o la consulta de patologías).
- Puedo ajustar `04_seed_50k.sql` para otro volumen o segmentarlo en etapas para menos uso de recursos.

Contacto
--------
- Si necesitas ayuda para configurar `pgAdmin` con la llave RSA o convertir el key a PPK para PuTTY/pgAdmin en Windows, dime y te guío.

-- Fin de la documentación en `recursos/README.md`
