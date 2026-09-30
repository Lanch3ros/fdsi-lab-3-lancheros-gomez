# Guion de demostración en vivo — FDSI Laboratorio 3

**Grupos G03+G04 · CrowdStrike Incident Hub**

Guion para mostrarle al profesor el laboratorio **corriendo en el equipo**, no
solo el código. Duración objetivo: **~5 minutos**. Narra el ciclo completo:
construir → atacar → detectar → corregir → mitigar.

> Ensayen el guion completo una vez antes de la presentación, cronometrando. Cada
> `docker compose ... --build` tarda ~30 segundos.

---

## Preparación (antes de que llegue el profesor)

1. **Docker Desktop abierto** (icono de la ballena, sin "starting").
2. **Wireshark instalado** (para los actos 3 y 5; se usan capturas ya guardadas).
3. Este archivo y [`PRUEBAS.md`](PRUEBAS.md) abiertos como chuleta.
4. Situarse en el proyecto:

```bash
cd ~/Desktop/fdsi-lab-3-lancheros-gomez
```

5. Dejar el laboratorio encendido en línea base:

```bash
HARDENED=0 docker compose -f infra/docker/compose.yml up -d --build
```

Verificar que responde (debe decir 200):

```bash
curl -s -o /dev/null -w "app -> %{http_code}\n" http://127.0.0.1:8080/
```

---

## Acto 1 — "Esta es la aplicación, insegura a propósito" (30 s)

```bash
open http://127.0.0.1:8080
```

**Decir:** *"Es un prototipo de un panel tipo CrowdStrike, con datos 100%
ficticios. Lo publicamos por HTTP y sin autenticación de forma intencional,
porque el laboratorio consiste en analizar los riesgos de esa configuración."*

---

## Acto 2 — "Estas son las fallas" (60 s)

El servidor revela su versión exacta:

```bash
curl -sI http://127.0.0.1:8080/ | grep -i server
```

Un archivo interno que **no** debería ser público, y se descarga:

```bash
curl -i http://127.0.0.1:8080/.git/config
```

Un endpoint de diagnóstico olvidado que filtra el entorno:

```bash
curl -s http://127.0.0.1:8080/api/v1/debug | python3 -m json.tool | head -15
```

**Decir:** *"Sin explotar nada, solo leyendo, ya obtuvimos la versión del
servidor, un archivo de configuración y variables internas. Son los hallazgos
H2, H5 y H7 de nuestro modelo STRIDE."*

---

## Acto 3 — "El tráfico viaja en texto plano" (60 s)

Abrir la captura ya hecha en Wireshark:

```bash
open -a Wireshark evidence/blue/wireshark/wireshark-demo.pcap
```

En Wireshark: filtro `http` → clic derecho en `GET /api/v1/alerts` →
**Follow → HTTP Stream**.

**Decir:** *"Aquí está el tráfico capturado. Siguiendo el flujo HTTP se lee la
respuesta completa en texto plano: el usuario, el comando ejecutado, el hash. Es
el hallazgo H1: por HTTP no hay confidencialidad, cualquiera en la red lo lee."*

> La captura en vivo con Wireshark pide un permiso del sistema (ChmodBPF); por eso
> usamos la captura guardada, que muestra exactamente el mismo tráfico del
> ejercicio (Red Team 172.28.0.30 → servidor 172.28.0.10).

---

## Acto 4 — "Aplicamos las correcciones" (60 s)

Cambiar al estado endurecido (un solo comando):

```bash
HARDENED=1 docker compose -f infra/docker/compose.yml up -d --build
```

Repetir la misma falla del Acto 2 — ahora está cerrada:

```bash
curl -sI http://127.0.0.1:8080/ | grep -i server
curl -s -o /dev/null -w "/.git/config = %{http_code}\n" http://127.0.0.1:8080/.git/config
curl -s -o /dev/null -w "/api/v1/debug = %{http_code}\n" http://127.0.0.1:8080/api/v1/debug
```

**Decir:** *"El servidor ya no muestra la versión, `/.git/config` pasó de 200 a
404 y el endpoint de diagnóstico desapareció. Es el mismo código; solo cambiamos
una variable, así que el antes/después es totalmente reproducible."*

---

## Acto 5 — "La mitigación final: cifrado con TLS" (60 s)

Activar la capa de mitigación con HTTPS:

```bash
HARDENED=1 TLS=1 docker compose -f infra/docker/compose.yml up -d --build
```

Mostrar que ahora hay HTTPS y que HTTP redirige:

```bash
curl -sk -o /dev/null -w "HTTPS 8443 -> %{http_code}\n" https://127.0.0.1:8443/api/v1/health
curl -sI http://127.0.0.1:8080/ | grep -iE 'HTTP/|location'
```

Abrir la captura cifrada en Wireshark (filtro `tls`):

```bash
open -a Wireshark evidence/blue/wireshark/tls-mitigado.pcap
```

**Decir:** *"El mismo contenido que en el Acto 3 se leía en claro, ahora viaja
cifrado: Wireshark solo ve TLS y datos ilegibles. La amenaza de divulgación en
tránsito queda mitigada, y lo comprobamos con evidencia reproducible."*

---

## Cierre (30 s)

**Decir:** *"El único riesgo que dejamos abierto a propósito es la escritura sin
autenticación: hace falta identidad y roles, que corresponden al Laboratorio 4.
Queda registrado en `risk/register.md`. Todo el recorrido está documentado en el
README y en la matriz STRIDE."*

Volver el laboratorio al estado de entrega:

```bash
HARDENED=0 docker compose -f infra/docker/compose.yml up -d --build
```

---

## Si algo falla durante el demo

| Síntoma | Solución rápida |
|---------|-----------------|
| La app no responde | `docker compose -f infra/docker/compose.yml up -d --build` y esperar 15 s |
| Wireshark pide permiso al capturar | No capturar en vivo; abrir los `.pcap` guardados (File → Open) |
| No sé en qué modo está | `docker logs incident-hub-web 2>&1 \| grep lab3 \| tail -1` |
| Quiero reiniciar todo limpio | `docker compose -f infra/docker/compose.yml down -v` y volver a levantar |

## Preguntas que puede hacer el profesor y dónde está la respuesta

| Pregunta | Dónde |
|----------|-------|
| ¿Cómo modelaron las amenazas? | [`threat-model/stride.md`](threat-model/stride.md) y el DFD |
| ¿Qué encontró el Red Team? | [`evidence/red/`](evidence/red/) y [README §5](README.md) |
| ¿Cómo lo detectaron? | [`evidence/blue/correlacion.md`](evidence/blue/correlacion.md) |
| ¿Qué riesgos quedan? | [`risk/register.md`](risk/register.md) |
| ¿Cómo diseñaron la mitigación? | [`MITIGACIONES.md`](MITIGACIONES.md) |
