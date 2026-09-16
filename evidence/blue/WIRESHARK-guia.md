# Capturar tráfico plano con Wireshark (Paso 11)

**"Tráfico plano"** = tráfico sin cifrar. El objetivo es mostrar en Wireshark que
por HTTP el contenido (peticiones y respuestas de la API) viaja en **texto
legible**, sin ninguna protección. Es la evidencia visual del hallazgo **H1**.

Hay dos formas. La **B** es a prueba de fallos (abrir un archivo); la **A** es en
vivo y más vistosa. Recomendado: preparar la B por si acaso, e intentar la A.

---

## Opción A — Captura EN VIVO sobre el loopback (recomendada para la demo)

El puerto 8080 está publicado en `127.0.0.1` de tu Mac, así que el tráfico hacia
`http://127.0.0.1:8080` pasa por la interfaz de loopback y Wireshark puede verlo.

### 1. Asegúrate de que el laboratorio esté en línea base

```bash
HARDENED=0 docker compose -f infra/docker/compose.yml up -d --build
```

### 2. Abre Wireshark y elige la interfaz de loopback

- Abre **Wireshark**.
- En la lista de interfaces, selecciona **Loopback: lo0**
  (en macOS aparece como `lo0`; si dudas, es la que tiene tráfico al usar
  `127.0.0.1`).
- Antes de iniciar, escribe en el campo **Capture filter** (barra superior):
  `tcp port 8080`
  Esto limita la captura al tráfico del laboratorio (solo tráfico del lab, como
  exige la guía).
- Pulsa el botón azul de **aleta de tiburón** (Start capturing).

### 3. Genera tráfico (en la terminal, mientras Wireshark captura)

```bash
curl http://127.0.0.1:8080/api/v1/alerts
```

Y un par más para tener variedad:

```bash
curl http://127.0.0.1:8080/ ; curl http://127.0.0.1:8080/.git/config
```

### 4. Detén la captura y filtra

- Pulsa el botón rojo (Stop).
- En el campo **Display filter** (barra bajo los botones) escribe: `http`
  y pulsa Enter. Verás solo las peticiones y respuestas HTTP.

### 5. Muestra el contenido en claro (lo importante)

- Haz **clic derecho** sobre la línea `GET /api/v1/alerts` →
  **Follow → HTTP Stream** (o **Seguir → Flujo HTTP**).
- Se abre una ventana con **toda la conversación en texto legible**: la petición
  y la respuesta con el JSON de alertas, incluyendo `cmdline`, `user_name`,
  `sha256`. **Eso es el tráfico plano.**
- En rojo aparece lo que envió el cliente y en azul lo que respondió el servidor.

> Captura de pantalla sugerida para la evidencia: la ventana "Follow HTTP Stream"
> mostrando el JSON de alertas legible.

---

## Opción B — Abrir la captura ya hecha (a prueba de fallos)

Si la interfaz de loopback no muestra tráfico en tu equipo (a veces Docker Desktop
enruta distinto), usa la captura que ya está en el repositorio, tomada dentro del
host de la aplicación.

### 1. Abre el archivo en Wireshark

- **Wireshark → File → Open** →
  `evidence/blue/wireshark-demo.pcap`
  (o `evidence/blue/lab3-http.pcap`, la del ejercicio completo).

### 2. Filtra y sigue el flujo

- Display filter: `http` → Enter.
- Clic derecho en `GET /api/v1/alerts` → **Follow → HTTP Stream**.
- Verás el mismo contenido en claro.

> Nota técnica: estas capturas usan "Linux cooked capture (SLL2)" porque se
> tomaron con `tcpdump -i any` dentro del contenedor. Wireshark las abre sin
> problema; solo cambia el encabezado de enlace, no el contenido HTTP.

---

## Qué decirle al profesor

> "Capturamos el tráfico del laboratorio con Wireshark filtrando por HTTP. Al
> seguir el flujo de `GET /api/v1/alerts` se ve la respuesta completa en texto
> plano: los campos `cmdline`, `user_name` y `sha256` de las alertas viajan sin
> cifrar. Esto demuestra el hallazgo H1: por HTTP no hay confidencialidad, y
> cualquier observador de la red lee el contenido sin descifrar nada. El control
> que lo resuelve —HTTPS— pertenece al Laboratorio 4, así que lo registramos como
> riesgo aceptado."

## Contraste antes/después (opcional, potente)

Si quieres cerrar el punto: repite la captura y observa que **el tráfico sigue en
claro incluso con `HARDENED=1`**. El hardening del Lab 3 mejora cabeceras y cierra
rutas, pero **no** cifra el transporte. Eso confirma que la confidencialidad queda
pendiente para el Lab 4 — exactamente el límite pedagógico de la guía.
