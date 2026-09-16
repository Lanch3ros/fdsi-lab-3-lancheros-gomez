# Línea de tiempo Purple Team (Paso 14)

**Grupos G03+G04** · Objetivo `172.28.0.10` · Origen Red Team `172.28.0.30`
Horas tomadas directamente de `access.log` (zona +0000 = UTC).

| Hora | Acción Red Team | Evidencia Blue Team | Conclusión |
|------|-----------------|---------------------|------------|
| (inicio) | `nmap -Pn -sV -p 80` | El SYN-scan de nmap **puede no aparecer** en access.log (Nginx registra peticiones HTTP completas, no el escaneo TCP) | Diferenciar capa de **red** vs. **aplicación** |
| 16/Sep/2026:21:27:22 +0000 | `GET /api/v1/alerts` | `200` en access.log + JSON legible en PCAP | Correlación confirmada; contenido visible por HTTP (H1) |
| 16/Sep/2026:21:27:22 +0000 | `GET /.git/config` | `200` en access.log; ruta oculta descargada | Fuga de configuración (H5) |
| 16/Sep/2026:21:27:22 +0000 | `GET /api/v1/debug` | `200`; entorno del proceso expuesto | Endpoint de diagnóstico accesible (H7) |
| 16/Sep/2026:21:27:22 +0000 | Enumeración de rutas comunes | Primer `404` de una ráfaga de 16 | Detección validada: supera umbral (H6) |

## Observación clave (pregunta de análisis §12)

**¿Qué prueba de red no apareció en access.log y por qué?**
El escaneo `nmap -sV` opera a nivel TCP/servicio. Nginx solo registra
**peticiones HTTP que llegan a completarse**; el descubrimiento de puerto y las
sondas de versión que no forman una petición HTTP válida quedan fuera de
`access.log`. Para verlos se necesita telemetría de **red** (el PCAP, o el
firewall), no de **aplicación**. Esto ilustra la diferencia entre ambas capas de
visibilidad defensiva.
