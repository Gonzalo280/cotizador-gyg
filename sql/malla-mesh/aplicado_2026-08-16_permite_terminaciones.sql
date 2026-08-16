-- Malla Mesh (id 38): activar permite_terminaciones — 2026-08-16
-- Aplicado en producción con protocolo PRE/POST. Ver rollback_2026-08-16_permite_terminaciones.sql
-- para revertir.
--
-- Contexto: en aplicado_2026-08-16_precio_y_terminaciones.sql se vincularon 5 terminaciones
-- a Malla Mesh (producto_terminaciones), pero el frontend decide si MUESTRA la sección de
-- terminaciones de un ítem a partir de la columna productos.permite_terminaciones
-- (index.html, mapeada a CATALOGO[id].term, usada en al menos 5 puntos del render:
-- líneas ~843, ~904, ~1041, ~1156, ~1349). Esa columna seguía en false, así que las 5
-- terminaciones ya vinculadas no se veían pese a estar bien cargadas en la base.
--
-- PRE:  permite_terminaciones = false
-- POST: permite_terminaciones = true

UPDATE productos SET permite_terminaciones=true WHERE id=38;
