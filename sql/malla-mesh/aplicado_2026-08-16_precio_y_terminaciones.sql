-- Malla Mesh (id 38): baja de precio + módulo de terminaciones sin laminados — 2026-08-16
-- Aplicado en producción con protocolo PRE/POST. Ver rollback_2026-08-16_precio_y_terminaciones.sql
-- para revertir.
--
-- PRE (antes de aplicar):
--   precio: 9.000 en ambas listas (Principal y Empresa), ambos tiers.
--   terminaciones ya vinculadas: 1,2,3,4,5,6,7 (las 7 completas, incluidos los 2 laminados).
--
-- CORRECCIÓN durante la sesión: el Bloque 2 original solo insertaba (idempotente), lo que
-- habría dejado los laminados (5,6) que YA estaban vinculados, contradiciendo el pedido
-- explícito "SIN laminados". Se agregó un DELETE de 5 y 6 al bloque, confirmado por el
-- dueño antes de ejecutar.
--
-- POST (verificado):
--   precio: 7.000 en ambas listas, ambos tiers.
--   terminaciones: 1,2,3,4,7 (5 en total, sin 5/6).

-- BLOQUE 1: precio $7.000 (ambas listas, ambos tiers)
UPDATE producto_precios SET precio=7000 WHERE producto_id=38;

-- BLOQUE 2: vincular las 5 terminaciones del módulo Pendón tela PVC sin laminados,
-- y quitar los laminados que ya estaban vinculados.
INSERT INTO producto_terminaciones (producto_id, terminacion_id) VALUES
  (38,1),(38,2),(38,3),(38,4),(38,7)
ON CONFLICT (producto_id, terminacion_id) DO NOTHING;
DELETE FROM producto_terminaciones WHERE producto_id=38 AND terminacion_id IN (5,6);
