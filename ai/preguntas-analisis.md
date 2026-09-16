# Preguntas de análisis (§12 de la guía)

Respuestas del equipo, respaldadas en la evidencia recogida.

**1. ¿Qué pudo observar el Red Team sin explotar ninguna vulnerabilidad?**
Versión del servidor y de la API (banners), el listado de `/files/`, el contenido
de `/.git/config` y `/.env`, el entorno del proceso vía `/api/v1/debug`, y el
JSON completo de alertas con campos sensibles (`cmdline`, `user_name`, `sha256`).
Todo con peticiones GET de solo lectura. Evidencia: `evidence/red/`.

**2. ¿Qué pruebas de red no aparecieron en access.log y por qué?**
El escaneo `nmap -sV` a nivel TCP. Nginx solo registra peticiones HTTP completas;
el descubrimiento de puerto y las sondas de versión que no forman una petición
HTTP válida quedan fuera de `access.log`. Se ven en telemetría de **red** (PCAP,
firewall), no de **aplicación**. Evidencia: `evidence/blue/timeline-purple.md`.

**3. ¿Qué control aplicado reduce exposición pero NO resuelve el riesgo de HTTP?**
El hardening de Nginx (headers, `server_tokens off`, bloqueo de rutas ocultas)
reduce metadatos y superficie, pero el tráfico **sigue en claro**. La
confidencialidad e integridad en tránsito (D6) solo se resuelven con HTTPS, que
es del Lab 4. Evidencia: `evidence/retest/comparacion-antes-despues.md`.

**4. ¿Qué datos necesitaría Blue Team para distinguir curl legítimo de actividad
sospechosa?**
Frecuencia y volumen por IP, patrón de rutas (existentes vs. inexistentes),
User-Agent, horario respecto a la ventana autorizada, y correlación con una lista
de IP conocidas del laboratorio. Un `curl` aislado a `/` es normal; 16 rutas
inexistentes en segundos, no. Evidencia: `evidence/blue/correlacion.md`.

**5. ¿Qué amenaza STRIDE debe priorizarse en el Laboratorio 4?**
**Spoofing** y la ausencia de autenticación/autorización (Elevation of Privilege,
H9). Hoy cualquiera cierra un incidente sin identificarse y puede falsear su
origen. El Lab 4 introduce identidad, sesiones y roles. Evidencia:
`threat-model/stride.md` §7.

**6. ¿Qué conclusión propuesta por la IA no pudo comprobarse directamente?**
Dos: la posible existencia de un CVE en la versión de Nginx (no se probó ninguna
explotación, prohibida por la guía) y la sugerencia de un webshell (sin evidencia
alguna, descartada como alucinación). Evidencia: `ai/uso-responsable-ia.md`.
