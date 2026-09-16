# Registro de riesgos — FDSI Laboratorio 3

**Grupos G03+G04** · Temática: CrowdStrike Incident Hub
Estados posibles: **Corregido** · **Mitigado** · **Aceptado** · **Pendiente (Lab 4)**

| ID | Riesgo | STRIDE | Hipótesis | Severidad | Estado | Justificación |
|----|--------|--------|-----------|-----------|--------|---------------|
| D1 | El banner revela producto y versión | Information Disclosure | H2 | Media | **Corregido** | `server_tokens off` + `proxy_hide_header X-Powered-By`. Verificado: `Server: nginx` sin versión. |
| D2 | Listado de directorio (`autoindex`) | Information Disclosure | H6 | Media | **Corregido** | `autoindex off`. `/files/` → 403. |
| D3 | Faltan headers de seguridad | Tampering / Info. Disclosure | H2 | Baja | **Corregido** | `nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: no-referrer` presentes. |
| D4 | Rutas ocultas descargables (`.git`, `.env`) | Information Disclosure | H5 | **Alta** | **Corregido** | `location ~ /\.` → 404. Verificado antes 200 / después 404. |
| D5 | Sin límite de tasa | Denial of Service | H11 | Media | **Mitigado** | `limit_req` 10 r/s ráfaga 20. Mitiga enumeración; no elimina DoS distribuido. |
| D6 | Contenido e integridad en claro (HTTP) | Info. Disclosure / Tampering | H1, H4 | **Alta** | **Aceptado → Pendiente Lab 4** | HTTPS, certificados y HSTS pertenecen al Laboratorio 4 por decisión pedagógica de la guía. Riesgo conocido y documentado. |
| D7 | La API expone campos sensibles en el listado | Information Disclosure | H8 | Media | **Corregido** | `cmdline`, `user_name`, `sha256`, `filename` retirados del listado; siguen en el detalle individual. |
| D8 | Endpoint de diagnóstico expone el entorno | Information Disclosure | H7 | **Alta** | **Corregido** | `/api/v1/debug` → 404 en modo hardened. |
| D9 | Auditoría sin hora ni correlación, y pública | Repudiation | H3 | Media | **Corregido** | Auditoría con `ts_utc`, `correlation_id`, `src_ip`; endpoint público → 403. |
| D10 | La app confía en `X-Forwarded-For` (origen falsificable) | Spoofing | H10 | Media | **Mitigado** | Nginx fija `X-Real-IP` autoritativo; el valor declarado se guarda aparte. La suplantación completa requiere la identidad del Lab 4. |
| — | Escritura sin autenticación (`/assign`) | Elevation of Privilege | H9 | **Alta** | **Pendiente Lab 4** | El control que falta —identidad y roles— es materia del Lab 4. En Lab 3 solo se logra que la acción quede **trazada** en la auditoría. |

## Resumen

| Estado | Cantidad | IDs |
|--------|----------|-----|
| Corregido | 6 | D1, D2, D3, D4, D7, D8, D9 |
| Mitigado | 2 | D5, D10 |
| Aceptado / Pendiente Lab 4 | 2 (+1 hallazgo) | D6, H9 (escritura sin auth) |

## Riesgos que se trasladan al Laboratorio 4

1. **D6 — Falta de confidencialidad e integridad en tránsito.** Se resolverá con
   HTTPS, certificados y HSTS. Es el riesgo de mayor severidad que queda abierto.
2. **H9 — Escritura sin identidad.** Hoy cualquiera reasigna o cierra una alerta.
   El Lab 4 introduce autenticación, sesiones y roles (autorización), que es el
   control faltante. Se deja deliberadamente medible: la acción funciona pero
   queda registrada.
3. **Spoofing (H10) en profundidad.** Con identidad real, el origen dejará de
   depender de una cabecera controlable por el cliente.

Estos tres puntos son la **base técnica del Laboratorio 4**, tal como anticipa la
sección 13 de la guía.
