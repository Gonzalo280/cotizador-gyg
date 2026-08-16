-- ROLLBACK — revierte aplicado_2026-08-16_permite_terminaciones.sql
-- NO ejecutar salvo necesidad explícita del dueño.

UPDATE productos SET permite_terminaciones=false WHERE id=38;
