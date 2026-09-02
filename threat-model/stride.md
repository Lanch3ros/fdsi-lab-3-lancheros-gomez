# Modelo de amenazas STRIDE — CrowdStrike Incident Hub

**Laboratorio:** FDSI 3 · **Grupos:** G03+G04 · **Fase B de la guía (Pasos 6 y 7)**
**Estado modelado:** línea base `HARDENED=0` (HTTP, sin autenticación)
**Elaborado:** sesión conjunta de los tres integrantes, **antes** de ejecutar cualquier prueba.

> ⚠️ Este documento se escribe **antes** del Red Team, no después. La guía (§2) exige
> documentar *amenaza, hipótesis, comando, resultado esperado y evidencia* antes de
> ejecutar. Si las hipótesis se escribieran después de atacar, describirían lo ya
> observado y no demostrarían método.

---

## 1. Alcance del modelo

| | |
|---|---|
| **Sistema** | Prototipo CrowdStrike Incident Hub (portal estático + API de alertas ficticias) |
| **Objetivo autorizado** | `TARGET_IP` dentro de `LAB_CIDR` únicamente |
| **Fuera de alcance** | Internet, red institucional, equipos de otros grupos, cualquier host fuera del CIDR |
| **Prohibido** | DoS, fuerza bruta, explotación destructiva, persistencia, MITM sobre terceros |
| **Palabra de seguridad** | `STOP-LAB` — cualquier integrante puede detener una prueba |
| **Naturaleza de los datos** | 100% ficticios; no hay nada que anonimizar porque nada es real |

---

## 2. Fronteras de confianza

La guía (Paso 6) pide como mínimo dos: *"la entrada al servidor y el cambio entre red
y aplicación"*. Identificamos **tres**, porque el almacenamiento y la telemetría
introducen una decisión de confianza propia que explica la hipótesis de Repudiation.

| ID | Frontera | Separa | Por qué es una frontera |
|----|----------|--------|--------------------------|
| **TB1** | Red externa → servidor | E1/E2 ↔ P1 (Nginx :80) | Todo lo que cruza es **no confiable y no autenticado**. Nginx no distingue a un analista legítimo de la estación Red Team: ambos son peticiones HTTP anónimas. Además el tráfico viaja en claro, así que cualquiera con acceso al medio lee el contenido completo. |
| **TB2** | Red → aplicación | P1 (Nginx) ↔ P2 (API Flask) | Nginx **reenvía sin validar** y la API **confía en lo que Nginx le pasa**, incluida la cabecera `X-Forwarded-For`, que el cliente controla. La API tampoco verifica que la petición venga realmente del proxy: quien alcance el puerto 8000 la consume directo, saltándose TB1. |
| **TB3** | Proceso → almacenamiento y telemetría | P1/P2 ↔ DS1/DS2/DS3/DS4 | Aquí se decide **qué queda registrado y con qué detalle**. Es la frontera que determina si un evento puede atribuirse después. También separa los datos que el proceso *puede* leer de los que *debería* exponer. |

**Nota sobre TB1 y el firewall:** `ufw`/la red Docker restringen el origen a `LAB_CIDR`,
pero eso limita *quién llega*, no *qué se ve*. La confidencialidad sigue ausente.

---

## 3. Elementos del DFD

| ID | Tipo | Elemento | Zona |
|----|------|----------|------|
| E1 | Entidad externa | Estación Red Team (Kali / contenedor `redteam`, 172.28.0.30) | No confiable |
| E2 | Entidad externa | Analista SOC con navegador, sin identidad | No confiable |
| E3 | Entidad interna | Blue Team operando sobre el host | Host |
| P1 | Proceso | Nginx — estático + proxy inverso (172.28.0.10:80) | Host / capa de red |
| P2 | Proceso | Incident Hub API — Flask/gunicorn (172.28.0.20:8000) | Capa de aplicación |
| DS1 | Almacén | Webroot público (`index.html`, `public-inventory.txt`, `files/`, `.git/`, `.env`) | Host |
| DS2 | Almacén | Telemetría Nginx (`access.log`, `error.log`) | Host |
| DS3 | Almacén | Dataset de alertas (`alerts.json`) | Aplicación |
| DS4 | Almacén | Registro de auditoría de la aplicación | Aplicación |

| Flujo | Recorrido | Protocolo | Cruza |
|-------|-----------|-----------|-------|
| F1 | E1 → P1 (y respuesta) | HTTP :80 en claro | TB1 |
| F2 | E2 → P1 | HTTP :80 en claro | TB1 |
| F3 | P1 → P2 | HTTP :8000 en claro | TB2 |
| F4 | P1 → DS1 | lectura de ficheros | TB3 |
| F5 | P1 → DS2 | escritura de log | TB3 |
| F6 | DS2 → E3 | lectura del defensor | TB3 |
| F7 | P2 → DS3 | lectura del dataset | TB3 |
| F8 | P2 → DS4 | escritura de auditoría | TB3 |
| F9 | E3 observa F1 y F3 | captura `tcpdump` | TB1 / TB2 |

---

## 4. Tabla STRIDE — resumen

Once hipótesis. La guía exige **mínimo cuatro**; H1–H4 conservan intencionalmente el
enunciado y la numeración de la tabla de ejemplo del Paso 7 para que la correspondencia
con la guía sea directa. H5–H11 las extienden con las debilidades específicas de este
prototipo.

| ID | STRIDE | Hipótesis técnica | Frontera | Debilidad | Responsable |
|----|--------|-------------------|----------|-----------|-------------|
| **H1** | Information Disclosure | HTTP permite observar contenido y rutas en tránsito | TB1 | D6 | Blue (captura) + Red (genera) |
| **H2** | Information Disclosure | Headers y respuestas revelan tecnología y versión | TB1 | D1 | Red |
| **H3** | Repudiation | Sin correlación temporal, el equipo no atribuye solicitudes | TB3 | D9 | Blue |
| **H4** | Tampering | Sin TLS, un intermediario podría alterar el tráfico | TB1 | D6 | Red (documental) |
| **H5** | Information Disclosure | Rutas ocultas desplegadas por error son descargables | TB1 | D4 | Red |
| **H6** | Information Disclosure | El listado de directorio revela recursos no enlazados | TB1 | D2 | Red |
| **H7** | Information Disclosure | Un endpoint de diagnóstico expone configuración interna | TB2 | D8 | Red |
| **H8** | Information Disclosure | La API entrega campos sensibles innecesarios en el listado | TB2 | D7 | Red |
| **H9** | Elevation of Privilege / Tampering | Cualquiera cambia el estado de una alerta sin identidad | TB2 | falta de authN/authZ | Red |
| **H10** | Spoofing | La API confía en `X-Forwarded-For`, que el cliente falsifica | TB2 | D10 | Red + Blue |
| **H11** | Denial of Service | Sin límite de tasa, la enumeración no encuentra fricción | TB1 | D5 | **No se ejecuta** — ver §6 |

### Cobertura STRIDE

| Letra | Amenaza | Cubierta por |
|-------|---------|--------------|
| **S** | Spoofing | H10 |
| **T** | Tampering | H4, H9 |
| **R** | Repudiation | H3 |
| **I** | Information Disclosure | H1, H2, H5, H6, H7, H8 |
| **D** | Denial of Service | H11 *(documental)* |
| **E** | Elevation of Privilege | H9 |

Las seis categorías quedan cubiertas. El peso recae en *Information Disclosure*, que es
exactamente lo que la guía anticipa para un servicio HTTP sin autenticación (§1).

---

## 5. Fichas de hipótesis

Cada ficha usa el formato que exige la condición de aprobación: **hipótesis → comando →
timestamp → resultado → interpretación → corrección → retest**. Los campos en blanco se
completan durante la ejecución y su evidencia se guarda en `evidence/`.

> `$TARGET_URL` y `$TARGET_IP` según las variables de `README.md`.
> Todo comando debe registrar su hora: `date -u +%Y-%m-%dT%H:%M:%SZ`.

---

### H1 · Information Disclosure — el contenido viaja legible

| | |
|---|---|
| **Frontera** | TB1 (y TB2) · **Debilidad** D6 · **Responsable** Blue captura, Red genera |
| **Hipótesis** | Al no existir TLS, un observador del medio puede leer URI, cabeceras y cuerpo completo de las respuestas, incluidos los campos sensibles del dataset de alertas. |
| **Comando (Blue)** | `sudo timeout 60 tcpdump -i any -nn -s0 -w evidence/blue/lab3-http.pcap 'tcp port 80'` |
| **Comando (Red)** | `curl "$TARGET_URL/"` y `curl "$TARGET_URL/api/v1/alerts"` durante esos 60 s |
| **Resultado esperado** | Con el filtro `http` en Wireshark se reconstruye el JSON completo, con `cmdline`, `user_name` y `sha256` en claro. |
| **Timestamp** | _(completar)_ |
| **Resultado observado** | _(completar)_ |
| **Interpretación** | _(completar)_ |
| **Corrección Lab 3** | **Ninguna.** HTTPS pertenece al Lab 4 (§ Límite pedagógico). Se reduce el dato expuesto vía H8, no el canal. |
| **Retest** | Repetir la captura tras el hardening: el canal sigue en claro pero el listado ya no incluye campos sensibles. |

---

### H2 · Information Disclosure — el banner revela producto y versión

| | |
|---|---|
| **Frontera** | TB1 · **Debilidad** D1 · **Responsable** Red |
| **Hipótesis** | Las cabeceras de respuesta identifican el servidor y su versión exacta, y la API añade su propia cabecera de tecnología, lo que permite buscar vulnerabilidades conocidas sin tocar el sistema. |
| **Comando** | `curl -I "$TARGET_URL/"` · `curl -I "$TARGET_URL/api/v1/alerts"` · `nmap -Pn -sV -p 80 "$TARGET_IP"` |
| **Resultado esperado** | `Server: nginx/<versión>` y `X-Powered-By: incident-hub/<versión> (Flask)`. Nmap reporta producto y versión. |
| **Timestamp** | _(completar)_ |
| **Resultado observado** | _(completar)_ |
| **Interpretación** | _(completar)_ |
| **Corrección Lab 3** | `server_tokens off` y `proxy_hide_header X-Powered-By` (C1). |
| **Retest** | `curl -I` ya no muestra versión; Nmap puede seguir identificando "nginx" sin número. |

---

### H3 · Repudiation — no se puede atribuir quién hizo qué

| | |
|---|---|
| **Frontera** | TB3 · **Debilidad** D9 · **Responsable** Blue |
| **Hipótesis** | El registro de auditoría de la aplicación no guarda hora ni identificador de correlación, así que sus entradas no pueden ordenarse ni cruzarse con `access.log`. Su único campo de origen (`src_ip`) proviene de una cabecera que el cliente controla, de modo que ni siquiera ese dato sirve para atribuir (ver H10). |
| **Comando** | `curl "$TARGET_URL/api/v1/audit"` y comparar contra `sudo tail -n 50 /var/log/nginx/access.log` |
| **Resultado esperado** | Las entradas de auditoría carecen de `ts_utc` y `correlation_id`; solo `access.log` permite reconstruir hora y origen reales, y a costa de un cruce manual. |
| **Timestamp** | _(completar)_ |
| **Resultado observado** | _(completar)_ |
| **Interpretación** | _(completar)_ |
| **Corrección Lab 3** | La auditoría incorpora `ts_utc`, `src_ip`, `user_agent` y `correlation_id`, y deja de ser un endpoint público (pasa a 403). |
| **Retest** | El log de la aplicación permite correlacionar cada acción con una petición concreta de `access.log`. |

---

### H4 · Tampering — sin TLS no hay garantía de integridad

| | |
|---|---|
| **Frontera** | TB1 · **Debilidad** D6 · **Responsable** Red (documental) |
| **Hipótesis** | Un intermediario en la ruta podría modificar respuestas sin que cliente ni servidor lo detecten, porque no existe ningún mecanismo de integridad. |
| **Comando** | **No se ejecuta MITM.** Se demuestra la *ausencia de protección*: `curl -sI "$TARGET_URL/" \| grep -iE 'strict-transport|content-security'` y verificar que el puerto 443 no responde. |
| **Resultado esperado** | Sin `Strict-Transport-Security`, sin TLS, sin firma ni verificación de integridad. Ausencia comprobable sin interceptar a nadie. |
| **Timestamp** | _(completar)_ |
| **Resultado observado** | _(completar)_ |
| **Interpretación** | _(completar)_ |
| **Corrección Lab 3** | **Ninguna.** Riesgo aceptado y trasladado al Lab 4. |
| **Retest** | Confirmar que el riesgo sigue abierto y queda anotado en `risk/register.md`. |

> **Razón de no ejecutar MITM:** la guía (§2) prohíbe interceptar tráfico de terceros.
> Demostrar que el control falta es suficiente y no requiere atacar a nadie.

---

### H5 · Information Disclosure — rutas ocultas desplegadas por error

| | |
|---|---|
| **Frontera** | TB1 · **Debilidad** D4 · **Responsable** Red |
| **Hipótesis** | El despliegue arrastró artefactos que no deberían ser públicos (`.git/`, `.env`). Si son descargables, exponen metadatos del proyecto y configuración. |
| **Comando** | `curl -i "$TARGET_URL/.git/config"` · `curl -i "$TARGET_URL/.env"` |
| **Resultado esperado** | `200 OK` con el contenido de ambos archivos. |
| **Timestamp** | _(completar)_ |
| **Resultado observado** | _(completar)_ |
| **Interpretación** | _(completar)_ |
| **Corrección Lab 3** | `location ~ /\. { deny all; return 404; }` (C4). Se responde 404 y no 403 para no confirmar la existencia del recurso. |
| **Retest** | Ambas rutas devuelven `404`. |

---

### H6 · Information Disclosure — el listado de directorio revela recursos ocultos

| | |
|---|---|
| **Frontera** | TB1 · **Debilidad** D2 · **Responsable** Red |
| **Hipótesis** | Con `autoindex on`, un directorio sin `index.html` devuelve su listado, permitiendo descubrir archivos que no están enlazados desde ninguna página. |
| **Comando** | `curl -i "$TARGET_URL/files/"` |
| **Resultado esperado** | HTML con el índice del directorio y el nombre de los archivos. |
| **Timestamp** | _(completar)_ |
| **Resultado observado** | _(completar)_ |
| **Interpretación** | _(completar)_ |
| **Corrección Lab 3** | `autoindex off` (C2). |
| **Retest** | La ruta devuelve `403` o `404`, sin listado. |

---

### H7 · Information Disclosure — endpoint de diagnóstico olvidado

| | |
|---|---|
| **Frontera** | TB2 · **Debilidad** D8 · **Responsable** Red |
| **Hipótesis** | La API conserva un endpoint de diagnóstico que expone rutas internas, versión del intérprete y variables de entorno del proceso. Se descubre por enumeración, no por enlace. |
| **Comando** | `curl -s "$TARGET_URL/api/v1/debug" \| jq .` |
| **Resultado esperado** | JSON con `routes`, `python`, `cwd` y el bloque `env`. |
| **Timestamp** | _(completar)_ |
| **Resultado observado** | _(completar)_ |
| **Interpretación** | _(completar)_ |
| **Corrección Lab 3** | El endpoint deja de existir en modo hardened (responde `404`). |
| **Retest** | `curl` devuelve `404`. |

---

### H8 · Information Disclosure — la API entrega más datos de los necesarios

| | |
|---|---|
| **Frontera** | TB2 · **Debilidad** D7 · **Responsable** Red |
| **Hipótesis** | El listado masivo de alertas incluye campos que solo tendrían sentido en el detalle de una alerta concreta (`cmdline`, `user_name`, `sha256`, `filename`), ampliando innecesariamente la superficie de exposición. |
| **Comando** | `curl -s "$TARGET_URL/api/v1/alerts" \| jq '.resources[0] \| keys'` |
| **Resultado esperado** | La lista de claves incluye los cuatro campos sensibles. |
| **Timestamp** | _(completar)_ |
| **Resultado observado** | _(completar)_ |
| **Interpretación** | _(completar)_ |
| **Corrección Lab 3** | Paso 16 — reducción de exposición: el listado deja de incluir esos campos; siguen disponibles en el detalle individual. |
| **Retest** | Las claves sensibles desaparecen del listado. |

---

### H9 · Elevation of Privilege / Tampering — escritura sin identidad

| | |
|---|---|
| **Frontera** | TB2 · **Debilidad** ausencia de autenticación y autorización · **Responsable** Red |
| **Hipótesis** | Un endpoint de escritura cambia el estado de una alerta sin exigir identidad, de modo que cualquiera que alcance el servicio puede reasignar o cerrar incidentes. |
| **Comando** | `curl -i -X POST "$TARGET_URL/api/v1/alerts/ldt:mock:0001/assign" -H 'Content-Type: application/json' -d '{"assigned_to":"prueba_red_team","status":"closed"}'` |
| **Resultado esperado** | `200 OK` y la alerta reasignada, sin haber presentado credencial alguna. |
| **Timestamp** | _(completar)_ |
| **Resultado observado** | _(completar)_ |
| **Interpretación** | _(completar)_ |
| **Corrección Lab 3** | **Parcial.** El control que falta —identidad y roles— es materia del Lab 4. En Lab 3 solo se consigue que la acción quede **trazada** (H3). |
| **Retest** | La acción sigue siendo posible, pero ahora aparece en la auditoría con IP, hora y `correlation_id`. Riesgo **mitigado, no corregido**. |

> Esta es la hipótesis que más claramente conecta con el Laboratorio 4.

---

### H10 · Spoofing — la aplicación confía en una cabecera que el cliente controla

| | |
|---|---|
| **Frontera** | TB2 · **Debilidad** D10 · **Responsable** Red ejecuta, Blue verifica |
| **Hipótesis** | La línea base de Nginx no fija `X-Real-IP` (D10), así que la API solo dispone de `X-Forwarded-For` y toma su primer valor como origen. Si el cliente envía esa cabecera, falsea su IP en la auditoría de la aplicación, aunque `access.log` de Nginx conserve la real. |
| **Comando** | `curl -s "$TARGET_URL/api/v1/alerts" -H 'X-Forwarded-For: 203.0.113.99'` y comparar auditoría contra `access.log` |
| **Resultado esperado** | La auditoría de la aplicación muestra la IP falsificada; `access.log` muestra la IP real de la estación Red Team. |
| **Timestamp** | _(completar)_ |
| **Resultado observado** | _(completar)_ |
| **Interpretación** | _(completar)_ |
| **Corrección Lab 3** | Nginx fija `X-Real-IP` con `$remote_addr` y la API lo usa como origen autoritativo, guardando aparte el valor declarado en `xff_declarado`. La discrepancia entre ambos campos es en sí misma una señal de detección. |
| **Retest** | Verificar que la IP real sigue siendo recuperable desde `access.log` y que la discrepancia es detectable. |

> `203.0.113.0/24` es un rango reservado por el RFC 5737 para documentación: no
> corresponde a ningún sistema real.

---

### H11 · Denial of Service — ausencia de límite de tasa

| | |
|---|---|
| **Frontera** | TB1 · **Debilidad** D5 · **Responsable** Blue (revisión de configuración) |
| **Hipótesis** | Sin `limit_req`, nada frena la enumeración automatizada ni el consumo repetido de la API. |
| **Comando** | **No se ejecuta ninguna prueba de carga.** La validación es por **revisión de configuración**: `grep -c limit_req infra/nginx/incident-hub.baseline.conf` |
| **Resultado esperado** | `0` coincidencias en la línea base, `> 0` tras el hardening. |
| **Timestamp** | _(completar)_ |
| **Resultado observado** | _(completar)_ |
| **Interpretación** | _(completar)_ |
| **Corrección Lab 3** | `limit_req_zone` a 10 r/s por IP con ráfaga de 20 (C5). |
| **Retest** | Verificación por configuración. Cualquier prueba de carga requiere **autorización explícita del docente** y queda fuera del alcance por defecto. |

> **Por qué no se prueba:** la guía (§2) prohíbe la denegación de servicio sin
> excepciones. Verificar la ausencia del control por configuración es evidencia válida
> y no pone en riesgo el servicio ni sale del alcance.

---

## 6. Pruebas descartadas por alcance

| Prueba | Por qué se descarta | Alternativa aplicada |
|--------|---------------------|----------------------|
| MITM / ARP spoofing (H4) | §2 prohíbe interceptar tráfico de terceros | Demostrar la ausencia de TLS y de HSTS |
| Prueba de carga o flood (H11) | §2 prohíbe denegación de servicio | Revisión de configuración |
| Fuerza bruta | §2 lo prohíbe; además no hay autenticación que forzar | No aplica en Lab 3 |
| Escaneo de todos los puertos | El Paso 8 limita el alcance al puerto 80 | `nmap -p 80` |
| Active Scan de ZAP | El Paso 10 exige modo pasivo | Manual Explore + revisión de Alerts |
| Escaneo fuera de `LAB_CIDR` | §2 lo prohíbe expresamente | Objetivo único y autorizado |

---

## 7. Priorización

| Prioridad | Hipótesis | Criterio |
|-----------|-----------|----------|
| **1 — Crítica** | H9, H1 | Escritura sin identidad y exposición total del contenido. Impacto directo sobre integridad y confidencialidad. |
| **2 — Alta** | H5, H7, H8 | Fugas concretas, corregibles dentro del alcance del Lab 3. |
| **3 — Media** | H2, H6, H3, H10 | Reducen superficie o mejoran atribución; no exponen datos por sí solas. |
| **4 — Aceptada** | H4, H11 | Trasladadas al Lab 4 o verificadas por configuración. |

### Amenaza a priorizar en el Laboratorio 4

**Spoofing (H10) y la ausencia de autenticación que habilita H9.** La guía anticipa que
el Lab 4 trabajará *"certificados, identidad, sesiones, roles y escenarios de Spoofing"*.
H9 queda deliberadamente **sin corregir** en Lab 3 para que el Lab 4 tenga un punto de
partida medible: hoy cualquiera cierra un incidente sin identificarse.

---

## 8. Trazabilidad hipótesis ↔ debilidad ↔ evidencia

| Hipótesis | Debilidad | Corrección | Evidencia Red | Evidencia Blue | Retest |
|-----------|-----------|------------|---------------|----------------|--------|
| H1 | D6 | — (Lab 4) | `evidence/red/curl_alerts.txt` | `evidence/blue/lab3-http.pcap` | `evidence/retest/` |
| H2 | D1 | C1 | `evidence/red/curl_headers.txt` | `access.log` | `evidence/retest/headers_after.txt` |
| H3 | D9 | app | `evidence/red/curl_audit.txt` | `evidence/blue/access_correlacion.md` | `evidence/retest/audit_after.txt` |
| H4 | D6 | — (Lab 4) | `evidence/red/tls_ausente.txt` | — | `risk/register.md` |
| H5 | D4 | C4 | `evidence/red/hidden_paths.txt` | `access.log` (404/200) | `evidence/retest/hidden_path.txt` |
| H6 | D2 | C2 | `evidence/red/autoindex.txt` | `access.log` | `evidence/retest/autoindex_after.txt` |
| H7 | D8 | app | `evidence/red/debug_endpoint.json` | `access.log` | `evidence/retest/debug_after.txt` |
| H8 | D7 | app (Paso 16) | `evidence/red/alerts_keys.txt` | — | `evidence/retest/alerts_keys_after.txt` |
| H9 | authN/authZ | parcial | `evidence/red/assign_sin_auth.txt` | auditoría | `evidence/retest/assign_after.txt` |
| H10 | cabeceras | parcial | `evidence/red/xff_spoof.txt` | `evidence/blue/xff_discrepancia.md` | `evidence/retest/xff_after.txt` |
| H11 | D5 | C5 | — (no se ejecuta) | `evidence/blue/limit_req_config.txt` | `evidence/retest/limit_req_after.txt` |

---

**Documento elaborado en sesión conjunta.** El diagrama correspondiente está en
[`dfd-lab3.png`](dfd-lab3.png) (fuente editable: [`dfd-lab3.svg`](dfd-lab3.svg)).
