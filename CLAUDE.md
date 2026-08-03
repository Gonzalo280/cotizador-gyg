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
- Listas de precio: `Principal` (id 1, canal 10000) y `Empresa` (id 2, canal 40000), con precios idénticos por ahora (copia exacta). Parámetro `minimo_cotizacion_40000 = 10000`.

## Tablas principales
clientes (canal_codigo default 10000) · productos (metodo m2|unidad, config jsonb con 'minimo')
producto_precios (producto_id, lista_precio_id, incluye_diseno, precio) — índice único sobre esa terna. Lista Empresa (id 2) es copia exacta de Principal (id 1): 148 filas cada una.
producto_costos · listas_precio (columna canal_codigo, índice único — una lista por canal; hoy 2 filas: (1,'Principal',10000) y (2,'Empresa',40000)) · terminaciones · producto_terminaciones
cotizaciones (columna canal_codigo NOT NULL default 10000; histórico previo quedó en 10000) · cotizacion_items (snapshots inmutables)
ordenes_trabajo (canal_codigo, 8 estados) · ot_pagos · parametros (iva=0.19, margen_piso=30, tope_descuento_vendedor=10, minimo_cotizacion_40000=10000)
profiles (rol admin|vendedor, activo, descuento_max, empresa_default)

## Trabajo pendiente (en orden)
PASO 3 COMPLETO (a+b) y en producción: motor canal-consciente (RPC `guardar_cotizacion` v2,
bloques 1-6, mergeado vía PR #5) + frontend módulo Empresa F2 (canal visible en la cotización,
override admin, listas por canal en vivo, mergeado vía PR #8) + presentación del documento
pulida (sección "Cliente" con etiquetas en negrita siempre visibles alineadas en columna, canal
movido a la cabecera, mergeado vía PR #9).

1. Reclasificación de canal de clientes importados. Los 491 importados incluyen clientes de mesón (GyG) mezclados como canal 40000. Antes de bajar precios Empresa en F3, reclasificar a 10000 los que sean de mesón, según el análisis de facturas del dueño. Sin esto, F3 haría que clientes de mesón cobren precios Empresa rebajados.
2. Ajuste de precios lista Empresa (producto por producto, tras el Paso 3). Aquí se validan márgenes reales y se confirma el margen piso Empresa.
3. Ítems compuestos / catálogo de párrafos (proyecto aparte).
4. Merch de precio libre (después del cotizador paramétrico y del control de producción; requiere cargar SKU y costos del proveedor).
5. Control de producción / ERP (módulos diseño, impresión, TAI sobre los 8 estados de OT).

Los documentos de arquitectura completos (DOC 0 a DOC 5) los tiene el dueño y los entrega cuando corresponda.

## Pendientes menores (post canal 40000)
- Editor de ficha de cliente: hoy no existe forma de ver/corregir los datos de un cliente ya creado. Necesario antes de habilitar auto-completado.
- Auto-completado de datos de cliente al generar OT: rellenar en la ficha los campos vacíos con lo que el vendedor escribe. POSPUESTO hasta que exista el editor de fichas (para poder corregir errores). Requiere escritura a la tabla clientes.
- Bug conocido (no bug real): la OT muestra en blanco los campos de contacto que estén vacíos en la ficha del cliente. Es el comportamiento correcto mientras no exista el editor de fichas.
- Colchón de hora de producción en la OT: mostrar hora de entrega al cliente + "listo en producción" una hora antes (colchón parametrizable). Decidido mostrar ambas horas, no restar oculto. Pendiente de implementar.

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
- Piso de margen por canal: mecanismo implementado con fallback al global 30; la clave `margen_piso_40000` (20%) NO se siembra hasta F3.
- Canal sin lista propia: cobra Santa Rosa (lista 1), no da error (opción A).
- Error explícito solo si un producto no tiene precio en la lista resuelta (D5).
- Mínimo de cotización Empresa $10.000: rechaza a no-admin, admin exento, sobre el neto post-descuento.
- Frontend Empresa: INDEX ÚNICO (no archivo separado).
