# Implementación: PostgreSQL + carga de ~50k datos

Este README ejecuta el plan completo dentro de `recursos`.

## 1) Archivos y orden de ejecución

Ejecutar los scripts en este orden exacto:

1. `01_schema.sql`
2. `02_indexes.sql`
3. `03_seed_catalogos.sql`
4. `04_seed_50k.sql`
5. `05_validaciones.sql`
6. `06_readonly_user.sql` (opcional)

## 2) Objetivo de volumen

- Se carga un total aproximado de **100,000 filas** en tablas de negocio.
- Casi todas las tablas transaccionales reciben datos; algunas tablas (catálogos/maestros) tienen menos filas por diseño.

Distribución base usada en `04_seed_50k.sql`:

- `persona`: 22,000
- `paciente`: 19,000
- `personal`: 3,000
- `cita_medica`: 16,000
- `pago`: 16,000
- `diagnostico`: 10,000
- `diagnostico_procedimiento`: 7,000
- `historial_clinico`: 4,000
- `receta`: 2,500
- `receta_detalle`: 2,500

## 3) Requisitos técnicos

- PostgreSQL 13+ (recomendado 14 o 15)
- Base de datos creada (`hospitaldb`)
- Permisos para `CREATE`, `INSERT`, `TRUNCATE`, `INDEX`

## 4) Ejecución rápida desde VS Code

Con extensión de DB Client/SQL, abrir conexión a `hospitaldb` y ejecutar scripts en orden.

Si usas `psql`:

```bash
psql -U postgres -d hospitaldb -f recursos/01_schema.sql
psql -U postgres -d hospitaldb -f recursos/02_indexes.sql
psql -U postgres -d hospitaldb -f recursos/03_seed_catalogos.sql
psql -U postgres -d hospitaldb -f recursos/04_seed_50k.sql
psql -U postgres -d hospitaldb -f recursos/05_validaciones.sql
psql -U postgres -d hospitaldb -f recursos/06_readonly_user.sql
```

## 5) Qué valida el script final

`05_validaciones.sql` verifica:

- conteo por tabla,
- total aproximado de filas,
- orfandad de llaves foráneas,
- rangos de datos clínicos,
- distribución de citas y CIE10.

## 6) Herramientas externas sugeridas

- **SQLTools (VS Code)**: ejecución y exploración SQL.
- **Database Client (VS Code)**: ejecución de scripts por archivo.
- **pgAdmin 4**: administración visual, import/export y `COPY`.
- **DBeaver**: editor SQL + generación/importación de datos.
- **dbForge Data Generator for PostgreSQL**: generación masiva sintética guiada.
- **Mockaroo**: generación CSV sintético para luego cargar por `COPY`.

## 7) Ajustar volumen

Si quieres variar los volúmenes, modifica directamente los límites y `generate_series()` en `04_seed_50k.sql`.

## 8) Usuario lectura y acceso remoto (LAN)

Crear rol solo-lectura:

```bash
psql -U postgres -d hospitaldb -f recursos/06_readonly_user.sql
```

Habilitar conexiones LAN (ajustar en `pg_hba.conf`):

```
host    hospitaldb    lector    192.168.56.0/24    md5
```

Y en `postgresql.conf` asegurar:

```
listen_addresses = '*'
```

Luego recargar configuración:

```sql
SELECT pg_reload_conf();
```
