# Capa de mitigación — Fase 2

**Grupos G03+G04 · CrowdStrike Incident Hub**

Este documento diseña e implementa una **capa de mitigación** para las
vulnerabilidades identificadas con STRIDE en la [matriz de amenazas](threat-model/stride.md).
Cada mitigación indica: **qué amenaza resuelve**, **por qué es necesaria**, **cómo
se implementa** y **qué evidencia** la comprueba.

## Cómo activar y reproducir la capa de mitigación

La capa se activa con un solo comando, sin tocar código:

```bash
HARDENED=1 TLS=1 docker compose -f infra/docker/compose.yml up -d --build
```

| Estado | Comando | Qué representa |
|--------|---------|----------------|
| ANTES | `HARDENED=0 docker compose ... up -d` | Línea base insegura (Lab 3) |
| Hardening HTTP | `HARDENED=1 docker compose ... up -d` | Correcciones de aplicación (Lab 3) |
| **Mitigación completa** | `HARDENED=1 TLS=1 docker compose ... up -d --build` | **Hardening + TLS (Fase 2)** |

Acceso con la capa activa: **https://127.0.0.1:8443** (HTTP `:8080` redirige a HTTPS).

> El certificado es autofirmado y ficticio (`CN=incident-hub.lab`); el navegador
> mostrará un aviso de "no confiable", que es lo esperado en un laboratorio. Con
> `curl` se usa `-k` para aceptarlo.

---

## Tabla resumen de mitigaciones

| ID | Mitigación | Amenaza STRIDE | Hipótesis | Debilidad | Evidencia |
|----|------------|----------------|-----------|-----------|-----------|
| M1 | Terminación TLS (HTTPS) | Information Disclosure / Tampering | H1, H4 | D6 | `evidence/blue/wireshark/tls-mitigado.pcap` |
| M2 | Redirección 80→443 + HSTS | Tampering | H4 | D6 | `curl -I` → 301 / HSTS |
| M3 | Ocultar versión y tecnología | Information Disclosure | H2 | D1 | `evidence/retest/headers_after.txt` |
| M4 | Bloqueo de rutas ocultas | Information Disclosure | H5 | D4 | `evidence/retest/hidden_after.txt` |
| M5 | Desactivar autoindex | Information Disclosure | H6 | D2 | `evidence/retest/autoindex_after.txt` |
| M6 | Retirar endpoint de diagnóstico | Information Disclosure | H7 | D8 | `evidence/retest/debug_after.txt` |
| M7 | Minimizar datos del listado | Information Disclosure | H8 | D7 | `evidence/retest/alerts_keys_after.txt` |
| M8 | Auditoría trazable y privada | Repudiation | H3 | D9 | `evidence/retest/audit_after.txt` |
| M9 | Origen autoritativo (X-Real-IP) | Spoofing | H10 | D10 | `evidence/blue/correlacion.md` |
| M10 | Cabeceras de seguridad | Tampering / Info. Disclosure | H2 | D3 | `evidence/retest/security_headers_after.txt` |
| M11 | Límite de tasa | Denial of Service | H11 | D5 | config `limit_req` |

---

## M1 — Terminación TLS (HTTPS)

- **Amenaza que resuelve:** Information Disclosure y Tampering en tránsito (H1, H4).
  Es la mitigación central de la Fase 2 y la que se **valida en Wireshark**.
- **Por qué es necesaria:** en la línea base, el contenido de las alertas
  (`user_name`, `cmdline`, `sha256`, hostnames) viaja en claro. Cualquier
  observador de la red lo reconstruye siguiendo el flujo HTTP. Fue el hallazgo H1,
  demostrado en Wireshark.
- **Cómo se implementa:** Nginx termina TLS en el puerto 443 con un certificado
  del laboratorio (autofirmado, generado en el build). Configuración en
  [`infra/nginx/incident-hub.mitigado-tls.conf`](infra/nginx/incident-hub.mitigado-tls.conf),
  `ssl_protocols TLSv1.2 TLSv1.3`.
- **Evidencia que lo comprueba:**
  - `evidence/blue/wireshark/tls-mitigado.pcap`: al abrirlo en Wireshark se ve
    handshake TLS y "Application Data" cifrado.
  - Búsqueda de datos sensibles en claro sobre ese PCAP: **0 ocurrencias**
    (antes: 8+). Detalle en `evidence/blue/wireshark/tls-validacion.txt`.

## M2 — Redirección 80→443 y HSTS

- **Amenaza que resuelve:** Tampering (H4). Evita que quede un canal en claro por
  el que un intermediario altere el tráfico.
- **Por qué es necesaria:** de nada sirve ofrecer HTTPS si el puerto 80 sigue
  sirviendo contenido; un atacante forzaría la versión insegura.
- **Cómo se implementa:** el server de `:80` responde `301` hacia `https://`, y el
  server de `:443` añade `Strict-Transport-Security` para que el navegador exija
  HTTPS en el futuro.
- **Evidencia:** `curl -I http://127.0.0.1:8080/` → `301` con `Location: https://`;
  `curl -kI https://127.0.0.1:8443/` muestra la cabecera `Strict-Transport-Security`.

## M3 a M11 — Mitigaciones de aplicación (heredadas del hardening del Lab 3)

Estas mitigaciones ya se implementaron y verificaron en el retest del Lab 3 (estado
`HARDENED=1`) y se conservan dentro de la capa TLS. Se resumen aquí con su formato:

| Mit. | Amenaza | Por qué | Cómo | Evidencia |
|------|---------|---------|------|-----------|
| **M3** | Info. Disclosure (H2) | El banner revelaba `nginx/1.27.5` y `X-Powered-By`, útil para buscar exploits | `server_tokens off` + `proxy_hide_header X-Powered-By` | `evidence/retest/headers_after.txt` → `Server: nginx` |
| **M4** | Info. Disclosure (H5) | `/.git/config` y `/.env` se descargaban (200) | `location ~ /\. { return 404; }` | `evidence/retest/hidden_after.txt` → 404 |
| **M5** | Info. Disclosure (H6) | `/files/` listaba su contenido | `autoindex off` | `evidence/retest/autoindex_after.txt` → 403 |
| **M6** | Info. Disclosure (H7) | `/api/v1/debug` filtraba el entorno del proceso | endpoint retirado en modo endurecido | `evidence/retest/debug_after.txt` → 404 |
| **M7** | Info. Disclosure (H8) | El listado entregaba `cmdline`, `user_name`, `sha256` | se retiran esos campos del listado masivo | `evidence/retest/alerts_keys_after.txt` |
| **M8** | Repudiation (H3) | La auditoría no tenía hora ni correlación y era pública | se añade `ts_utc`, `correlation_id`, `src_ip`; endpoint → 403 | `evidence/retest/audit_after.txt` |
| **M9** | Spoofing (H10) | La app confiaba en `X-Forwarded-For`, falsificable | Nginx fija `X-Real-IP=$remote_addr` como origen autoritativo | `evidence/blue/correlacion.md` |
| **M10** | Tampering / Info. Disclosure (H2) | Faltaban cabeceras de seguridad | `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy` | `evidence/retest/security_headers_after.txt` |
| **M11** | Denial of Service (H11) | Sin límite, la enumeración no tenía fricción | `limit_req` 10 r/s, ráfaga 20 | config `mitigado-tls.conf` |

---

## Validación en Wireshark (paso a paso)

1. Abrir la captura **de antes**: `evidence/blue/wireshark/wireshark-demo.pcap`.
   Filtro `http` → clic derecho en `GET /api/v1/alerts` → **Follow → HTTP Stream**.
   Se lee el JSON con `user_name`, `cmdline`, `sha256` en claro. → H1 confirmado.
2. Abrir la captura **de después**: `evidence/blue/wireshark/tls-mitigado.pcap`.
   Filtro `tls`. Se ven paquetes `TLSv1.2/1.3` y `Application Data`. Intentar
   `Follow → HTTP Stream` ya no aplica sobre el flujo 443: no hay HTTP legible.
3. Conclusión para el profesor: **la misma petición que antes exponía las alertas
   en texto plano, ahora viaja cifrada**. La amenaza de divulgación en tránsito
   (H1/H4, debilidad D6) queda mitigada y comprobada con evidencia reproducible.

## Cobertura STRIDE tras la mitigación

| Amenaza | Antes | Después de la capa de mitigación |
|---------|-------|----------------------------------|
| **S**poofing | H10 abierta | Mitigada (M9) |
| **T**ampering | H4 abierta (sin TLS) | **Mitigada (M1, M2)** |
| **R**epudiation | H3 abierta | Mitigada (M8) |
| **I**nformation Disclosure | H1,H2,H5,H6,H7,H8 | **Mitigadas (M1,M3–M7,M10)** |
| **D**enial of Service | H11 | Mitigada parcialmente (M11) |
| **E**levation of Privilege | H9 (escritura sin auth) | **Pendiente**: requiere identidad y roles |

> **Único punto que sigue abierto:** la escritura sin autenticación (H9, endpoint
> `/assign`). Su control —identidad, sesiones y roles— excede una capa de red y es
> materia del siguiente laboratorio. Queda registrado en
> [`risk/register.md`](risk/register.md).
