# Registro de la inspección pasiva (Paso 10)

| Campo | Valor |
|-------|-------|
| Herramienta | OWASP ZAP (zap-baseline, escaneo **pasivo** headless) |
| Objetivo | http://172.28.0.10 (TARGET_URL, línea base HARDENED=0) |
| Responsable | Juan David Gómez (Red Team) |
| Fecha/hora UTC | 2026-09-16T21:43:20Z |
| Active Scan | **NO** ejecutado (zap-baseline solo hace spider + escaneo pasivo) |
| Resultado | FAIL: 0 · WARN-NEW: 10 · PASS: 57 |
| Reportes | `zap-report.html`, `zap-report.md`, `zap-report.xml` |

## Observaciones pasivas encontradas (10)

Cada una es una **observación**, no una vulnerabilidad explotable (según indica el
Paso 10). Se contrastan con las debilidades de nuestro modelo STRIDE:

| # | Alerta ZAP | ID | Nuestra debilidad |
|---|-----------|-----|-------------------|
| 1 | Server Leaks Version Information (`Server` header) | 10036 | D1 |
| 2 | Server Leaks Information via `X-Powered-By` | 10037 | D1 |
| 3 | Content Security Policy (CSP) Header Not Set | 10038 | D3 |
| 4 | Missing Anti-clickjacking / X-Frame-Options | — | D3 |
| 5 | X-Content-Type-Options Header Missing | — | D3 |
| 6 | Permissions Policy Header Not Set | 10063 | D3 |
| 7 | Cross-Domain Misconfiguration (CORS abierto) | 10098 | D7 (API) |
| 8 | Private IP Disclosure | 2 | D7 (expone IP internas ficticias) |
| 9 | Storable and Cacheable Content | 10049 | D3 (sin `Cache-Control`) |
| 10 | Cross-Origin-Embedder-Policy Missing | 90004 | D3 |

## Interpretación

ZAP en modo pasivo **confirma de forma independiente** los hallazgos de curl y
nmap: la fuga de versión (D1) y la ausencia de cabeceras de seguridad (D3). La
alerta *Private IP Disclosure* corrobora H8 (la API expone IP internas, aunque
ficticias). Tras el hardening, las alertas 1–6 y 9 deben desaparecer; contrastar
con `evidence/retest/security_headers_after.txt`.

Reporte navegable: abrir `zap-report.html` en un navegador.
