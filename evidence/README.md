# Evidencias — FDSI Laboratorio 3 (Grupos G03+G04)

Cada hallazgo sigue la cadena exigida por la condición de aprobación:
**hipótesis → comando → timestamp → resultado → interpretación → corrección → retest.**

## `red/` — Red Team (Juan David Gómez)

| Archivo | Contenido | Hipótesis |
|---------|-----------|-----------|
| `00-contexto.txt` | Responsable, hora de inicio, objetivo, alcance | — |
| `nmap_port80.txt` | Escaneo `nmap -sV -p 80` | H2 |
| `curl_headers_home.txt`, `curl_headers_api.txt` | Banners de servidor y API | H2 |
| `api_alerts.json`, `api_alerts_keys.txt` | Listado y campos expuestos | H1, H8 |
| `hidden_paths.txt`, `hidden_paths_full.txt` | `/.git/config`, `/.env` | H5 |
| `autoindex_files.txt` | Listado de `/files/` | H6 |
| `api_debug.json`, `api_debug_envkeys.txt` | Endpoint de diagnóstico | H7 |
| `assign_sin_auth.txt` | Escritura sin identidad | H9 |
| `api_audit.json`, `api_audit_ultima.txt` | Origen falsificable | H3, H10 |
| `enumeracion.txt` | Ráfaga de rutas comunes (genera 404) | H6 |
| `tls_ausente.txt` | Ausencia de HSTS/TLS (documental) | H4 |
| `passive/` | Instructivo y registro de OWASP ZAP | H2, D3 |

## `blue/` — Blue Team (Jeyder León)

| Archivo | Contenido |
|---------|-----------|
| `lab3-http.pcap` | Captura tcpdump del ejercicio (solo tráfico del lab) |
| `pcap-lectura-ascii.txt` | Lectura del PCAP: contenido en claro (H1) |
| `access.log`, `error.log` | Telemetría de Nginx |
| `deteccion-404.txt` | Regla de detección ejecutada (dispara con 16 × 404) |
| `correlacion.md` | Correlación de ≥3 eventos con las hipótesis |
| `timeline-purple.md` | Línea de tiempo Purple Team (Paso 14) |
| `api-audit.json`, `audit-xff.txt` | Evidencia de spoofing de origen (H10) |

## `retest/` — Verificación (José Lancheros, Fase F)

| Archivo | Contenido |
|---------|-----------|
| `comparacion-antes-despues.md` | Tabla comparativa completa |
| `headers_after.txt`, `nmap_after.txt` | Banners tras hardening |
| `hidden_after.txt`, `autoindex_after.txt`, `debug_after.txt` | Rutas cerradas |
| `alerts_keys_after.txt` | Campos sensibles retirados del listado |
| `audit_after.txt`, `security_headers_after.txt` | Auditoría privada y headers |
| `access_after.log` | Mismo path 200 (antes) → 404 (después) |

## Reproducir

```bash
cd infra/docker && HARDENED=0 docker compose up -d --build   # línea base
bash ../../scripts/run-red-team.sh                            # Red Team
# (Blue captura con tcpdump; ver scripts/)
bash ../../scripts/blue-detect.sh evidence/blue/access.log    # detección
HARDENED=1 docker compose up -d                               # hardening
docker exec redteam sh /tmp/retest.sh                         # retest
```
