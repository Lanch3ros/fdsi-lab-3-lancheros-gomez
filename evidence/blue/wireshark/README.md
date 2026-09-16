# Evidencia de análisis de tráfico (Wireshark)

Demostración visual del hallazgo **H1** (contenido en claro por HTTP) y de su
**mitigación** con TLS. Grupos G03+G04.

## Archivos

| Archivo | Qué contiene |
|---------|--------------|
| `wireshark-demo.pcap` | Captura **antes** (HTTP): tráfico Red Team ↔ servidor en claro |
| `tls-mitigado.pcap` | Captura **después** (HTTPS): mismo flujo, ya cifrado |
| `follow-http-stream-baseline.txt` | Extracto legible del "Follow HTTP Stream" (antes) |
| `tls-validacion.txt` | Comparación objetiva antes/después |
| `01-packet-list.png` | *(captura de pantalla)* lista de paquetes con `GET /api/v1/alerts` |
| `02-follow-http-stream.png` | *(captura de pantalla)* el JSON en claro (Follow HTTP Stream) |
| `03-tls-cifrado.png` | *(captura de pantalla, opcional)* tráfico TLS cifrado tras la mitigación |

## ANTES — tráfico plano por HTTP (hallazgo H1)

Al seguir el flujo HTTP de `GET /api/v1/alerts/ldt:mock:0001` en Wireshark, la
respuesta del servidor se lee **en texto plano**, incluyendo campos sensibles:

![Lista de paquetes en Wireshark](01-packet-list.png)

![Follow HTTP Stream con el JSON en claro](02-follow-http-stream.png)

Se observan sin cifrado: `user_name: svc_lab_a`, `cmdline: /usr/bin/mock-dump
--target lsass`, `hostname: WEB-LAB-01`, `sha256`, técnica `OS Credential
Dumping`. Extracto en texto: [`follow-http-stream-baseline.txt`](follow-http-stream-baseline.txt).

## DESPUÉS — tráfico cifrado con TLS (mitigación M1)

Con la capa de mitigación activa (`HARDENED=1 TLS=1`), la misma petición viaja por
HTTPS. La captura `tls-mitigado.pcap` muestra un handshake TLS y "Application
Data" cifrado. La búsqueda de datos sensibles en claro sobre ese PCAP da **0
ocurrencias** (antes: 8+).

![Tráfico TLS cifrado](03-tls-cifrado.png)

Detalle en [`tls-validacion.txt`](tls-validacion.txt). Diseño de la mitigación en
[`../../../MITIGACIONES.md`](../../../MITIGACIONES.md).

---

> **Nota sobre las imágenes `.png`:** son las capturas de pantalla que toma el
> equipo desde Wireshark. Para incorporarlas, guárdalas en esta carpeta con esos
> nombres exactos (`01-packet-list.png`, `02-follow-http-stream.png`,
> `03-tls-cifrado.png`) y quedarán enlazadas en este documento.
