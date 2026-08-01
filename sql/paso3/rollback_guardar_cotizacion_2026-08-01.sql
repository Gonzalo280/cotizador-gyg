-- ROLLBACK · guardar_cotizacion (definición vigente antes del bloque 6, Paso 3)
-- Capturada el 2026-08-01 vía: SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname='guardar_cotizacion';
-- Para revertir el bloque 6: ejecutar este archivo íntegro contra la base de datos.

CREATE OR REPLACE FUNCTION public.guardar_cotizacion(p jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_uid        uuid := auth.uid();
  v_perfil     record;
  v_iva        numeric;
  v_piso       numeric;
  v_item       jsonb;
  v_prod       record;
  v_term       record;
  v_precio     numeric;
  v_costo      numeric;
  v_ancho      numeric;
  v_alto       numeric;
  v_area       numeric;
  v_cant       int;
  v_unit_p     numeric;
  v_unit_c     numeric;
  v_subtotal   numeric := 0;
  v_costo_tot  numeric := 0;
  v_desc_pct   numeric;
  v_desc_monto numeric;
  v_neto       numeric;
  v_iva_m      numeric;
  v_total      numeric;
  v_margen     numeric;
  v_cot_id     bigint;
  v_numero     text;
  v_lineas     jsonb := '[]'::jsonb;
  v_g          jsonb;
  v_lam        numeric;
  v_minimo     numeric;                                  -- V4
  v_detalle    text;                                     -- V4
  v_descr      text;                                     -- V4
begin
  if v_uid is null then
    raise exception 'Debes iniciar sesión.';
  end if;
  select * into v_perfil from profiles where id = v_uid and activo;
  if not found then
    raise exception 'Tu perfil no está activo.';
  end if;

  select valor into v_iva  from parametros where clave = 'iva';
  select valor into v_piso from parametros where clave = 'margen_piso';

  v_desc_pct := greatest(coalesce((p->>'descuento_pct')::numeric, 0), 0);
  if v_desc_pct > v_perfil.descuento_max then
    raise exception 'El descuento de %%% excede tu tope autorizado de %%%.',
      v_desc_pct, v_perfil.descuento_max;
  end if;

  for v_item in select * from jsonb_array_elements(p->'items') loop

    select * into v_prod from productos
      where id = (v_item->>'producto_id')::bigint and activo;
    if not found then
      raise exception 'Producto no encontrado o inactivo.';
    end if;

    select pp.precio into v_precio
      from producto_precios pp
      join listas_precio l on l.id = pp.lista_precio_id and l.nombre = 'Principal'
     where pp.producto_id = v_prod.id
       and pp.incluye_diseno = (v_item->>'incluye_diseno')::boolean;
    if v_precio is null then
      raise exception 'Producto "%" sin precio en la lista Principal.', v_prod.nombre;
    end if;

    select c.costo into v_costo
      from producto_costos c
     where c.producto_id = v_prod.id
       and c.incluye_diseno = (v_item->>'incluye_diseno')::boolean;
    v_costo := coalesce(v_costo, 0);

    v_cant := greatest(coalesce((v_item->>'cantidad')::int, 1), 1);

    if v_prod.metodo = 'm2' then
      v_ancho := coalesce((v_item->>'ancho')::numeric, 0);
      v_alto  := coalesce((v_item->>'alto')::numeric, 0);
      v_area  := round(v_ancho * v_alto, 3);
      if v_area <= 0 then
        raise exception 'Medidas inválidas en "%": ancho y alto deben ser mayores a 0.', v_prod.nombre;
      end if;
      v_unit_p := v_area * v_precio;
      v_unit_c := v_area * v_costo;
      -- V4: mínimo comercial por producto (solo precio; el costo queda real)
      v_minimo := coalesce((v_prod.config->>'minimo')::numeric, 0);
      if v_minimo > 0 and v_unit_p < v_minimo then
        v_unit_p := v_minimo;
      end if;
    else
      v_ancho := null; v_alto := null; v_area := null;
      v_unit_p := v_precio;
      v_unit_c := v_costo;
    end if;

    for v_term in
      select t.*, coalesce((e->>'cantidad')::numeric, 1) as q
        from jsonb_array_elements(coalesce(v_item->'terminaciones','[]'::jsonb)) e
        join terminaciones t on t.id = (e->>'id')::bigint
    loop
      if v_term.tipo = 'unidad' then
        v_unit_p := v_unit_p + v_term.precio * v_term.q;
        v_unit_c := v_unit_c + v_term.costo  * v_term.q;
      else
        if coalesce((v_term.config->>'por_m2')::boolean, false) then
          v_lam := coalesce(v_area, 1) * v_term.precio;
          v_lam := greatest(coalesce((v_term.config->>'minimo')::numeric, 0), v_lam);
          v_unit_p := v_unit_p + v_lam;
          v_unit_c := v_unit_c + coalesce(v_area, 1) * v_term.costo;
        elsif v_term.dinamico then
          v_unit_p := v_unit_p + v_term.precio;
          v_g := v_term.config;
          v_unit_c := v_unit_c
            + coalesce((v_g->>'tubos')::numeric, 2)
              * (coalesce(v_ancho,0) * 100)
              * coalesce((v_g->>'tubo_costo_cm')::numeric, 0)
            + coalesce((v_g->>'regatones')::numeric, 4)
              * coalesce((v_g->>'regaton')::numeric, 0);
        else
          v_unit_p := v_unit_p + v_term.precio;
          v_unit_c := v_unit_c + v_term.costo;
        end if;
      end if;
    end loop;

    -- Redondeo al peso (B3, se mantiene)
    v_unit_p := round(v_unit_p, 0);
    v_unit_c := round(v_unit_c, 0);

    v_subtotal  := v_subtotal  + v_unit_p * v_cant;
    v_costo_tot := v_costo_tot + v_unit_c * v_cant;

    -- V4: descripción corta del ítem (máx. 120 caracteres) unida al nombre
    v_detalle := left(trim(coalesce(v_item->>'detalle','')), 120);
    v_descr   := v_prod.nombre || case when v_detalle <> '' then ' · (' || v_detalle || ')' else '' end;

    v_lineas := v_lineas || jsonb_build_object(
      'producto_id',    v_prod.id,
      'descripcion',    v_descr,                            -- V4
      'incluye_diseno', (v_item->>'incluye_diseno')::boolean,
      'ancho', v_ancho, 'alto', v_alto, 'm2', v_area,
      'cantidad',       v_cant,
      'precio_unit',    v_unit_p,
      'costo_unit',     v_unit_c,
      'terminaciones',  coalesce(v_item->'terminaciones','[]'::jsonb),
      'subtotal',       v_unit_p * v_cant
    );
  end loop;

  if jsonb_array_length(v_lineas) = 0 then
    raise exception 'La cotización no tiene productos.';
  end if;

  v_desc_monto := round(v_subtotal * v_desc_pct / 100, 0);
  v_neto       := round(v_subtotal - v_desc_monto, 0);
  v_iva_m      := round(v_neto * v_iva, 0);
  v_total      := v_neto + v_iva_m;
  v_margen     := case when v_neto > 0
                       then (v_neto - v_costo_tot) / v_neto * 100 else 0 end;

  if v_perfil.rol <> 'admin' and v_margen < v_piso then
    raise exception 'Esta cotización queda con margen bajo el mínimo permitido. Requiere aprobación de un administrador.';
  end if;

  insert into cotizaciones
    (cliente_id, vendedor_id, lista_precio_id, estado,
     subtotal_neto, descuento_pct, descuento_monto, neto, iva, total,
     vigencia_dias, observaciones,
     empresa, forma_pago, lugar_entrega, tiempo_entrega)
  values
    (nullif(p->>'cliente_id','')::bigint, v_uid,
     (select id from listas_precio where nombre = 'Principal'),
     'enviada',
     v_subtotal, v_desc_pct, v_desc_monto, v_neto, v_iva_m, v_total,
     coalesce((p->>'vigencia_dias')::int, 15),
     nullif(p->>'observaciones',''),
     case when p->>'empresa' = 'GDG' then 'GDG' else 'GYG' end,
     nullif(p->>'forma_pago',''),
     nullif(p->>'lugar_entrega',''),
     nullif(p->>'tiempo_entrega',''))
  returning id, numero into v_cot_id, v_numero;

  insert into cotizacion_items
    (cotizacion_id, producto_id, descripcion_snapshot, incluye_diseno,
     ancho, alto, m2, cantidad,
     precio_unit_snapshot, costo_unit_snapshot, terminaciones_snapshot, subtotal)
  select v_cot_id,
         (l->>'producto_id')::bigint,
         l->>'descripcion',
         (l->>'incluye_diseno')::boolean,
         nullif(l->>'ancho','')::numeric,
         nullif(l->>'alto','')::numeric,
         nullif(l->>'m2','')::numeric,
         (l->>'cantidad')::int,
         (l->>'precio_unit')::numeric,
         (l->>'costo_unit')::numeric,
         coalesce(l->'terminaciones','[]'::jsonb),
         (l->>'subtotal')::numeric
    from jsonb_array_elements(v_lineas) l;

  return jsonb_build_object(
    'numero', v_numero,
    'id',     v_cot_id,
    'neto',   v_neto,
    'iva',    v_iva_m,
    'total',  v_total
  );
end;
$function$;
