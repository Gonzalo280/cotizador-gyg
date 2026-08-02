# Registro de datos de prueba — Paso 3 F1 (bloques 1-6, motor canal-consciente)

Generado 2026-08-01 durante las pruebas del RPC `guardar_cotizacion` v2 (canal-consciente).
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

Nota: COT-2026-0185 se generó con el RPC anterior al despliegue del bloque 6 (commit `4ee3742`,
22:18:44 UTC) — quedó con `canal_codigo=10000` / `lista_precio_id=1` por el `DEFAULT` del bloque 4,
no por un fallo de la lógica canal-consciente. Ver hilo de verificación previo.

## Órdenes de trabajo de prueba (verificadas)

| numero | canal_codigo |
|---|---|
| 20006 | 20000 |
| 20007 | 20000 |
| 40016 | 40000 |
| 40017 | 40000 |

## Pagos verificados

| OT | monto |
|---|---|
| 40016 | $20.000 |
| 40017 | $1.190 |

(Solo se verificaron pagos de 40016 y 40017 — no se consultaron pagos de 20006/20007 en esta ronda.)

## Clientes ficticios confirmados

| id | razón social | rut | canal_codigo |
|---|---|---|---|
| 567 | Juan Perez | 13260423-6 | 10000 |

Nombre genérico, canal Santa Rosa, no coincide con el patrón de la importación Empresa. Candidato
claro a limpieza en F0.

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
