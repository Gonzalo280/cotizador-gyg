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

## Estado actual (agosto 2026)
- En producción: cotizador Santa Rosa completo + B7 (previsualización, numeración de ítems, columna Ítem en PDF, toggle de pago, bordes) + B8 (cabecera compacta, totales angostos, "Datos para transferencia", pie anclado al fondo, aviso de segunda hoja sobre 12 ítems) + módulo Empresa F2/F3 (ver Trabajo pendiente) + UI Cliente con Razón social/Comuna (PR #11).
- Base de datos: catálogo de 8 categorías, ~146 precios en la única lista `Principal` (id 1), copiados a `Empresa` (id 2). 552 clientes reclasificados por canal: 442 en 10000 (Santa Rosa/mesón), 103 en 40000 (Empresa), 7 en 50000 (Mercado Público). Respaldo de la reclasificación en `respaldo_reclasif_canal_2026`.
- Catálogo: los 33 productos m² activos tienen mínimo comercial de $5.000 neto. F3 (agosto 2026) actualizó 52 costos a valores reales (venían de marzo), 2 precios Santa Rosa (id 20 y 42) y 8 nombres de producto. Costo único por producto, no varía por canal ni por diseño (el diseño se cobra como ítem aparte). Respaldos: `respaldo_catalogo_f3_costos` / `_precios` / `_nombres`.
- Perfiles: vendedores con nombre real (Roxana Gutiérrez S., Aranka Gutiérrez, Mario Yáñez). Cuentas susanbarczi@gmail.com, tai.gygimpresores y diseno.gygimpresores desactivadas (activo=false) hasta la etapa de producción.
- Infraestructura: Claude Code conectado a Supabase con permiso de ESCRITURA. Regla vigente: toda escritura sigue el ciclo PRE → confirmación explícita del dueño → ejecución → POST.
- 9 canales de venta: 10000 Santa Rosa, 20000 Rrss, 30000 Campaña volumen (electoral), 40000 Empresa, 50000 Mercado Público, 60000 Ecommerce Google, 70000 Gonzalo, 80000 Partner, 90000 Mercado Libre.
- Listas de precio: `Principal` (id 1, canal 10000) y `Empresa` (id 2, canal 40000). Regla general (F3): precios idénticos entre ambas listas. EXCEPCIÓN vigente (agosto 2026, confirmada por el dueño): productos id 20 (Tela PVC reverso negro: Santa Rosa $8.000 / Empresa $7.000) e id 42 (Gráfica Vehicular liso con memoria laminado: Santa Rosa $50.000 / Empresa $40.000) divergen por decisión explícita — no es un error, no igualar ni propagar un precio al otro sin instrucción del dueño. Parámetro `minimo_cotizacion_40000 = 10000`.

## Tablas principales
clientes (canal_codigo default 10000, comuna text) · productos (metodo m2|unidad, config jsonb con 'minimo', orden int sin unicidad, permite_terminaciones bool — PRERREQUISITO independiente de producto_terminaciones para que el frontend muestre la sección de terminaciones, ver_en text default 'Ambos' — filtro de visibilidad de catálogo por perfil, valores 'Santa Rosa'|'Empresa'|'Ambos')
producto_precios (producto_id, lista_precio_id, incluye_diseno, precio) — índice único sobre esa terna. Lista Empresa (id 2) es copia de Principal (id 1) salvo EXCEPCIONES puntuales confirmadas por el dueño (ver Estado actual, productos 20 y 42).
producto_costos · listas_precio (columna canal_codigo, índice único — una lista por canal; hoy 2 filas: (1,'Principal',10000) y (2,'Empresa',40000)) · terminaciones (tipo fija|unidad; config jsonb con 'por_m2' bool + 'minimo' propio cuando aplica, ej. laminados, Sellado perimetral, Cuerda perimetral) · producto_terminaciones
cotizaciones (columna canal_codigo NOT NULL default 10000; histórico previo quedó en 10000) · cotizacion_items (snapshots inmutables)
ordenes_trabajo (canal_codigo, 8 estados) · ot_pagos · parametros (iva=0.19, margen_piso=30, tope_descuento_vendedor=10, minimo_cotizacion_40000=10000)
profiles (rol admin|vendedor, activo, descuento_max, empresa_default, telefono text — se imprime en el pie del PDF bajo el nombre del ejecutivo, vista_producto text default 'santarosa' — filtro de catálogo para vendedores; el admin ve TODO el catálogo por rol, ignora esta columna)

## Trabajo pendiente (en orden)
PASO 3 COMPLETO (a+b) y en producción: motor canal-consciente (RPC `guardar_cotizacion` v2,
bloques 1-6, mergeado vía PR #5) + frontend módulo Empresa F2 (canal visible en la cotización,
override admin, listas por canal en vivo, mergeado vía PR #8) + presentación del documento
pulida (sección "Cliente" con etiquetas en negrita siempre visibles alineadas en columna, canal
movido a la cabecera, mergeado vía PR #9).

RECLASIFICACIÓN DE CANAL DE CLIENTES — COMPLETADA (agosto 2026): de los clientes
importados, 442 quedaron en 10000 (mesón), 103 en 40000 (Empresa, según libro de
ventas GDG 2025+2026) y 7 en 50000 (Mercado Público: municipalidades y CONAF). Se
dieron de alta 44 clientes Empresa que facturaban por GDG y no tenían ficha (39 en
40000, 5 en 50000). Corrección puntual: Gráficas City (id 555) pasó a 40000; fila
basura id 374 eliminada. Respaldo para rollback: tabla `respaldo_reclasif_canal_2026`.

F3 — AJUSTE DE COSTOS Y PRECIOS — COMPLETADO (agosto 2026): 52 costos actualizados a
valores reales (venían de marzo). 2 precios Santa Rosa corregidos (id 20 Tela PVC
reverso negro 7.000→8.000; id 42 ex "Rotulación Completa" 40.000→35.000). 8 productos
renombrados. DECISIÓN FIRME (vigente para margen): margen piso 30% parejo para todos
los canales (se descartó el piso diferenciado 20%/25% para Empresa; no se sembró
`margen_piso_40000`, el motor sigue cayendo al global 30%). El 30% es el piso, no el
margen real: los márgenes medidos en la lista van de 30,0% a 82,7% según el producto.
Respaldos: `respaldo_catalogo_f3_costos` / `_precios` / `_nombres`. SUPERADO EN PARTE
por el cambio de catálogo de agosto 2026 siguiente: la decisión de precios idénticos
Empresa=Santa Rosa dejó de ser firme para los productos 20 y 42 (ver Estado actual).

FIX MÍNIMO COMERCIAL — OPCIÓN B — COMPLETADO (2026-08-14, PR #13): bug detectado en el
motor y el frontend — el mínimo comercial por producto ($5.000, columna
`productos.config->>'minimo'`) se aplicaba al precio UNITARIO antes de multiplicar por
cantidad, así que un ítem bajo el mínimo con cantidad>1 pagaba mínimo×cantidad en vez de
mínimo una sola vez por la línea completa. Corregido en ambos lados: RPC
`guardar_cotizacion` (aplicado directo a producción vía protocolo PRE/POST/rollback, sin
branch de Supabase por no estar disponible `confirm_cost`; respaldo en `sql/fix-minimo/`)
y frontend (`calcItem` en `index.html`, mismo PR). El mínimo ahora se evalúa sobre
`(precio unitario + terminaciones) × cantidad`, ya redondeado. El mínimo PROPIO de
terminaciones `por_m2` (laminados, Sellado perimetral, Cuerda perimetral) NO cambió —
sigue siendo por m² del ítem, un concepto distinto, sin cantidad involucrada.

VISIBILIDAD DE PRODUCTOS POR PERFIL + TELÉFONO DEL EJECUTIVO — COMPLETADO (2026-08-15/16,
PR #16): columnas nuevas `profiles.telefono`, `profiles.vista_producto` (default
'santarosa') y `productos.ver_en` (default 'Ambos'). El `<select>` de productos en
`index.html` se filtra: admin ve TODO (sin usar `vista_producto`); vendedor con
`vista_producto='empresa'` ve productos `ver_en IN ('Empresa','Ambos')`; el resto ve
`ver_en IN ('Santa Rosa','Ambos')`. Hoy solo Javier Muñoz y el vendedor Gonzalo
(`gerenciagonzalo28@gmail.com`) tienen `vista_producto='empresa'`; solo Malla Mesh (id 38)
tiene `ver_en='Empresa'`. El pie del PDF imprime `perfil.telefono` bajo "Ejecutivo/a de
ventas" (soporta 2 líneas separadas por `\n`, caso Aranka). De paso se renombró la cuenta
admin (`eec14dbd-...`), que tenía `profiles.nombre` = su propio email — el pie del PDF
usa `perfil.nombre`, así que antes imprimía el correo del admin en vez de un nombre.
Respaldo: `sql/visibilidad-y-pie/`.

CATÁLOGO — MALLA MESH (id 38) — COMPLETADO (2026-08-16, PR #17/#18): precio 9.000→7.000
(ambas listas). Vinculado el módulo de Pendón tela PVC SIN laminados (terminaciones
1,2,3,4,7). Bug encontrado y corregido en PR #18: `productos.permite_terminaciones`
seguía en `false` — las terminaciones vinculadas en producto_terminaciones NO se
mostraban en el frontend pese a estar bien cargadas en la base, porque el render
(`index.html`, `CATALOGO[id].term`, al menos 5 puntos de uso) depende de esa columna
como prerrequisito independiente, no solo de la tabla de relación. GOTCHA A RECORDAR:
al vincular terminaciones a un producto, SIEMPRE verificar/activar
`permite_terminaciones` — pasó una vez con Malla Mesh (bug real, corregido después) y se
detectó a tiempo en id 20/74 durante el paquete de Cuerda perimetral (prerrequisito
incluido en el mismo PR). Respaldo: `sql/malla-mesh/`.

CATÁLOGO — CUERDA PERIMETRAL — COMPLETADO (2026-08-16, PR #19): nueva terminación
"Cuerda perimetral" (id 18, tipo fija, `por_m2:true`, precio $500, costo $100, mínimo
propio $500 — misma estructura que Sellado perimetral/laminados). Vinculada a 9
productos: 1, 20, 23, 38, 43, 56, 58, 70, 74. Malla Mesh (38) sumó también "Sobrante 5cm"
(17), quedando con 7 terminaciones. Productos 20 y 74 completaron el módulo entero
(sumaron 11 "Entrega en rollo" y 17 "Sobrante 5cm", con `permite_terminaciones` activado
como prerrequisito) — quedaron con 10 terminaciones cada uno, igual que 1/23/43/56/58/70.
Respaldo: `sql/cuerda-perimetral/`.

CATÁLOGO — RENOMBRES + PRECIOS SR + ORDEN DEL MENÚ — COMPLETADO (2026-08-15): paquete de
3 bloques aplicado directo a producción con protocolo PRE/POST (sin rama, SQL de datos).
(1) 5 renombres: productos 56 y 58 intercambian nombre cruzado ("Pendón mayorista 1" ↔
"Pendón mayorista 2", posición en el menú también cruzada); rollers 16/34/26 pasan de
"Roller N fondo prensa" a "Roller N fondo prensa 720 dpi". (2) Precios Santa Rosa (lista
Principal, ambos tiers): id 39 de 50.000→70.000, id 42 de 35.000→50.000 (la lista Empresa
de ambos NO se tocó, ver excepción arriba). (3) Reordenado completo del menú: los 74
productos activos quedaron con `orden` 1..74 sin huecos ni duplicados (antes había un
hueco en el valor 70 y los productos 73/74/75 tenían `orden=NULL`, no aparecían en el
menú ordenado). Respaldos con PRE completo + rollback: `sql/catalogo-orden-nombres/`.

CATÁLOGO — MÓDULO DE TERMINACIONES + "SOBRANTE 5 CM" — COMPLETADO (2026-08-15): creada
terminación "Sobrante 5 cm por lado" (id 17, $0/$0) y vinculado el módulo completo de
terminaciones (Sellado perimetral, Sobrante 7cm, Bolsillos+tubos, Ojetillos, Laminado
mate/brillante, 2 bolsillos, Entrega en rollo, Sobrante 5cm — 9 en total) a 6 productos
que lo tenían incompleto: Pendón tela PVC (1), Tela PVC monumental (70), Pendón
mayorista 1/2 (56, 58), PVC Impreso (43), Gigantografía (23). Palomas (3, 35) y
bastidores (22, 59) NO se tocaron. Orden de terminaciones en el frontend es por
`terminacion_id` ascendente (`index.html`, `CATALOGO[k].termIds.sort((a,b)=>a-b)`), sin
columna de orden dedicada — por eso "Sobrante 5 cm" (id 17) cae debajo de "Sobrante 7cm"
(id 2) y "Entrega en rollo" (id 11) de forma automática. Respaldos:
`sql/catalogo-modulo/`.

UI MÓDULO CLIENTE — EN PRODUCCIÓN (PR #11): buscador "Cliente" pasó a etiqueta "Razón
social" (el campo `razon` separado queda oculto en el DOM, sincronizado solo por
tipeo real, nunca por foco, para no pisar la razón social de un cliente ya elegido).
Campo nuevo "Comuna" (columna `comuna text` agregada a `clientes`), se imprime en el
PDF junto a la Dirección solo si tiene valor. Placeholder de Dirección simplificado a
"Dirección". Fix de bug preexistente: `limpiarFormulario()` no vaciaba el campo de
observaciones del cliente por un id mal escrito (`obsCliente` → `obsCli`).

1. Ítems compuestos / catálogo de párrafos (proyecto aparte).
2. Merch de precio libre (después del cotizador paramétrico y del control de producción; requiere cargar SKU y costos del proveedor).
3. Control de producción / ERP (módulos diseño, impresión, TAI sobre los 8 estados de OT).

Los documentos de arquitectura completos (DOC 0 a DOC 5) los tiene el dueño y los entrega cuando corresponda.

## Pendientes menores (post canal 40000)
- Editor de ficha de cliente: hoy no existe forma de ver/corregir los datos de un cliente ya creado (incluye Comuna, agregada en agosto 2026: solo se guarda al crear un cliente nuevo, no hay edición de clientes existentes). Necesario antes de habilitar auto-completado.
- Auto-completado de datos de cliente al generar OT: rellenar en la ficha los campos vacíos con lo que el vendedor escribe. POSPUESTO hasta que exista el editor de fichas (para poder corregir errores). Requiere escritura a la tabla clientes.
- Bug conocido (no bug real): la OT muestra en blanco los campos de contacto que estén vacíos en la ficha del cliente. Es el comportamiento correcto mientras no exista el editor de fichas.
- Colchón de hora de producción en la OT: mostrar hora de entrega al cliente + "listo en producción" una hora antes (colchón parametrizable). Decidido mostrar ambas horas, no restar oculto. Pendiente de implementar.
- Bug preexistente en `filtrarClientes()` (index.html): la rama "sin coincidencias" resetea `clienteSelId=null` mientras el vendedor sigue tipeando una búsqueda parcial que aún no matchea nada, incluso si no llega a confirmar la selección nueva. Detectado en la revisión de UI Cliente (agosto 2026), no corrige datos guardados, no resuelto.
- Vista de Orden de Trabajo (index.html ~línea 1539): el campo "Dirección" ahí viene de `d.cliente.direccion` (de la base), no del formulario — no se tocó al agregar Comuna en agosto 2026. Evaluar si conviene sumar comuna también ahí.
- Canal 50000 (Mercado Público) — RIESGO DE PRECIO ABIERTO: los 7 clientes de este canal SÍ son cotizables hoy, pero por el fallback caen a precio Santa Rosa (mesón) sin ningún aviso. Precio incorrecto para licitación pública. Mientras no exista lista de precios propia del canal 50000 (F6), cotizar a estos clientes da un precio que no corresponde y nadie lo nota. Mitigación temporal a evaluar: no cotizarlos por el sistema, o crear su lista antes de usarlos.
- Normalización de RUT: hoy se ingresa con formato libre. Falta decidir un formato único, aplicar limpieza en el frontend + validación en servidor, y migrar los RUT ya guardados en la base a ese formato.

## Notas operativas
- El dueño opera GitHub por web UI y ahora también por Code. No sabe git a nivel comandos: explicarle en lenguaje simple.
- Tras cada deploy, el equipo debe hacer Ctrl+Shift+R (caché del navegador).
- Error conocido en Excel histórico de costos: usa plancha 2.88 m²; el valor correcto es 1.22×2.44 = 2.9768 m². No propagarlo.
- GOTCHA catálogo de terminaciones: vincular filas en `producto_terminaciones` NO alcanza para que se vean en el frontend. `productos.permite_terminaciones` es un prerrequisito aparte (booleano en `productos`, no en la tabla de relación) — si está en `false`, el ítem no muestra ninguna terminación aunque tenga 10 vinculadas. Verificar siempre las dos cosas juntas.
- El MCP de Supabase (`mcp__supabase__*`) a veces no queda conectado al iniciar una sesión nueva de Claude Code aunque `.mcp.json` y `SUPABASE_ACCESS_TOKEN` estén bien — usar `/mcp` para reconectar antes de asumir que hay que reconfigurar algo.

## Decisiones del Paso 3 (cerradas)
- El canal nace en la cotización y lo trae el CLIENTE (su canal_codigo), no el selector "Emitir por". "Emitir por" (GyG/GDG) solo define membrete y banco del documento.
- Lista Empresa (canal 40000): regla general (F3, agosto 2026) — idéntica a Santa Rosa, no se diferencia precio por canal. EXCEPCIÓN confirmada agosto 2026: productos id 20 y 42 divergen por decisión explícita del dueño (ver Estado actual).
- Mínimo por producto: $5.000 neto (ya aplicado). Mínimo por cotización Empresa: $10.000 neto (implementado en el Paso 3).
- Margen piso: DECISIÓN FIRME (F3, agosto 2026) — 30% parejo para todos los canales. Se descartó el piso diferenciado 20%/25% para Empresa.
- Terminaciones comparten precio entre canales.
- Override de lista solo admin, validado en servidor; el servidor ignora cualquier canal que envíe un no-admin desde el navegador.
- Solo se crea lista Empresa por ahora; otros canales se agregan después sin tocar el motor.
- El índice único (producto_id, lista_precio_id, incluye_diseno) YA existe en producto_precios.
- Piso de margen por canal: mecanismo implementado con fallback al global 30; la clave `margen_piso_40000` NO se siembra — F3 (agosto 2026) cerró en margen piso único de 30% para todos los canales, se descartó diferenciar Empresa.
- Resolución de lista de precios (verificado en el código de `guardar_cotizacion`): 1) si el canal del cliente no tiene fila propia en `listas_precio`, cae automáticamente a Santa Rosa (lista 1, canal 10000) — sin error, opción A. 2) Con la lista ya resuelta (propia o fallback), si un producto puntual no tiene precio en esa lista, recién ahí se lanza excepción explícita (D5).
- Mínimo de cotización Empresa $10.000: rechaza a no-admin, admin exento, sobre el neto post-descuento.
- Frontend Empresa: INDEX ÚNICO (no archivo separado).
