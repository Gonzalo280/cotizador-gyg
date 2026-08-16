-- Paquete profiles+productos: teléfono de vendedor, renombre admin, visibilidad — 2026-08-15
-- Aplicado en producción con protocolo PRE/POST. Ver rollback_2026-08-15_telefono_renombre_visibilidad.sql
-- para revertir.
--
-- PRE (antes de aplicar):
--   profiles.telefono, profiles.vista_producto, productos.ver_en: ninguna existía.
--   profiles id eec14dbd... (admin) tenía nombre='gonsalsa69@yahoo.es' (el email, no un
--   nombre real) — igual que las 3 cuentas desactivadas (diseno.gygimpresores@gmail.com,
--   susanbarczi@gmail.com, tai.gygimpresores@gmail.com).
--
-- POST (verificado):
--   admin renombrado a "Luis Gonzalo Gutiérrez Solar" (ya no imprime el email en el pie
--   del PDF, que usa perfil.nombre).
--   8 teléfonos cargados (Aranka lleva 2, separados por salto de línea).
--   vista_producto='empresa' en 2 vendedores (Javier Muñoz, gerencia/Gonzalo vendedor) —
--   CORRECCIÓN pedida por el dueño: el admin NO lleva 'empresa', queda en el default
--   'santarosa' porque el frontend resuelve visibilidad total para rol='admin' sin
--   filtrar por esta columna.
--   productos.ver_en: 73 en 'Ambos' (default), 1 en 'Empresa' (id 38, Malla Mesh).
--
-- NOTA: Javier Muñoz, Roxana Gutiérrez S. y Francis Fuenzalida Gutiérrez comparten el
-- mismo teléfono (+569 55377286) — confirmado como intencional en la sesión, no es un
-- error de copiado. Las cuentas admin (eec14dbd...) y vendedor gerencia (9a1831d3...)
-- son la misma persona (Gonzalo) con dos logins — comparten nombre y teléfono a propósito.

-- BLOQUE 1: columnas nuevas
ALTER TABLE profiles  ADD COLUMN IF NOT EXISTS telefono text;
ALTER TABLE profiles  ADD COLUMN IF NOT EXISTS vista_producto text NOT NULL DEFAULT 'santarosa';
ALTER TABLE productos ADD COLUMN IF NOT EXISTS ver_en text NOT NULL DEFAULT 'Ambos';

-- BLOQUE 2: renombre admin
UPDATE profiles SET nombre='Luis Gonzalo Gutiérrez Solar'
  WHERE id='eec14dbd-a67e-41f9-868a-faa1414ecc98';

-- BLOQUE 3: teléfonos (por id, para no depender de join)
UPDATE profiles SET telefono='+569 85956685' WHERE id='91b720ee-9f3a-40ea-a74b-1a3cfa2a362e'; -- Susan
UPDATE profiles SET telefono='+569 55377286' WHERE id='cec1cab0-c139-499c-bf75-2360063dad87'; -- Javier
UPDATE profiles SET telefono='+569 55377286' WHERE id='764b0d66-dca9-4bea-a32b-537dc69bbc72'; -- Roxana
UPDATE profiles SET telefono='+569 45279849' WHERE id='3c80d6fc-0449-4146-acaa-b6514dcc7f7e'; -- Mario
UPDATE profiles SET telefono=E'+569 72129638\n+569 92768741' WHERE id='7ea72625-af0e-47ac-a4bb-3fb1350c733a'; -- Aranka
UPDATE profiles SET telefono='+569 55377286' WHERE id='d894a4db-2ddf-43b7-90ca-3ecfae68142f'; -- Francis
UPDATE profiles SET telefono='+569 72129688' WHERE id='eec14dbd-a67e-41f9-868a-faa1414ecc98'; -- gonsalsa admin
UPDATE profiles SET telefono='+569 72129688' WHERE id='9a1831d3-45a0-44a9-9059-f21436d79a05'; -- gerencia

-- BLOQUE 4: vista_producto = empresa — SOLO los 2 vendedores empresa (sin el admin,
-- corrección del dueño: el admin ve todo por rol, sin filtrar por esta columna)
UPDATE profiles SET vista_producto='empresa'
  WHERE id IN ('cec1cab0-c139-499c-bf75-2360063dad87',   -- Javier
               '9a1831d3-45a0-44a9-9059-f21436d79a05');  -- gerencia (vendedor)

-- BLOQUE 5: ver_en de productos (solo Malla Mesh difiere; resto queda 'Ambos' por default)
UPDATE productos SET ver_en='Empresa' WHERE id=38;  -- Malla Mesh
