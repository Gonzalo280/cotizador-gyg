-- Catálogo · renombres + 2 precios Santa Rosa + orden del menú (74 productos) — 2026-08-15
-- Aplicado en producción con protocolo PRE/POST. Ver rollback_2026-08-15_renombres_precios_orden.sql
-- para revertir.
--
-- PRE (antes de aplicar):
--   56="Pendón mayorista 1" (orden 5), 58="Pendón mayorista 2" (orden 6)
--   16="Roller 200 fondo prensa" (orden 28), 34="Roller 250 fondo prensa" (orden 29),
--   26="Roller 300 fondo prensa" (orden 30)
--   producto 39 lista 1 (Santa Rosa): precio 50.000 → 39 lista 2 (Empresa): 50.000 (igual)
--   producto 42 lista 1 (Santa Rosa): precio 35.000 → 42 lista 2 (Empresa): 40.000 (ya divergía)
--   orden previo: 74 filas, con hueco en el valor 70 (ningún producto en 70) y
--   73/74/75 con orden=NULL (no aparecían en el menú ordenado).
--
-- POST (verificado):
--   56="Pendón mayorista 2" (orden 6), 58="Pendón mayorista 1" (orden 5) — nombre y
--   posición se cruzan juntos.
--   16="Roller 200 fondo prensa 720 dpi" (orden 56), 34="...250... 720 dpi" (orden 55),
--   26="...300... 720 dpi" (orden 54).
--   producto 39 lista 1: 70.000. producto 42 lista 1: 50.000.
--   orden: 74 filas, 74 distintos, min 1, max 74 — sin huecos ni duplicados. 75→14,
--   73→70, 74→74.
--
-- NOTA IMPORTANTE (afecta CLAUDE.md): con este cambio la lista Empresa (id 2) queda
-- divergente de Principal (id 1) para el producto 42 (35.000 SR vs 40.000 Empresa,
-- divergencia preexistente que se mantiene) y también para el producto 20 (8.000 SR vs
-- 7.000 Empresa, divergencia preexistente detectada en el diagnóstico previo a este
-- cambio). Esto contradice la "decisión firme" documentada en F3 de precios idénticos
-- entre listas — el dueño confirmó que la divergencia en 20 y 42 es intencional. Ver
-- CLAUDE.md actualizado en el mismo commit que este archivo.

-- BLOQUE 1: renombres (5)
UPDATE productos SET nombre='Pendón mayorista 2'            WHERE id=56;
UPDATE productos SET nombre='Pendón mayorista 1'            WHERE id=58;
UPDATE productos SET nombre='Roller 200 fondo prensa 720 dpi' WHERE id=16;
UPDATE productos SET nombre='Roller 250 fondo prensa 720 dpi' WHERE id=34;
UPDATE productos SET nombre='Roller 300 fondo prensa 720 dpi' WHERE id=26;

-- BLOQUE 2: precios Santa Rosa (lista Principal id 1), ambos tiers
UPDATE producto_precios SET precio=70000 WHERE producto_id=39 AND lista_precio_id=1;
UPDATE producto_precios SET precio=50000 WHERE producto_id=42 AND lista_precio_id=1;

-- BLOQUE 3: orden del menú (74 productos)
UPDATE productos SET orden = CASE id
  WHEN 1 THEN 1   WHEN 43 THEN 2  WHEN 23 THEN 3  WHEN 70 THEN 4  WHEN 58 THEN 5
  WHEN 56 THEN 6  WHEN 3 THEN 7   WHEN 35 THEN 8  WHEN 22 THEN 9  WHEN 59 THEN 10
  WHEN 30 THEN 11 WHEN 18 THEN 12 WHEN 11 THEN 13 WHEN 75 THEN 14 WHEN 31 THEN 15
  WHEN 17 THEN 16 WHEN 29 THEN 17 WHEN 36 THEN 18 WHEN 7 THEN 19  WHEN 15 THEN 20
  WHEN 10 THEN 21 WHEN 57 THEN 22 WHEN 60 THEN 23 WHEN 20 THEN 24 WHEN 38 THEN 25
  WHEN 14 THEN 26 WHEN 6 THEN 27  WHEN 37 THEN 28 WHEN 24 THEN 29 WHEN 8 THEN 30
  WHEN 12 THEN 31 WHEN 25 THEN 32 WHEN 28 THEN 33 WHEN 41 THEN 34 WHEN 40 THEN 35
  WHEN 19 THEN 36 WHEN 33 THEN 37 WHEN 44 THEN 38 WHEN 46 THEN 39 WHEN 48 THEN 40
  WHEN 50 THEN 41 WHEN 47 THEN 42 WHEN 45 THEN 43 WHEN 49 THEN 44 WHEN 69 THEN 45
  WHEN 68 THEN 46 WHEN 67 THEN 47 WHEN 66 THEN 48 WHEN 65 THEN 49 WHEN 64 THEN 50
  WHEN 72 THEN 51 WHEN 71 THEN 52 WHEN 4 THEN 53  WHEN 26 THEN 54 WHEN 34 THEN 55
  WHEN 16 THEN 56 WHEN 13 THEN 57 WHEN 5 THEN 58  WHEN 9 THEN 59  WHEN 39 THEN 60
  WHEN 42 THEN 61 WHEN 32 THEN 62 WHEN 21 THEN 63 WHEN 27 THEN 64 WHEN 54 THEN 65
  WHEN 53 THEN 66 WHEN 52 THEN 67 WHEN 51 THEN 68 WHEN 55 THEN 69 WHEN 73 THEN 70
  WHEN 63 THEN 71 WHEN 62 THEN 72 WHEN 61 THEN 73 WHEN 74 THEN 74
  ELSE orden END
WHERE id IN (1,43,23,70,58,56,3,35,22,59,30,18,11,75,31,17,29,36,7,15,10,57,60,20,38,
  14,6,37,24,8,12,25,28,41,40,19,33,44,46,48,50,47,45,49,69,68,67,66,65,64,72,71,4,26,
  34,16,13,5,9,39,42,32,21,27,54,53,52,51,55,73,63,62,61,74);
