-- Respaldo PRE de public.cambiar_estado_ot(p jsonb) — capturado 2026-10-07 antes del Bloque 2b.2 (Frente Partner 80000)
-- LANGUAGE plpgsql, SECURITY DEFINER, search_path=public. Para ROLLBACK: ejecutar este archivo.
CREATE OR REPLACE FUNCTION public.cambiar_estado_ot(p jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_num text := p->>'ot_numero'; v_est text := p->>'estado';
begin
  if v_est not in ('pendiente_info','para_disenar','diseno','impresion','tai',
                   'entregada_venta','entregada_cliente','anulada') then
    raise exception 'Estado inválido: %', v_est;
  end if;
  update public.ordenes_trabajo set estado = v_est where numero = v_num;
  if not found then raise exception 'OT % no existe', v_num; end if;
  return jsonb_build_object('numero', v_num, 'estado', v_est);
end $function$;
