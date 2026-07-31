# CLAUDE.md — cotizador1 · GyG Impresores / Grupo Digital Gráfico SpA

## Quién es el dueño
Luis Gonzalo Gutiérrez Solar (Gonzalo). Empresario chileno, 24 años en publicidad gráfica.
NO es programador. Trabaja en español. Prefiere respuestas directas, sin relleno.
Su prioridad: (1) rentabilidad verificable, (2) simplicidad operacional, (3) escalabilidad, (4) velocidad.

## Qué es este proyecto
Cotizador web en producción para el equipo de ventas (4-8 usuarios) de dos empresas:
- GyG Impresores (RUT 13.250.007-K) — mesón/retail, canal Santa Rosa
- Grupo Digital Gráfico SpA (RUT 76.677.433-4) — clientes empresa

Productos: gigantografías, pendones, rollers, branding vehicular, letreros, adhesivos, DTF textil.
URL producción: https://cotizador1.vercel.app

## Arquitectura
- Frontend: UN archivo `index.html` (~1.460 líneas). HTML+CSS+JS vanilla. Sin framework, sin build.
- Backend: Supabase (Postgres + Auth + RLS + RPCs). Project ref: tcruyggneptjmrmjfcqq
- Deploy: Vercel conectado a GitHub (Gonzalo280/cotizador-gyg). Push a main = producción. Push a rama = preview.
- PDF: window.print() con bloque @media print. Sin librerías.

### Principio central de seguridad
El navegador propone, el servidor dispone. El frontend calcula solo para mostrar.
El precio real, descuentos, margen y correlativo los determina el RPC `guardar_cotizacion`
(SECURITY DEFINER) releyendo precios desde tablas. NUNCA mover lógica de precio al frontend.

## REGLAS DURAS — no negociables

1. NUNCA hacer push ni merge directo a `main`. Siempre: rama nueva → push → preview Vercel → el dueño prueba → PR → él aprueba el merge.
2. SQL destructivo (DELETE, DROP, TRUNCATE, UPDATE masivo, CREATE OR REPLACE de RPC) requiere confirmación EXPLÍCITA del dueño antes de ejecutar. Mostrar primero qué se va a ejecutar y qué filas afecta.
3. Todo cambio SQL se entrega con: verificación PRE, la operación, verificación POST con valores esperados, y ROLLBACK preparado.
4. NUNCA inventar datos. Si una query no se pudo ejecutar, decirlo. Si un número no se verificó, no afirmarlo.
5. Responder en español.
6. No tomar decisiones de arquitectura por cuenta propia. Ante ambigüedad: preguntar al dueño.
7. El arquitecto del proyecto es un chat web separado. Este entorno (Claude Code) es el EJECUTOR: recibe instrucciones acotadas y las ejecuta. Si una instrucción parece incompleta o riesgosa, detenerse y avisar.

## Estado actual (julio 2026)
- En producción: cotizador Santa Rosa completo + B7 (previsualización, numeración de ítems, columna Ítem en PDF, toggle de pago, bordes) + B8 (cabecera compacta, totales angostos, "Datos para transferencia", pie anclado al fondo, aviso de segunda hoja sobre 12 ítems).
- Base de datos: catálogo de 8 categorías, ~146 precios en la única lista `Principal` (id 1). ~503 clientes (491 Empresa importados canal 40000 + los que crea el mesón).
- Catálogo: los 33 productos m² activos tienen mínimo comercial de $5.000 neto. Producto id 11 "Adhesivo Normal P3 Impreso" con costo corregido a $5.000. Producto id 75 "Adhesivo Normal P3 Impreso Mayorista" creado ($8.500 precio / $5.000 costo, laminados mate y brillante).
- Perfiles: vendedores con nombre real (Roxana Gutiérrez S., Aranka Gutiérrez, Mario Yáñez). Cuentas susanbarczi@gmail.com, tai.gygimpresores y diseno.gygimpresores desactivadas (activo=false) hasta la etapa de producción.
- Infraestructura: Claude Code conectado a Supabase con permiso de ESCRITURA. Regla vigente: toda escritura sigue el ciclo PRE → confirmación explícita del dueño → ejecución → POST.
- 9 canales de venta: 10000 Santa Rosa, 20000 Rrss, 30000 Campaña volumen (electoral), 40000 Empresa, 50000 Mercado Público, 60000 Ecommerce Google, 70000 Gonzalo, 80000 Partner, 90000 Mercado Libre.

## Tablas principales
clientes (canal_codigo default 10000) · productos (metodo m2|unidad, config jsonb con 'minimo')
producto_precios (producto_id, lista_precio_id, incluye_diseno, precio) — índice único sobre esa terna
producto_costos · listas_precio (hoy solo id 1 'Principal') · terminaciones · producto_terminaciones
cotizaciones (NO tiene canal_codigo todavía) · cotizacion_items (snapshots inmutables)
ordenes_trabajo (canal_codigo, 8 estados) · ot_pagos · parametros (iva=0.19, margen_piso=30)
profiles (rol admin|vendedor, activo, descuento_max, empresa_default)

## Trabajo pendiente (en orden)
1. PASO 3 (rama y chat aparte): precios por canal + RPC canal-consciente. Dos mitades: (a) base de datos + motor, (b) frontend. Se hace (a) primero, se prueba, luego (b).
2. Ajuste de precios lista Empresa (producto por producto, tras el Paso 3). Aquí se validan márgenes reales y se confirma el margen piso Empresa.
3. Ítems compuestos / catálogo de párrafos (proyecto aparte).
4. Merch de precio libre (después del cotizador paramétrico y del control de producción; requiere cargar SKU y costos del proveedor).
5. Control de producción / ERP (módulos diseño, impresión, TAI sobre los 8 estados de OT).

Los documentos de arquitectura completos (DOC 0 a DOC 5) los tiene el dueño y los entrega cuando corresponda.

## Notas operativas
- El dueño opera GitHub por web UI y ahora también por Code. No sabe git a nivel comandos: explicarle en lenguaje simple.
- Tras cada deploy, el equipo debe hacer Ctrl+Shift+R (caché del navegador).
- Error conocido en Excel histórico de costos: usa plancha 2.88 m²; el valor correcto es 1.22×2.44 = 2.9768 m². No propagarlo.

## Decisiones del Paso 3 (cerradas)
- El canal nace en la cotización y lo trae el CLIENTE (su canal_codigo), no el selector "Emitir por". "Emitir por" (GyG/GDG) solo define membrete y banco del documento.
- Lista Empresa (canal 40000) arranca como copia exacta de Santa Rosa; el dueño baja precios después.
- Mínimo por producto: $5.000 neto (ya aplicado). Mínimo por cotización Empresa: $10.000 neto (se implementa en el Paso 3).
- Margen piso: 30% mesón, 20% Empresa — el 20% queda A VALIDAR con márgenes reales antes de encender.
- Terminaciones comparten precio entre canales.
- Override de lista solo admin, validado en servidor; el servidor ignora cualquier canal que envíe un no-admin desde el navegador.
- Solo se crea lista Empresa por ahora; otros canales se agregan después sin tocar el motor.
- El índice único (producto_id, lista_precio_id, incluye_diseno) YA existe en producto_precios.
