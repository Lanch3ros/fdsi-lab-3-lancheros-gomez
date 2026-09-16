# Cómo probar el laboratorio en tu Mac (paso a paso)

Guía para ejecutar y verificar el laboratorio completo desde cero. No necesitas
las VM del profesor: todo corre en contenedores dentro de tu Mac, en una red
aislada `172.28.0.0/24`.

## Requisito único

**Docker Desktop** instalado y **abierto** (el icono de la ballena arriba a la
derecha, sin "starting"). Nada más: nmap, curl, tcpdump y ZAP van dentro de los
contenedores.

---

## Paso 0 — Situarse en el proyecto

```bash
cd ~/Desktop/fdsi-lab-3-lancheros-gomez
```

---

## Paso 1 — Levantar el laboratorio en LÍNEA BASE (estado inseguro)

```bash
HARDENED=0 docker compose -f infra/docker/compose.yml up -d --build
```

Espera a que terminen los tres contenedores. Comprueba que están arriba:

```bash
docker compose -f infra/docker/compose.yml ps
```

Deberías ver `incident-hub-web`, `incident-hub-api` y `redteam` en estado *Up*.

Abre el portal en el navegador:

```bash
open http://127.0.0.1:8080
```

---

## Paso 2 — Ver las fallas con tus propios ojos (línea base)

Cada comando de abajo demuestra una debilidad. Míralos uno por uno.

**El servidor revela su versión (D1):**

```bash
curl -sI http://127.0.0.1:8080/ | grep -i server
```
Esperado: `Server: nginx/1.27.5`

**Archivos privados descargables (D4):**

```bash
curl -i http://127.0.0.1:8080/.git/config
```
Esperado: `200 OK` y el contenido del archivo (no debería ser público).

**Registro de diagnóstico filtrando el entorno (D8):**

```bash
curl -s http://127.0.0.1:8080/api/v1/debug | python3 -m json.tool | head -20
```
Esperado: rutas internas y variables de entorno.

**La API entrega datos sensibles en el listado (D7):**

```bash
curl -s http://127.0.0.1:8080/api/v1/alerts | python3 -m json.tool | grep -E 'cmdline|user_name|sha256' | head
```
Esperado: aparecen `cmdline`, `user_name` y `sha256`.

**Falsificar el origen (D10 / H10):**

```bash
curl -s -o /dev/null http://127.0.0.1:8080/api/v1/alerts -H 'X-Forwarded-For: 203.0.113.99'; curl -s http://127.0.0.1:8080/api/v1/audit | python3 -m json.tool | tail -8
```
Esperado: la auditoría registra la IP falsa `203.0.113.99`.

---

## Paso 3 — Ronda Red Team automatizada (Juan)

Ejecuta toda la batería de reconocimiento desde el contenedor atacante. Genera la
evidencia en `evidence/red/` con timestamps.

```bash
bash scripts/run-red-team.sh
```

Revisa lo que quedó:

```bash
ls -1 evidence/red/
```

---

## Paso 4 — Ronda Blue Team: captura + detección (Jeyder)

> ⚠️ La captura tiene que estar **corriendo antes** de atacar. Para no coordinar
> varios comandos a mano, usa este único script que lo hace todo en orden:
> inicia tcpdump, lanza el ataque, cierra la captura y comprueba el resultado.

```bash
bash scripts/blue-pcap-demo.sh
```

Esperado al final:
`'composite_id' aparece 19 veces EN CLARO dentro del PCAP` → prueba de H1: el
contenido de las alertas se lee sin cifrar en la red.

Luego corre la regla de detección de 404 sobre los logs frescos:

```bash
bash scripts/blue-detect.sh evidence/blue/access.log
```

Esperado: una IP con muchos 404 y el aviso `SUPERA UMBRAL (>=5)`.

> Si prefieres hacerlo manual (los 4 pasos por separado), están al final de este
> archivo en el anexo "Captura manual paso a paso".

## Paso 5 — Aplicar el hardening (cambiar al estado ARREGLADO)

Un solo comando reconstruye todo en modo seguro:

```bash
HARDENED=1 docker compose -f infra/docker/compose.yml up -d --build
```

Confirma el modo:

```bash
docker logs incident-hub-web 2>&1 | grep lab3 | tail -1
```
Esperado: `configuracion ENDURECIDA (HARDENED=1)`.

---

## Paso 6 — Verificar el ANTES vs DESPUÉS (retest)

Repite las mismas pruebas del Paso 2. Ahora deben fallar para el atacante:

**Versión oculta (antes `nginx/1.27.5`):**

```bash
curl -sI http://127.0.0.1:8080/ | grep -i server
```
Esperado ahora: `Server: nginx` (sin número).

**Rutas ocultas bloqueadas (antes 200):**

```bash
curl -s -o /dev/null -w "/.git/config = %{http_code}\n" http://127.0.0.1:8080/.git/config
```
Esperado ahora: `404`.

**Diagnóstico eliminado y auditoría privada:**

```bash
curl -s -o /dev/null -w "/api/v1/debug = %{http_code}\n" http://127.0.0.1:8080/api/v1/debug; curl -s -o /dev/null -w "/api/v1/audit = %{http_code}\n" http://127.0.0.1:8080/api/v1/audit
```
Esperado: `debug = 404` y `audit = 403`.

**Headers de seguridad presentes:**

```bash
curl -sI http://127.0.0.1:8080/ | grep -iE 'x-content-type|x-frame|referrer'
```
Esperado: aparecen los tres.

O corre el retest completo de una:

```bash
docker cp scripts/retest.sh redteam:/tmp/retest.sh && docker exec -e TARGET_IP=172.28.0.10 redteam sh /tmp/retest.sh
```

---

## Paso 7 — Volver a la línea base (estado de entrega)

Deja el laboratorio como debe quedar entregado:

```bash
HARDENED=0 docker compose -f infra/docker/compose.yml up -d --build
```

---

## Paso 8 — (Opcional) Regenerar el reporte de ZAP

Escaneo pasivo real (tarda unos minutos; descarga ~1.5 GB la primera vez):

```bash
docker run --rm --network fdsi-lab3-g04_lab -v "$PWD/evidence/red/passive:/zap/wrk:rw" zaproxy/zap-stable zap-baseline.py -t http://172.28.0.10 -r zap-report.html || true
```

Abrir el reporte:

```bash
open evidence/red/passive/zap-report.html
```

---

## Apagar todo al terminar

Detiene los contenedores (borra también el tráfico capturado temporal):

```bash
docker compose -f infra/docker/compose.yml down -v
```

---

## Chuleta: ¿qué debería pasar en cada estado?

| Prueba | Línea base (HARDENED=0) | Endurecido (HARDENED=1) |
|--------|-------------------------|-------------------------|
| `Server:` | `nginx/1.27.5` | `nginx` |
| `/.git/config` | 200 | 404 |
| `/.env` | 200 | 404 |
| `/files/` | 200 (listado) | 403 |
| `/api/v1/debug` | 200 | 404 |
| `/api/v1/audit` | 200 (público) | 403 |
| Campos `cmdline/user_name/sha256` | presentes | ausentes del listado |
| Headers de seguridad | ausentes | presentes |
| Tráfico HTTP en claro | sí | **sí (no se corrige en Lab 3)** |

Si algún resultado no coincide, revisa en qué modo está el laboratorio con:
`docker logs incident-hub-web 2>&1 | grep lab3 | tail -1`


---

## Anexo — Captura manual paso a paso (alternativa al script)

Si quieres entender qué hace `blue-pcap-demo.sh` por dentro, son estos 4 comandos
**en este orden** (el error típico es saltarse el primero):

```bash
docker exec -d incident-hub-web sh -c 'rm -f /tmp/demo.pcap; timeout 40 tcpdump -i any -nn -s0 -w /tmp/demo.pcap "tcp port 80"'
```

```bash
bash scripts/run-red-team.sh >/dev/null 2>&1; echo "ataque enviado"
```

```bash
docker exec incident-hub-web sh -c 'kill $(pidof tcpdump) 2>/dev/null; sleep 2'; docker cp incident-hub-web:/tmp/demo.pcap evidence/blue/demo.pcap
```

```bash
docker exec incident-hub-web sh -c 'tcpdump -nn -A -r /tmp/demo.pcap 2>/dev/null' | grep -c composite_id
```

Si el último número es 0, es que **no arrancaste la captura antes de atacar**
(te saltaste el primer comando) o los contenedores estaban apagados.
