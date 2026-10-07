-- Respaldo PRE de public.es_admin() — capturado 2026-10-07 antes del Bloque 1.3 (Frente Partner 80000)
-- Para ROLLBACK: ejecutar este archivo.
CREATE OR REPLACE FUNCTION public.es_admin()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (select 1 from public.profiles where id = auth.uid() and rol = 'admin');
$function$;
