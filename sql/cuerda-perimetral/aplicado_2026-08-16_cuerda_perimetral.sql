-- Cuerda perimetral: nueva terminación + vínculos + prerrequisitos — 2026-08-16
-- Aplicado en producción con protocolo PRE/POST. Ver rollback_2026-08-16_cuerda_perimetral.sql
-- para revertir.
--
-- PRE (antes de aplicar):
--   "Cuerda perimetral" no existía.
--   productos id 20 (Tela PVC reverso negro) y 74 (Tela PVC campaña elect.) tenían
--   permite_terminaciones=false (prerrequisito no cumplido — mismo bug ya visto en
--   Malla Mesh: vincular terminaciones sin esta columna en true no las muestra en el
--   frontend, ver sql/malla-mesh/aplicado_2026-08-16_permite_terminaciones.sql).
--   Terminaciones ya vinculadas: 1 (Pendón tela PVC) y 23,43,56,58,70 con el módulo
--   completo (1,2,3,4,5,6,7,11,17 — 9 c/u); 20 y 74 con el módulo base sin rollo/sobrante5
--   (1,2,3,4,5,6,7 — 7 c/u); 38 (Malla Mesh) con 1,2,3,4,7 (5, sin laminados).
--
-- POST (verificado):
--   Cuerda perimetral: id 18, tipo fija, precio 500, costo 100, config
--   {"minimo":500,"por_m2":true}.
--   productos 20 y 74: permite_terminaciones=true.
--   Malla Mesh (38): 1,2,3,4,7,17,18 — 7 terminaciones (sin laminados, con Sobrante 5cm
--   y Cuerda perimetral nuevos).
--   20 y 74: 1,2,3,4,5,6,7,11,17,18 — 10 c/u (módulo completo + Cuerda perimetral).
--   1,23,43,56,58,70: sus 9 previas + 18 — 10 c/u.

-- BLOQUE 1: crear "Cuerda perimetral" (por_m2, precio 500, costo 100, minimo 500)
INSERT INTO terminaciones (nombre, tipo, precio, costo, config)
SELECT 'Cuerda perimetral', 'fija', 500, 100, '{"minimo":500,"por_m2":true}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM terminaciones WHERE nombre='Cuerda perimetral');
-- id resultante: 18

-- BLOQUE 2: activar permite_terminaciones en id 20 y 74 (prerrequisito)
UPDATE productos SET permite_terminaciones=true WHERE id IN (20,74);

-- BLOQUE 3: vínculos (idempotente). :cp = 18 (id real de "Cuerda perimetral")
INSERT INTO producto_terminaciones (producto_id, terminacion_id) VALUES
  -- Cuerda perimetral a los 9:
  (74,18),(1,18),(70,18),(43,18),(23,18),(56,18),(58,18),(38,18),(20,18),
  -- Sobrante 5cm (17) a Malla Mesh (38):
  (38,17),
  -- Módulo completo a id 20 y 74: les faltaba 11 (Entrega en rollo) y 17 (Sobrante 5cm):
  (20,11),(20,17),(74,11),(74,17)
ON CONFLICT (producto_id, terminacion_id) DO NOTHING;
