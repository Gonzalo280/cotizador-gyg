-- ROLLBACK — revierte aplicado_2026-08-15_telefono_renombre_visibilidad.sql
-- NO ejecutar salvo necesidad explícita del dueño.
--
-- Opción A (recomendada si no se usó ninguna columna todavía en el frontend):
-- elimina las 3 columnas nuevas por completo, revierte todo de una vez.
ALTER TABLE profiles  DROP COLUMN IF EXISTS telefono;
ALTER TABLE profiles  DROP COLUMN IF EXISTS vista_producto;
ALTER TABLE productos DROP COLUMN IF EXISTS ver_en;

-- Opción B (si ya se agregaron más datos a esas columnas y no se quiere perderlos):
-- revertir solo el renombre del admin al estado PRE.
-- UPDATE profiles SET nombre='gonsalsa69@yahoo.es'
--   WHERE id='eec14dbd-a67e-41f9-868a-faa1414ecc98';
