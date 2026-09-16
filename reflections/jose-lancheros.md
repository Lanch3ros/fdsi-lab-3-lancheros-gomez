# Reflexión individual — José Luis Lancheros Ayora

**Rol en el Laboratorio 3:** 🟣 Builder / Security Lead (Fase F)
**Grupo:** G03+G04 · **Temática:** CrowdStrike Incident Hub
**Fecha:** _(completar)_

> ⚠️ BORRADOR para personalizar. Reescríbelo con tus propias palabras: la guía
> (§8) califica la validación humana, no el texto generado. Borra este aviso y
> ajusta el conteo a ≤250 palabras.

Como Builder y responsable de la verificación, mi aprendizaje fue que una
corrección solo vale si es reproducible. Construí la aplicación y su
infraestructura de forma que el estado inseguro y el endurecido se activaran con
una sola variable (`HARDENED`), para que la comparación antes/después no
dependiera de capturas sino de volver a ejecutar las pruebas. En el retest
confirmé que tras el hardening el servidor deja de exponer su versión, que
`/.git/config`, `/.env` y `/api/v1/debug` pasan a 404 y que los campos sensibles
desaparecen del listado (`evidence/retest/comparacion-antes-despues.md`). El
control que reduce exposición pero no resuelve el riesgo de fondo es precisamente
ese hardening: por más cabeceras que agregue, mientras el transporte siga siendo
HTTP la confidencialidad no está garantizada, y por eso registré D6 como riesgo
aceptado y trasladado al Lab 4. Coordinar el trabajo de los tres me obligó a
cuidar la trazabilidad: que cada evidencia quedara atribuida a quien la generó y
que ningún dato real entrara al repositorio. La amenaza que priorizaría para el
Lab 4 es la falta de autenticación y autorización: dejamos deliberadamente medible
que hoy cualquiera puede cerrar un incidente sin identidad, y ese será el punto de
partida para introducir certificados, sesiones y roles.

---
**Conteo de palabras:** _(completar — máximo 250)_
