# Correlación Blue Team — access.log ↔ acciones Red Team

**Responsable:** Jeyder Nicolay León Lancheros (Blue Team)
**Fuente:** `evidence/blue/access.log`, `evidence/blue/lab3-http.pcap`, `evidence/blue/api-audit.json`
**Objetivo:** correlacionar cada evento de red con las hipótesis del modelo STRIDE.

> Todas las peticiones provienen de `172.28.0.30` (estación Red Team). En un
> ejercicio real, distinguir un `curl` legítimo de una enumeración exige más
> contexto: frecuencia, User-Agent, rutas solicitadas y horario. Aquí el
> User-Agent `curl/*` y la ráfaga de rutas inexistentes lo delatan.

## 1. Eventos correlacionados (mínimo 3 exigido por el checklist)

| # | Evento en access.log | Hipótesis | Interpretación Blue Team |
|---|----------------------|-----------|--------------------------|
| 1 | `GET /.git/config → 200` y `GET /.env → 200` | H5 | Rutas ocultas descargadas con éxito. Fuga de configuración. |
| 2 | `GET /api/v1/debug → 200` | H7 | Endpoint de diagnóstico accedido; expone entorno del proceso. |
| 3 | 16 × `→ 404` desde una misma IP | H6 / enumeración | Supera el umbral de detección (≥5 en 5 min). Señal de reconocimiento. |
| 4 | `GET /files/ → 200` con `Index of` | H6 | Listado de directorio servido. |
| 5 | `GET /api/v1/alerts` con contenido en claro (ver PCAP) | H1 / H8 | El JSON con `cmdline`, `user_name`, `sha256` viaja legible. |

## 2. Evidencia de H1 en el PCAP (contenido en claro)

Lectura ASCII del PCAP (`pcap-lectura-ascii.txt`):

- `composite_id` aparece **en claro** múltiples veces → el cuerpo de las
  respuestas de la API es legible sin descifrar nada.
- Los usuarios ficticios `svc_lab_a/b/c` son visibles en el tráfico.
- La petición `GET /.git/config` y su contenido viajan sin cifrar.

Esto valida H1: por HTTP, cualquier observador del medio reconstruye el contenido.

## 3. Evidencia de H10 en el log de la aplicación (spoofing de origen)

En la línea base, la API toma el origen del encabezado `X-Forwarded-For`, que el
cliente controla. La petición del Red Team con `X-Forwarded-For: 203.0.113.99`
queda registrada en la auditoría de la aplicación con esa **IP falsa**, mientras
que `access.log` de Nginx conserva la **IP real** `172.28.0.30`.

- **Auditoría de la app (falsificable):** `src_ip = 203.0.113.99`
- **access.log de Nginx (autoritativo):** `172.28.0.30`

La discrepancia entre ambas fuentes es la señal que permite detectar el intento
de falsificación. Detalle en `audit-xff.txt`.

## 4. Regla de detección (Paso 13)

Definida en `../../scripts/blue-detect.sh` y ejecutada en `deteccion-404.txt`:

> Una misma IP con **≥ 5 respuestas 404 en 5 minutos** se marca como posible
> enumeración.

**Resultado:** `172.28.0.30` generó **16** respuestas 404 → la regla dispara.

### Limitaciones y falsos positivos

- Un rastreador legítimo, un monitor de disponibilidad mal configurado o un
  usuario que teclea mal una URL pueden producir 404 sin ser un ataque.
- La regla no distingue enumeración de un simple error de despliegue (enlaces
  rotos que devuelven 404 a usuarios reales).
- No cubre ataques que solo tocan rutas existentes (`200`), como la fuga de
  `/.git/config`, que **no** genera 404. Por eso se complementa con la regla de
  rutas sensibles de la sección 1.
- El umbral fijo (5/5min) es arbitrario; un atacante lento lo evade.

La guía indica que **no es obligatorio automatizar el bloqueo**; el objetivo es
explicar la señal y sus límites, no responder de forma automática.
