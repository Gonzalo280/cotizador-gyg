# Registro de datos de prueba — Paso 3 F1 (bloques 1-6, motor canal-consciente)

Generado 2026-08-01 durante las pruebas del RPC `guardar_cotizacion` v2 (canal-consciente).
Actualizado 2026-08-02 con las pruebas del dueño sobre F2 (frontend: canal visible, override
admin, listas por canal en vivo) — cierre de F2, ver nota al final.
Todos los datos de esta lista fueron verificados por lectura directa en la base antes de
documentarlos aquí — ninguno es asumido.

**Pendiente de limpieza en F0 (congelada hasta que cotizador1 sea el maestro).**

## Cotizaciones de prueba (verificadas)

| numero | created_at (UTC) |
|---|---|
| COT-2026-0183 | 2026-08-01 18:20:35 |
| COT-2026-0184 | 2026-08-01 18:30:12 |
| COT-2026-0185 | 2026-08-01 22:09:35 |
| COT-2026-0186 | 2026-08-01 22:36:00 |
| COT-2026-0187 | 2026-08-01 22:40:24 |
| COT-2026-0188 | 2026-08-01 23:04:45 |
| COT-2026-0189 | 2026-08-02 20:22:18 |
| COT-2026-0190 | 2026-08-02 20:29:09 |
| COT-2026-0191 | 2026-08-02 21:14:37 |
| COT-2026-0192 | 2026-08-02 21:16:46 |
| COT-2026-0193 | 2026-08-02 21:33:13 |

Nota: COT-2026-0185 se generó con el RPC anterior al despliegue del bloque 6 (commit `4ee3742`,
22:18:44 UTC) — quedó con `canal_codigo=10000` / `lista_precio_id=1` por el `DEFAULT` del bloque 4,
no por un fallo de la lógica canal-consciente. Ver hilo de verificación previo.

Nota F2: COT-2026-0189/0191/0193 → canal 40000, `lista_precio_id=2`. COT-2026-0190 → canal 10000,
`lista_precio_id=1`. COT-2026-0192 → canal 70000 (Gonzalo, sin lista propia), `lista_precio_id=1`
por el fallback a Santa Rosa — confirma en base el comportamiento de F2 en preview.

## Órdenes de trabajo de prueba (verificadas)

| numero | canal_codigo |
|---|---|
| 20006 | 20000 |
| 20007 | 20000 |
| 40016 | 40000 |
| 40017 | 40000 |
| 40018 | 40000 |
| 10040 | 10000 |
| 70010 | 70000 |
| 70011 | 70000 |

## Pagos verificados

| OT | monto | medio |
|---|---|---|
| 40016 | $20.000 | — |
| 40017 | $1.190 | — |
| 40018 | $70.151 | Transferencia |
| 10040 | $13.685 | Transferencia |
| 70010 | $13.090 | Transferencia |
| 70011 | $226.100 | Efectivo |

(Solo se verificaron pagos de 40016 y 40017 en la ronda F1 — no se consultaron pagos de
20006/20007. Los pagos de 40018/10040/70010/70011 se verificaron en la ronda F2, 2026-08-02.)

## Clientes ficticios confirmados

| id | razón social | rut | canal_codigo |
|---|---|---|---|
| 567 | Juan Perez | 13260423-6 | 10000 |
| 568 | Jose Perez | 76545434-6 | 10000 |
| 75 | Alicia Fernandez Chavez | 9632240-2 | 40000 |
| 67 | Agmar Constructora SpA | 77761192-5 | 40000 |
| 63 | 18 de Septiembre SpA | 78167138-K | 40000 |

Confirmados por el dueño como inventados (2026-08-02, cierre F2). Candidatos a limpieza en F0.
Los id 63/67/75 tienen `canal_codigo=40000` pero, a diferencia de los que siguen "por confirmar"
abajo, el dueño ya validó que son de prueba — no son parte de la importación real de Empresa.

## Por confirmar con el dueño (posibles clientes reales importados — NO marcar para borrar)

| id | razón social | rut | canal_codigo |
|---|---|---|---|
| 70 | AGUA PURIFICADA MOLINA SPA | 77965107-K | 40000 |
| 83 | ANDRES VALENCIA JIMENEZ | 25773553-2 | 40000 |
| 144 | COMERCIAL ESPINOZA Y CONTRERAS LTDA | 76266880-7 | 40000 |
| 242 | GILBERTO ROCHA DIAZ | 9673463-8 | 40000 |

Los 4 tienen razón social y RUT reales y `canal_codigo=40000`, el mismo patrón que los 491
clientes importados de Empresa. Se usaron en las pruebas de hoy (P6, P8, P10 y verificación de
COT-0185/0186/0187), pero eso no descarta que sean clientes reales de la importación. Requieren
decisión del dueño antes de cualquier limpieza — no se tocan en F0 sin su confirmación explícita.

Sin novedad en el cierre de F2 (2026-08-02): Andres Valencia, Agua Purificada Molina, Gilberto
Rocha y Comercial Espinoza siguen sin resolver — el dueño no se pronunció sobre estos cuatro.

## Cierre F2 (2026-08-02)

Las pruebas del dueño sobre el frontend del módulo Empresa (F2) pasaron todas. Validaron en
preview Vercel:
- Canal visible en el resumen de la cotización y en la previsualización B7 (mismo dato en ambos).
- Override de canal solo disponible para admin, con badge "OVERRIDE ADMIN".
- Fallback de canal 70000 (Gonzalo, sin lista propia) → `lista_precio_id=1` (Santa Rosa),
  verificado en base sobre COT-2026-0192 (ver nota F2 arriba).

F2 queda lista para PR hacia `main`.
