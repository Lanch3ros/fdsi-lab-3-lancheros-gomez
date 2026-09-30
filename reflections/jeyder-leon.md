# Reflexión individual — Jeyder Nicolay León Lancheros

**Rol en el Laboratorio 3:** 🔵 Blue Team
**Grupo:** G03+G04 · **Temática:** CrowdStrike Incident Hub
**Fecha:** 2026-09-30

Desde el Blue Team aprendí a diferenciar entre ver la red y ver la aplicación.
Capturé el tráfico con tcpdump y, al abrir el PCAP en Wireshark y seguir el flujo
HTTP, encontré el JSON de las alertas completamente legible: se leían el usuario
`svc_lab_a`, el comando ejecutado y hasta el hash. Esa imagen me dejó claro por
qué HTTP no ofrece confidencialidad; ya no es teoría, lo vi en texto plano.

Sobre `access.log` construí una regla de detección sencilla —cinco o más
respuestas 404 desde una misma IP— y disparó con las 16 peticiones de la
enumeración del Red Team. Lo valioso fue reconocer sus límites: un usuario que
teclea mal una URL también genera 404, y la descarga de `/.git/config` devolvía
200, así que esa regla por sí sola no la habría detectado.

Lo que más me sorprendió fue el caso de la IP falsificada: la auditoría de la app
se creyó el `X-Forwarded-For`, pero `access.log` conservó la IP real, y esa
diferencia entre las dos fuentes es justo lo que permite detectar el engaño.
También noté que el escaneo de `nmap` no aparecía en el log, porque actúa a nivel
de red y no como petición HTTP. Para el Lab 4 priorizaría el Spoofing: sin
identidad real, la atribución siempre dependerá de datos manipulables.

---
**Conteo de palabras:** 221 (máximo 250)
