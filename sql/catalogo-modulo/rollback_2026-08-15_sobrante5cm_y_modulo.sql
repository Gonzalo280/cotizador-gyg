-- ROLLBACK — revierte aplicado_2026-08-15_sobrante5cm_y_modulo.sql
-- Elimina los 28 vínculos producto_terminaciones agregados y la terminación
-- "Sobrante 5 cm por lado" (id 17) creada el 2026-08-15.
-- NO ejecutar salvo necesidad explícita del dueño.

DELETE FROM producto_terminaciones WHERE (producto_id, terminacion_id) IN (
  (1,11),(1,17),
  (70,11),(70,17),
  (58,11),(58,17),
  (56,1),(56,2),(56,3),(56,4),(56,7),(56,17),
  (43,1),(43,2),(43,3),(43,4),(43,7),(43,11),(43,17),
  (23,1),(23,2),(23,3),(23,4),(23,7),(23,11),(23,17)
);

DELETE FROM terminaciones WHERE nombre = 'Sobrante 5 cm por lado';
