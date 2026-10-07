-- Respaldo PRE de public.registrar_pago_ot(p jsonb) — capturado 2026-10-07 antes del Bloque 2b.3 (Frente Partner 80000)
-- LANGUAGE plpgsql, SECURITY DEFINER, search_path=public. Para ROLLBACK: ejecutar este archivo.
CREATE OR REPLACE FUNCTION public.registrar_pago_ot(p jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_ot     public.ordenes_trabajo%rowtype;
  v_total  numeric(12,2);
  v_pagado numeric(12,2);
  v_monto  numeric(12,2) := (p->>'monto')::numeric;
begin
  select * into v_ot from public.ordenes_trabajo where numero = p->>'ot_numero';
  if not found then raise exception 'OT % no existe', p->>'ot_numero'; end if;
  if v_ot.estado = 'anulada' then raise exception 'La OT está anulada'; end if;

  select c.total into v_total from public.cotizaciones c where c.id = v_ot.cotizacion_id;
  select coalesce(sum(monto),0) into v_pagado from public.ot_pagos where ot_id = v_ot.id;

  if v_monto is null or v_monto <= 0 then raise exception 'Monto inválido'; end if;
  if v_pagado + v_monto > v_total then
    raise exception 'El pago excede el saldo (saldo actual: %)', v_total - v_pagado;
  end if;

  insert into public.ot_pagos (ot_id, monto, medio)
  values (v_ot.id, v_monto, nullif(p->>'medio',''));

  return jsonb_build_object('numero', v_ot.numero, 'total', v_total,
    'pagado', v_pagado + v_monto, 'saldo', v_total - v_pagado - v_monto);
end $function$;
