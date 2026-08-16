-- ROLLBACK — revierte aplicado_2026-08-16_precio_y_terminaciones.sql
-- NO ejecutar salvo necesidad explícita del dueño.
--
-- Restaura precio a 9.000 (ambas listas) y re-vincula los laminados (5,6) que existían
-- antes del cambio. Las terminaciones 1,2,3,4,7 se dejan vinculadas — algunas ya
-- existían antes de este cambio (no se puede distinguir cuáles del PRE), así que el
-- rollback no las borra para no quitar algo que Malla Mesh ya tenía de antes.

UPDATE producto_precios SET precio=9000 WHERE producto_id=38;

INSERT INTO producto_terminaciones (producto_id, terminacion_id) VALUES (38,5),(38,6)
  ON CONFLICT (producto_id, terminacion_id) DO NOTHING;
