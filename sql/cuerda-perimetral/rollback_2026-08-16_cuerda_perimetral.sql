-- ROLLBACK — revierte aplicado_2026-08-16_cuerda_perimetral.sql
-- NO ejecutar salvo necesidad explícita del dueño.
--
-- Los vínculos 38-17, 20-11, 20-17, 74-11, 74-17 NO existían antes de este cambio
-- (confirmado en el PRE) — se pueden borrar sin riesgo de quitar algo previo.
-- Los vínculos con 18 (Cuerda perimetral) tampoco existían en ningún producto (la
-- terminación no existía), así que se borran todos junto con la terminación.

DELETE FROM producto_terminaciones WHERE terminacion_id=18;
DELETE FROM producto_terminaciones WHERE (producto_id,terminacion_id) IN
  ((38,17),(20,11),(20,17),(74,11),(74,17));
DELETE FROM terminaciones WHERE nombre='Cuerda perimetral';
UPDATE productos SET permite_terminaciones=false WHERE id IN (20,74);
