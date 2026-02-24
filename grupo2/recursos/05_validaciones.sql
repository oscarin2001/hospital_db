-- Active: 1769781403695@@127.0.0.1@5432@hospitaldb
-- Validaciones de integridad y volumen

-- 1) Conteo por tabla
SELECT 'persona' AS tabla, COUNT(*) AS total FROM persona
UNION ALL SELECT 'paciente', COUNT(*) FROM paciente
UNION ALL SELECT 'personal', COUNT(*) FROM personal
UNION ALL SELECT 'cita_medica', COUNT(*) FROM cita_medica
UNION ALL SELECT 'pago', COUNT(*) FROM pago
UNION ALL SELECT 'diagnostico', COUNT(*) FROM diagnostico
UNION ALL SELECT 'diagnostico_procedimiento', COUNT(*) FROM diagnostico_procedimiento
UNION ALL SELECT 'historial_clinico', COUNT(*) FROM historial_clinico
UNION ALL SELECT 'receta', COUNT(*) FROM receta
UNION ALL SELECT 'receta_detalle', COUNT(*) FROM receta_detalle
ORDER BY tabla;

-- 2) Total general aproximado (objetivo ~50k)
SELECT
  (SELECT COUNT(*) FROM persona)
+ (SELECT COUNT(*) FROM paciente)
+ (SELECT COUNT(*) FROM personal)
+ (SELECT COUNT(*) FROM cita_medica)
+ (SELECT COUNT(*) FROM pago)
+ (SELECT COUNT(*) FROM diagnostico)
+ (SELECT COUNT(*) FROM diagnostico_procedimiento)
+ (SELECT COUNT(*) FROM historial_clinico)
+ (SELECT COUNT(*) FROM receta)
+ (SELECT COUNT(*) FROM receta_detalle) AS total_general_aprox;

-- 3) Orfandad FK (debe devolver 0 en todas)
SELECT COUNT(*) AS citas_sin_paciente
FROM cita_medica c
LEFT JOIN paciente p ON p.id_paciente = c.id_paciente
WHERE p.id_paciente IS NULL;

SELECT COUNT(*) AS pagos_sin_cita
FROM pago p
LEFT JOIN cita_medica c ON c.id_cita = p.id_cita
WHERE c.id_cita IS NULL;

SELECT COUNT(*) AS diagnosticos_sin_cita
FROM diagnostico d
LEFT JOIN cita_medica c ON c.id_cita = d.id_cita
WHERE c.id_cita IS NULL;

SELECT COUNT(*) AS recetas_sin_diagnostico
FROM receta r
LEFT JOIN diagnostico d ON d.id_diagnostico = r.id_diagnostico
WHERE d.id_diagnostico IS NULL;

SELECT COUNT(*) AS detalle_sin_receta
FROM receta_detalle rd
LEFT JOIN receta r ON r.id_receta = rd.id_receta
WHERE r.id_receta IS NULL;

-- 4) Calidad de datos clínica
SELECT
  COUNT(*) FILTER (WHERE temperatura < 34 OR temperatura > 42) AS temp_fuera_rango,
  COUNT(*) FILTER (WHERE presion !~ '^[0-9]{2,3}/[0-9]{2,3}$') AS presion_formato_invalido
FROM cita_medica
WHERE temperatura IS NOT NULL OR presion IS NOT NULL;

-- 5) Distribución analítica de citas
SELECT ec.nombre AS estado_cita, COUNT(*) AS total
FROM cita_medica c
JOIN cat_estado_cita ec ON ec.id_estado_cita = c.id_estado_cita
GROUP BY ec.nombre
ORDER BY total DESC;

-- 6) Top 10 diagnósticos CIE10
SELECT codigo_cie10, COUNT(*) AS total
FROM diagnostico
GROUP BY codigo_cie10
ORDER BY total DESC
LIMIT 10;
