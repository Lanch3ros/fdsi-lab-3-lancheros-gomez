# Comparación antes / después (Pasos 15–17)

**Grupos G03+G04** · Fase F (Verificar y cerrar) · Responsable: José Luis Lancheros

Ambos estados se reproducen con el mismo código cambiando una variable:

```bash
HARDENED=0 docker compose up -d --build   # ANTES (línea base)
HARDENED=1 docker compose up -d --build   # DESPUÉS (hardening)
```

## Tabla comparativa

| Hipótesis | Debilidad | Prueba | ANTES | DESPUÉS | Corrección |
|-----------|-----------|--------|-------|---------|------------|
| H2 | D1 | `curl -I /` banner | `Server: nginx/1.27.5` + `X-Powered-By: incident-hub/...` | `Server: nginx` (sin versión), sin `X-Powered-By` | `server_tokens off`, `proxy_hide_header` (C1) |
| H5 | D4 | `GET /.git/config` | `200 OK` (contenido servido) | `404` | `location ~ /\.` (C4) |
| H5 | D4 | `GET /.env` | `200 OK` | `404` | `location ~ /\.` (C4) |
| H6 | D2 | `GET /files/` | `200` + `Index of` | `403` | `autoindex off` (C2) |
| H7 | D8 | `GET /api/v1/debug` | `200` + entorno del proceso | `404` | endpoint retirado en modo hardened |
| H8 | D7 | claves del listado | incluye `cmdline`, `user_name`, `sha256`, `filename` | esos 4 campos **desaparecen** del listado | reducción de exposición (Paso 16) |
| H3/H10 | D9/D10 | `GET /api/v1/audit` | `200`, público, IP falsificable | `403`, no público; auditoría interna con `ts_utc`, `correlation_id`, `src_ip` real + `xff_declarado` | X-Real-IP autoritativo, auditoría privada |
| — | D3 | headers de seguridad | ausentes | `nosniff`, `DENY`, `no-referrer` presentes | `add_header ... always` (C3) |
| **H1** | **D6** | contenido en tránsito | **legible por HTTP** | **sigue legible por HTTP** | **NINGUNA — riesgo aceptado, Lab 4** |
| **H4** | **D6** | integridad / HSTS | sin protección | **sigue sin protección** | **NINGUNA — riesgo aceptado, Lab 4** |
| H11 | D5 | `limit_req` en config | ausente | presente (10 r/s, ráfaga 20) | `limit_req_zone` (C5) |

## Evidencia de respaldo

| Estado | Archivo |
|--------|---------|
| Nmap antes | `../red/nmap_port80.txt` |
| Nmap después | `nmap_after.txt` |
| Headers antes | `../red/curl_headers_home.txt` |
| Headers después | `headers_after.txt` |
| Rutas ocultas antes | `../red/hidden_paths.txt` |
| Rutas ocultas después | `hidden_after.txt` |
| access.log (transición 200→404 misma ruta) | `access_after.log` |

## Conclusión de la Fase F

De **10 debilidades** de la línea base:
- **8 corregidas o mitigadas** (D1, D2, D3, D4, D5, D7, D8, D9/D10).
- **2 aceptadas y trasladadas al Lab 4** (D6: confidencialidad e integridad en
  tránsito), por decisión pedagógica explícita de la guía.

El servicio sigue identificándose como HTTP, pero la versión ya no se expone,
los headers definidos aparecen y las rutas ocultas quedan denegadas — exactamente
el criterio de éxito del Paso 17.
