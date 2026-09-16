# Reflexión individual — Juan David Gómez Cuellar

**Rol en el Laboratorio 3:** 🔴 Red Team
**Grupo:** G03+G04 · **Temática:** CrowdStrike Incident Hub
**Fecha:** _(completar)_

> ⚠️ BORRADOR para personalizar. Reescríbelo con tus propias palabras: la guía
> (§8) califica la validación humana, no el texto generado. Borra este aviso y
> ajusta el conteo a ≤250 palabras.

Como Red Team confirmé, sin explotar nada, cuánto revela un servicio HTTP sin
autenticación. Con `nmap -sV` y `curl` identifiqué la versión de Nginx y de la
API (`evidence/red/curl_headers_api.txt`), descargué `/.git/config` y `/.env`
(200 OK) y leí el entorno del proceso en `/api/v1/debug`. Lo que más me
sorprendió fue que el simple listado de alertas entregaba `cmdline`, `user_name`
y `sha256`: información sensible que ninguna vista de triage necesita. También
comprobé que un `POST /assign` cambia el estado de una alerta sin pedir
credenciales, y que enviando `X-Forwarded-For: 203.0.113.99` la auditoría de la
aplicación registraba una IP falsa. El control que aplicamos y que reduce
exposición pero no resuelve el problema de fondo fue el hardening de cabeceras y
`server_tokens off`: el tráfico sigue viajando en claro, así que la
confidencialidad depende todavía de pasar a HTTPS en el Lab 4. Usé IA para
ordenar la narrativa de los hallazgos, pero descarté dos afirmaciones suyas —un
supuesto CVE y un webshell— porque no pude comprobarlas contra ninguna evidencia.
La amenaza que priorizaría para el Lab 4 es la ausencia de identidad
(Spoofing/Elevation of Privilege): mientras cualquiera pueda cerrar un incidente
sin autenticarse, el resto de controles es secundario.

---
**Conteo de palabras:** _(completar — máximo 250)_
