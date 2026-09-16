# Checklist de cierre (§11 de la guía)

| # | Ítem | Estado | Evidencia |
|---|------|--------|-----------|
| 1 | La IP objetivo fue autorizada | ✅ | `172.28.0.10` dentro de `LAB_CIDR 172.28.0.0/24`; red Docker aislada |
| 2 | No se incluyeron datos reales | ✅ | Avisos en cada archivo; hostnames/hashes/IP ficticios |
| 3 | El servicio responde por HTTP desde el segmento permitido | ✅ | `evidence/red/curl_home.txt` |
| 4 | Red Team conservó comandos y timestamps | ✅ | `evidence/red/` con `date -u` en cada paso |
| 5 | Blue Team correlacionó al menos tres eventos | ✅ | `evidence/blue/correlacion.md` (5 eventos) |
| 6 | El PCAP solo contiene tráfico del laboratorio | ✅ | `tcp port 80` filtrado; solo `172.28.0.30 ↔ .10` |
| 7 | Se aplicaron headers y reducción de exposición | ✅ | `evidence/retest/security_headers_after.txt` |
| 8 | Se ejecutó el retest | ✅ | `evidence/retest/comparacion-antes-despues.md` |
| 9 | Los riesgos pendientes quedaron registrados para Lab 4 | ✅ | `risk/register.md` (D6, H9) |
| 10 | El tag `lab-3` existe y apunta a la entrega final | ✅ | `git tag lab-3` (último paso) |

## Entregables (§8) — cobertura

| Entregable | Ubicación |
|------------|-----------|
| Repositorio acumulativo con tag `lab-3` | (raíz) + `git tag lab-3` |
| README con arquitectura, variables y reproducción | `README.md` |
| DFD ligero con ≥2 límites de confianza | `threat-model/dfd-lab3.png` (3 fronteras) |
| Tabla STRIDE con ≥4 hipótesis | `threat-model/stride.md` (11 hipótesis) |
| `evidence/red` con Nmap, curl y ZAP pasivo | `evidence/red/` |
| `evidence/blue` con logs, PCAP y regla de detección | `evidence/blue/` |
| Comparación antes/después | `evidence/retest/comparacion-antes-despues.md` |
| Registro de riesgos | `risk/register.md` |
| Reflexión individual (≤250 palabras) | `reflections/` (una por integrante) |
| Uso responsable de IA | `ai/uso-responsable-ia.md` |
