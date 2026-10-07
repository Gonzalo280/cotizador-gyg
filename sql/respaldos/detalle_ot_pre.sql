-- Respaldo PRE de public.detalle_ot(p jsonb) — capturado 2026-10-07 antes del Bloque 2b.4b (Frente Partner 80000)
-- LANGUAGE sql, VOLATILE, SECURITY DEFINER, search_path=public, retorna jsonb. Para ROLLBACK: ejecutar este archivo.
CREATE OR REPLACE FUNCTION public.detalle_ot(p jsonb)
 RETURNS jsonb
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select jsonb_build_object(
    'numero', o.numero, 'estado', o.estado, 'canal', cv.nombre,
    'fecha_pedido', to_char(o.fecha_pedido at time zone 'America/Santiago','DD-MM-YYYY HH24:MI'),
    'fecha_entrega', coalesce(to_char(o.fecha_entrega,'DD-MM-YYYY'),''),
    'hora_entrega',  coalesce(to_char(o.hora_entrega,'HH24:MI'),''),
    'comprobante', o.comprobante, 'observaciones', coalesce(o.observaciones,''),
    'cotizacion', c.numero,
    'empresa', coalesce(c.empresa,'GYG'), 'vendedor', coalesce(pr.nombre, ''),
    'cliente', jsonb_build_object(
       'razon_social', coalesce(cl.razon_social,''), 'rut', coalesce(cl.rut,''),
       'contacto', coalesce(cl.nombre_contacto,''), 'telefono', coalesce(cl.telefono,''),
       'correo', coalesce(cl.correo,''), 'direccion', coalesce(cl.direccion,'')),
    'items', (select coalesce(jsonb_agg(jsonb_build_object(
       'descripcion', i.descripcion_snapshot, 'cantidad', i.cantidad,
       'ancho', i.ancho, 'alto', i.alto, 'm2', i.m2,
       'incluye_diseno', i.incluye_diseno,
       'terminaciones', i.terminaciones_snapshot,
       'subtotal', i.subtotal) order by i.id), '[]'::jsonb)
       from public.cotizacion_items i where i.cotizacion_id = c.id),
    'sin_iva', (o.comprobante = 'No aplica'),
    'neto', c.neto,
    'iva',   case when o.comprobante = 'No aplica' then 0      else c.iva   end,
    'total', case when o.comprobante = 'No aplica' then c.neto else c.total end,
    'pagado', coalesce((select sum(monto) from public.ot_pagos where ot_id = o.id),0),
    'saldo',  (case when o.comprobante = 'No aplica' then c.neto else c.total end)
              - coalesce((select sum(monto) from public.ot_pagos where ot_id = o.id),0),
    'pagos', (select coalesce(jsonb_agg(jsonb_build_object(
       'id', pa.id, 'monto', pa.monto, 'medio', coalesce(pa.medio,'—'),
       'fecha', to_char(pa.fecha at time zone 'America/Santiago','DD-MM-YYYY HH24:MI')
       ) order by pa.id), '[]'::jsonb)
       from public.ot_pagos pa where pa.ot_id = o.id)
  )
  from public.ordenes_trabajo o
  join public.cotizaciones c on c.id = o.cotizacion_id
  left join public.clientes cl on cl.id = c.cliente_id
  left join public.profiles pr on pr.id = c.vendedor_id
  join public.canales_venta cv on cv.codigo = o.canal_codigo
  where o.numero = p->>'ot_numero';
$function$;
