# Reflexión individual — Jeyder Nicolay León Lancheros

**Rol en el Laboratorio 3:** 🔵 Blue Team
**Grupo:** G03+G04 · **Temática:** CrowdStrike Incident Hub
**Fecha:** _(completar)_

> ⚠️ BORRADOR para personalizar. Reescríbelo con tus propias palabras: la guía
> (§8) califica la validación humana, no el texto generado. Borra este aviso y
> ajusta el conteo a ≤250 palabras.

Desde el Blue Team entendí la diferencia entre ver la red y ver la aplicación.
Con `tcpdump` capturé el tráfico del ejercicio y, al leer el PCAP, encontré el
JSON de alertas completamente legible: `composite_id` y los usuarios
`svc_lab_a/b/c` aparecían en claro (`evidence/blue/pcap-lectura-ascii.txt`). Eso
me demostró por qué HTTP no ofrece confidencialidad. En `access.log` correlacioné
las acciones del Red Team con sus horas y construí una regla de detección: cinco
o más respuestas 404 desde una misma IP en cinco minutos. Disparó con 16 errores
404 desde `172.28.0.30`. Lo interesante fue reconocer sus límites: un usuario que
teclea mal una URL también genera 404, y la fuga de `/.git/config` devolvía 200,
así que esa regla sola no la habría detectado. Lo que más me marcó fue el caso de
la IP falsificada: la auditoría de la aplicación se creyó el `X-Forwarded-For`,
pero `access.log` conservó la IP real, y esa discrepancia entre ambas fuentes es
lo que permite detectar el engaño. Comprobé también que el escaneo `nmap` no
aparecía en `access.log`, porque opera a nivel TCP y Nginx solo registra
peticiones HTTP completas. Para el Lab 4 priorizaría el Spoofing: sin identidad
real, la atribución siempre dependerá de datos que el cliente puede manipular.

---
**Conteo de palabras:** _(completar — máximo 250)_
