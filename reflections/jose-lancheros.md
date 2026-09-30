# Reflexión individual — José Luis Lancheros Ayora

**Rol en el Laboratorio 3:** 🟣 Builder / Security Lead (Fase F)
**Grupo:** G03+G04 · **Temática:** CrowdStrike Incident Hub
**Fecha:** 2026-09-30

Como Builder y responsable de la verificación, mi mayor aprendizaje fue que una
corrección solo vale si es reproducible. Construí la aplicación y su
infraestructura de modo que el estado inseguro y el endurecido se activaran con
una sola variable, para que el antes y el después no dependieran de capturas sino
de volver a ejecutar las mismas pruebas. En el retest confirmé que, tras el
hardening, el servidor dejaba de exponer su versión, que las rutas ocultas y el
endpoint de diagnóstico pasaban a 404 y que los campos sensibles desaparecían del
listado.

El control que reduce exposición pero no resuelve el riesgo de fondo es
precisamente ese hardening: por más cabeceras que agregue, mientras el transporte
sea HTTP la confidencialidad no está garantizada. Por eso registré ese riesgo como
aceptado y en la fase de mitigación implementé TLS; validarlo en Wireshark, viendo
el tráfico pasar de texto plano a datos cifrados, fue la confirmación más clara de
que la mitigación funcionaba.

Coordinar a los tres me obligó a cuidar la trazabilidad: que cada evidencia
quedara atribuida a quien la generó y que ningún dato real entrara al repositorio.
Para el Laboratorio 4 priorizaría la autenticación y la autorización: dejamos
medible que hoy cualquiera puede cerrar un incidente sin identidad, y ese será el
punto de partida para trabajar identidad, sesiones y roles.

---
**Conteo de palabras:** 233 (máximo 250)
