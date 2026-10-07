-- Respaldo PRE de public.generar_ot(p jsonb) — capturado 2026-10-07 antes del Bloque 2b.1 (Frente Partner 80000)
-- LANGUAGE plpgsql, SECURITY DEFINER, search_path=public. Para ROLLBACK: ejecutar este archivo.
CREATE OR REPLACE FUNCTION public.generar_ot(p jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_cot   public.cotizaciones%rowtype;
  v_ot_id bigint;
  v_num   text;
  v_abono numeric(12,2) := coalesce((p->>'abono_monto')::numeric, 0);
begin
  select * into v_cot from public.cotizaciones where numero = p->>'cotizacion_numero';
  if not found then
    raise exception 'Cotización % no existe', p->>'cotizacion_numero';
  end if;

  if exists (select 1 from public.ordenes_trabajo where cotizacion_id = v_cot.id) then
    raise exception 'La cotización % ya tiene una OT generada', v_cot.numero;
  end if;

  if not exists (select 1 from public.canales_venta
                 where codigo = (p->>'canal_codigo')::int and activo) then
    raise exception 'Canal de venta inválido';
  end if;

  if v_abono < 0 or v_abono > v_cot.total then
    raise exception 'El abono no puede superar el total (%)', v_cot.total;
  end if;

  insert into public.ordenes_trabajo
    (cotizacion_id, canal_codigo, fecha_entrega, hora_entrega, comprobante, observaciones)
  values
    (v_cot.id,
     (p->>'canal_codigo')::int,
     nullif(p->>'fecha_entrega','')::date,
     nullif(p->>'hora_entrega','')::time,
     coalesce(nullif(p->>'comprobante',''),'Factura'),
     nullif(p->>'observaciones',''))
  returning id, numero into v_ot_id, v_num;

  if v_abono > 0 then
    insert into public.ot_pagos (ot_id, monto, medio)
    values (v_ot_id, v_abono, nullif(p->>'abono_medio',''));
  end if;

  update public.cotizaciones set estado = 'aceptada' where id = v_cot.id;

  return jsonb_build_object(
    'numero', v_num, 'ot_id', v_ot_id,
    'total', v_cot.total, 'pagado', v_abono, 'saldo', v_cot.total - v_abono);
end $function$;
