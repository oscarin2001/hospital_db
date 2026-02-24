-- Active: 1770989223890@@127.0.0.1@5432@hospitaldb
-- 07_pathologia_ingresos_costos.sql
-- Consulta: ¿Qué patologías generan mayor ingreso y cuáles tienen costos operativos (procedimiento_costo) más altos?
--
-- Supuestos sobre el modelo:
--  - `diagnostico` tiene `id`, `codigo_cie10`, `descripcion` y `cita_id` (la cita donde se registró el diagnóstico)
--  - `pago` tiene `cita_id` y `monto` (ingresos por cita)
--  - `diagnostico_procedimiento` relaciona `diagnostico_id` con `procedimiento_medico_id`
--  - `procedimiento_medico` tiene `id` y `costo` (costo operativo por procedimiento)
--
-- Resultado: dos listados (1) por ingresos totales asociados al diagnóstico
--            (2) por costo total de procedimientos asociados al diagnóstico

-- 1) Patologías ordenadas por ingresos generados (sumatoria de pagos de las citas donde aparece el diagnóstico)
SELECT
  d.id_diagnostico AS diagnostico_id,
  d.codigo_cie10 AS cie10,
  d.descripcion AS diagnostico,
  COALESCE(SUM(p.monto_total),0)::numeric(18,2) AS total_ingresos,
  COUNT(DISTINCT d.id_cita) AS citas_con_diagnostico,
  COUNT(dp.id_procedimiento) AS procedimientos_relacionados
FROM diagnostico d
LEFT JOIN pago p ON p.id_cita = d.id_cita
LEFT JOIN diagnostico_procedimiento dp ON dp.id_diagnostico = d.id_diagnostico
GROUP BY d.id_diagnostico, d.codigo_cie10, d.descripcion
ORDER BY total_ingresos DESC
LIMIT 50;

-- 2) Patologías ordenadas por costo operativo total de los procedimientos asociados
--    (suma de los costos de los procedimientos por aparición en `diagnostico_procedimiento`)
SELECT
  d.id_diagnostico AS diagnostico_id,
  d.codigo_cie10 AS cie10,
  d.descripcion AS diagnostico,
  COUNT(dp.id_procedimiento) AS procedimientos_relacionados,
  COALESCE(SUM(pm.costo_base),0)::numeric(18,2) AS total_costo_procedimientos,
  CASE WHEN COUNT(dp.id_procedimiento) > 0
       THEN ROUND(SUM(pm.costo_base) / NULLIF(COUNT(dp.id_procedimiento),0)::numeric,2)
       ELSE 0
  END AS avg_costo_por_procedimiento
FROM diagnostico d
LEFT JOIN diagnostico_procedimiento dp ON dp.id_diagnostico = d.id_diagnostico
LEFT JOIN procedimiento_medico pm ON pm.id_procedimiento = dp.id_procedimiento
GROUP BY d.id_diagnostico, d.codigo_cie10, d.descripcion
ORDER BY total_costo_procedimientos DESC
LIMIT 50;

-- Nota: según la cardinalidad de tus datos puedes querer agregar filtros
-- (por rango de fechas, por tipo de paciente, o por columnas de estado de cita)
-- para comparar periodos distintos o excluir registros de prueba.
