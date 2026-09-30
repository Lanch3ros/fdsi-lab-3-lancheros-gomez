# Reflexión individual — Juan David Gómez Cuellar

**Rol en el Laboratorio 3:** 🔴 Red Team
**Grupo:** G03+G04 · **Temática:** CrowdStrike Incident Hub
**Fecha:** 2026-09-30

Como Red Team lo que más me marcó fue darme cuenta de cuánta información puede
obtener un atacante sin explotar una sola vulnerabilidad, solo leyendo lo que el
servicio entrega. Con `nmap` y `curl` confirmé la versión exacta de Nginx y de la
API, descargué `/.git/config` y `/.env`, y leí el entorno del proceso en
`/api/v1/debug`. Me sorprendió que el listado de alertas devolviera `cmdline`,
`user_name` y `sha256`: datos que un analista no necesita para hacer triage y que
amplían la superficie de exposición sin razón.

Entendí que el control que aplicamos después —quitar el banner de versión y
endurecer cabeceras— reduce pistas para el atacante, pero no resuelve el problema
de fondo: mientras el transporte siga siendo HTTP, todo viaja en claro. Eso solo
se cierra con HTTPS, que implementamos en la fase de mitigación.

Usé IA para ordenar la narrativa de los hallazgos, pero tuve que descartar dos de
sus afirmaciones —un supuesto CVE de Nginx y un posible webshell— porque no pude
comprobarlas contra ningún comando ni log; fueron alucinaciones. Para el
Laboratorio 4 priorizaría la ausencia de identidad (Spoofing y escritura sin
autenticación): mientras cualquiera pueda cerrar un incidente sin identificarse,
los demás controles quedan en segundo plano.

---
**Conteo de palabras:** 218 (máximo 250)
