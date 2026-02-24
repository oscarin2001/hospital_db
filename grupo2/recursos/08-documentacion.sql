-- Active: 1770989223890@@127.0.0.1@5432@hospitaldb
-- 08-documentacion.sql
-- Consultas para extraer documentación y metadatos de la base `hospitaldb`.
-- Ejecutar con psql conectándose a la BD objetivo.
-- Ejemplos: psql -d hospitaldb -f recursos/08-documentacion.sql

/* 1) Lista de tablas (esquema público) */
SELECT nspname AS schema,
       relname AS table_name,
       obj_description(pg_class.oid) AS table_description
FROM pg_class
JOIN pg_namespace n ON n.oid = pg_class.relnamespace
WHERE relkind = 'r' AND nspname = 'public'
ORDER BY relname;


/* 2) Columnas con tipo, PK, FK, referencia y descripción */
SELECT
  c.table_schema,
  c.table_name,
  c.column_name,
  c.data_type || COALESCE('('||c.character_maximum_length||')','') AS data_type,
  c.is_nullable,
  c.column_default,
  CASE WHEN pk.column_name IS NOT NULL THEN true ELSE false END AS is_primary_key,
  fk.constraint_name AS foreign_key_name,
  fk.foreign_table_schema || '.' || fk.foreign_table_name AS references_table,
  fk.foreign_column AS references_column,
  pgd.description AS column_description
FROM information_schema.columns c
LEFT JOIN (
  -- primary key columns
  SELECT kcu.table_schema, kcu.table_name, kcu.column_name
  FROM information_schema.table_constraints tc
  JOIN information_schema.key_column_usage kcu
    ON kcu.constraint_name = tc.constraint_name
   AND kcu.table_schema = tc.table_schema
   AND kcu.table_name = tc.table_name
  WHERE tc.constraint_type = 'PRIMARY KEY'
) pk
  ON pk.table_schema = c.table_schema AND pk.table_name = c.table_name AND pk.column_name = c.column_name
LEFT JOIN (
  -- foreign keys
  SELECT rc.constraint_name,
         kcu.table_schema, kcu.table_name, kcu.column_name,
         ccu.table_schema AS foreign_table_schema,
         ccu.table_name AS foreign_table_name,
         ccu.column_name AS foreign_column
  FROM information_schema.referential_constraints rc
  JOIN information_schema.key_column_usage kcu
    ON kcu.constraint_name = rc.constraint_name
  JOIN information_schema.constraint_column_usage ccu
    ON ccu.constraint_name = rc.unique_constraint_name
) fk
  ON fk.table_schema = c.table_schema AND fk.table_name = c.table_name AND fk.column_name = c.column_name
LEFT JOIN pg_catalog.pg_statio_all_tables as st on st.schemaname = c.table_schema and st.relname = c.table_name
LEFT JOIN pg_catalog.pg_description pgd ON pgd.objoid = (st.relid) AND pgd.objsubid = (
  SELECT ordinal_position FROM information_schema.columns ic
  WHERE ic.table_schema = c.table_schema AND ic.table_name = c.table_name AND ic.column_name = c.column_name
)
WHERE c.table_schema = 'public'
ORDER BY c.table_name, c.ordinal_position;


/* 3) Constraints (checks, uniques, pks, fks) por tabla */
SELECT
  tc.table_schema,
  tc.table_name,
  tc.constraint_name,
  tc.constraint_type,
  pg_get_constraintdef(con.oid) AS definition
FROM information_schema.table_constraints tc
LEFT JOIN pg_constraint con
  ON con.conname = tc.constraint_name
WHERE tc.table_schema = 'public'
ORDER BY tc.table_name, tc.constraint_type;


/* 4) Índices por tabla */
SELECT schemaname, tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;


/* 5) Tamaño y filas aproximadas por tabla */
-- Usamos pg_class.reltuples para obtener filas aproximadas y pg_total_relation_size(c.oid)
SELECT
  st.schemaname AS schema_name,
  c.relname     AS table_name,
  pg_size_pretty(pg_total_relation_size(c.oid)) AS total_size,
  pg_size_pretty(pg_relation_size(c.oid))       AS table_size,
  c.reltuples::bigint                           AS approx_rows
FROM pg_catalog.pg_stat_user_tables st
JOIN pg_catalog.pg_class c ON st.relid = c.oid
WHERE st.schemaname = 'public'
ORDER BY pg_total_relation_size(c.oid) DESC;


/* 6) Conteos exactos (precaución: puede ser lento). Descomentar y ejecutar sólo si se desea: */
-- DO $$
-- DECLARE r record;
-- BEGIN
--   FOR r IN SELECT schemaname, relname FROM pg_stat_user_tables LOOP
--     EXECUTE format('SELECT ''%s.%s'' AS table, count(*) AS exact_count FROM %I.%I', r.schemaname, r.relname, r.schemaname, r.relname);
--   END LOOP;
-- END $$;


/* 7) Muestra de datos (10 filas) por tabla: generar consultas de ejemplo */
SELECT format('SELECT * FROM %I.%I LIMIT 10;', schemaname, relname) AS sample_query
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY relname;


/* 8) Comentarios y descripciones: tabla y columnas (si existen) */
SELECT
  n.nspname AS schema,
  c.relname AS table_name,
  obj_description(c.oid) AS table_comment
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind = 'r' AND n.nspname = 'public'
ORDER BY c.relname;

SELECT
  n.nspname AS schema,
  c.relname AS table_name,
  a.attname AS column_name,
  col_description(c.oid, a.attnum) AS column_comment
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
JOIN pg_attribute a ON a.attrelid = c.oid
WHERE c.relkind = 'r' AND n.nspname = 'public' AND a.attnum > 0
ORDER BY c.relname, a.attnum;


/* 9) Dependencias FK (tabla origen -> tabla destino) */
SELECT
  con.conname AS fk_name,
  src_nsp.nspname AS source_schema,
  src_tbl.relname AS source_table,
  src_col.attname AS source_column,
  dst_nsp.nspname AS target_schema,
  dst_tbl.relname AS target_table,
  dst_col.attname AS target_column
FROM pg_constraint con
JOIN pg_class src_tbl ON src_tbl.oid = con.conrelid
JOIN pg_namespace src_nsp ON src_nsp.oid = src_tbl.relnamespace
JOIN pg_class dst_tbl ON dst_tbl.oid = con.confrelid
JOIN pg_namespace dst_nsp ON dst_nsp.oid = dst_tbl.relnamespace
JOIN unnest(con.conkey) WITH ORDINALITY AS src(colnum, ord) ON TRUE
JOIN unnest(con.confkey) WITH ORDINALITY AS dst(colnum, ord2) ON ord = ord2
JOIN pg_attribute src_col ON src_col.attrelid = src_tbl.oid AND src_col.attnum = src.colnum
JOIN pg_attribute dst_col ON dst_col.attrelid = dst_tbl.oid AND dst_col.attnum = dst.colnum
WHERE con.contype = 'f' AND src_nsp.nspname = 'public'
ORDER BY source_table;


/* 10) Resumen de uso: tablas sin PK, tablas sin filas, tablas con mayor tamaño */
SELECT
  t.relname AS table_name,
  CASE WHEN pk.constraint_name IS NULL THEN true ELSE false END AS has_no_pk,
  pg_total_relation_size(t.oid) AS bytes_total,
  t.reltuples::bigint AS approx_rows
FROM pg_class t
LEFT JOIN (
  SELECT tc.table_name, tc.constraint_name
  FROM information_schema.table_constraints tc
  WHERE tc.constraint_type = 'PRIMARY KEY' AND tc.table_schema = 'public'
) pk ON pk.table_name = t.relname
WHERE t.relkind = 'r' AND t.relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
ORDER BY bytes_total DESC;

-- Fin de 08-documentacion.sql

/* 15) Tamaño total de la base de datos y suma total aproximada de filas
   - total_database_size: tamaño en bytes y versión legible
   - total_tables_bytes: suma de pg_total_relation_size para todas las tablas public
   - total_approx_rows: suma de reltuples aproximadas
*/
SELECT
  pg_database.datname AS database_name,
  pg_database_size(pg_database.datname) AS total_bytes,
  pg_size_pretty(pg_database_size(pg_database.datname)) AS total_size_pretty
FROM pg_database
WHERE pg_database.datname = current_database();

SELECT
  SUM(pg_total_relation_size(c.oid)) AS total_tables_bytes,
  pg_size_pretty(SUM(pg_total_relation_size(c.oid))) AS total_tables_size_pretty,
  SUM(c.reltuples::bigint) AS total_approx_rows
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind = 'r' AND n.nspname = 'public';


/* 13) Cantidad de filas por tabla (RÁPIDO - aproximado) */
SELECT
  n.nspname AS schema_name,
  c.relname AS table_name,
  c.reltuples::bigint AS approx_rows
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind = 'r' AND n.nspname = 'public'
ORDER BY approx_rows DESC;


/* 14) Cantidad de filas por tabla (EXACTO - puede ser lento).
   Este bloque crea una tabla temporal y ejecuta COUNT(*) por cada tabla.
   Descomentar/ejecutar sólo si aceptas el tiempo de ejecución en tablas grandes.
*/
-- CREATE TEMP TABLE IF NOT EXISTS pg_temp.doc_table_counts(table_name text, exact_count bigint);
-- DO $$
-- DECLARE
--   r RECORD;
--   q TEXT;
-- BEGIN
--   TRUNCATE pg_temp.doc_table_counts;
--   FOR r IN SELECT n.nspname AS schema_name, c.relname AS table_name FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE c.relkind = 'r' AND n.nspname = 'public' LOOP
--     q := format('INSERT INTO pg_temp.doc_table_counts SELECT %L, count(*) FROM %I.%I', r.schema_name || '.' || r.table_name, r.schema_name, r.table_name);
--     EXECUTE q;
--   END LOOP;
-- END $$;
-- SELECT * FROM pg_temp.doc_table_counts ORDER BY exact_count DESC;


/* 11) Peso (bytes) y cantidad de datos por tabla (aproximado)
   Devuelve tamaños en bytes y versiones legibles, además de filas estimadas.
*/
SELECT
  n.nspname AS schema_name,
  c.relname AS table_name,
  pg_total_relation_size(c.oid)       AS total_bytes,
  pg_relation_size(c.oid)             AS table_bytes,
  pg_indexes_size(c.oid)              AS indexes_bytes,
  (pg_total_relation_size(c.oid) - pg_relation_size(c.oid) - pg_indexes_size(c.oid)) AS toast_bytes,
  c.reltuples::bigint                 AS approx_rows,
  pg_size_pretty(pg_total_relation_size(c.oid)) AS total_size_pretty,
  pg_size_pretty(pg_relation_size(c.oid))       AS table_size_pretty,
  pg_size_pretty(pg_indexes_size(c.oid))        AS indexes_size_pretty
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind = 'r' AND n.nspname = 'public'
ORDER BY total_bytes DESC;


/* 12) Conteos exactos por tabla (OPCIONAL - puede ser lento en tablas grandes)
   Descomentar para ejecutar; este bloque genera y ejecuta COUNT(*) por tabla.
*/
-- DO $$
-- DECLARE
--   r RECORD;
--   q TEXT;
-- BEGIN
--   RAISE NOTICE 'Computing exact counts (this can be slow)';
--   FOR r IN SELECT n.nspname AS schema, c.relname AS table_name FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE c.relkind = 'r' AND n.nspname = 'public' LOOP
--     q := format('SELECT %L AS table, count(*) AS exact_count FROM %I.%I', r.schema || '.' || r.table_name, r.schema, r.table_name);
--     EXECUTE q;
--   END LOOP;
-- END $$;

-- Fin de 08-documentacion.sql
