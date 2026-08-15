-- Catálogo · módulo de terminaciones — 2026-08-15
-- Crea "Sobrante 5 cm por lado" ($0/$0) y vincula el módulo faltante (base + "Entrega en
-- rollo" + "Sobrante 5 cm") a 6 productos: Pendón tela PVC (1), Tela PVC monumental (70),
-- Pendón mayorista 2 (58), Pendón mayorista 1 (56), PVC Impreso (43), Gigantografía (23).
-- NO toca palomas (3, 35) ni bastidores (22, 59).
--
-- Aplicado en producción con protocolo PRE/POST. Ver rollback_2026-08-15_sobrante5cm_y_modulo.sql
-- para revertir.
--
-- PRE (antes de aplicar):
--   terminaciones "sobrante": solo id 2 "Sobrante 7 cm por lado" ($500/$150).
--   conteo producto_terminaciones: 1→7, 23→2, 43→2, 56→3, 58→7, 70→7.
--
-- POST (verificado):
--   terminación creada: id 17 "Sobrante 5 cm por lado", tipo fija, precio 0, costo 0, config {}.
--   conteo producto_terminaciones tras el fix: 1→9, 23→9, 43→9, 56→9, 58→9, 70→9 (todos con
--   las 7 base + id 11 "Entrega en rollo" + id 17 "Sobrante 5 cm por lado").
--   palomas (3, 35) y bastidores (59) sin cambios (2, 2, 2); bastidor 22 sigue sin
--   terminaciones vinculadas (0, igual que antes).
--   Orden en el frontend es por terminacion_id ascendente (ver index.html línea 570,
--   CATALOGO[k].termIds.sort((a,b)=>a-b)), así que "Sobrante 5 cm" (id 17) cae debajo de
--   "Sobrante 7 cm" (id 2) y de "Entrega en rollo" (id 11), como se pidió.

-- BLOQUE 1: crear la terminación (idempotente)
INSERT INTO terminaciones (nombre, tipo, precio, costo, config)
SELECT 'Sobrante 5 cm por lado', 'fija', 0, 0, '{}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM terminaciones WHERE nombre = 'Sobrante 5 cm por lado');
-- id resultante: 17

-- BLOQUE 2: vincular terminaciones faltantes (idempotente con ON CONFLICT)
-- :s5 = 17 (id real de "Sobrante 5 cm por lado")
INSERT INTO producto_terminaciones (producto_id, terminacion_id) VALUES
  -- Pendón tela PVC (1): +11, +17
  (1,11),(1,17),
  -- Tela PVC monumental (70): +11, +17
  (70,11),(70,17),
  -- Pendón mayorista 2 (58): +11, +17
  (58,11),(58,17),
  -- Pendón mayorista 1 (56): +1,2,3,4,7, +17  (ya tenía 5,6,11)
  (56,1),(56,2),(56,3),(56,4),(56,7),(56,17),
  -- PVC Impreso (43): +1,2,3,4,7,11, +17  (ya tenía 5,6)
  (43,1),(43,2),(43,3),(43,4),(43,7),(43,11),(43,17),
  -- Gigantografía (23): +1,2,3,4,7,11, +17  (ya tenía 5,6)
  (23,1),(23,2),(23,3),(23,4),(23,7),(23,11),(23,17)
ON CONFLICT (producto_id, terminacion_id) DO NOTHING;
