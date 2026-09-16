# Uso responsable de IA (§7 de la guía)

La guía permite usar IA como **copiloto analítico**, nunca como autoridad. Cada
afirmación debe verificarse contra comandos, logs, PCAP o configuración. Este
documento registra el prompt usado, con datos **anonimizados**, y marca qué
respuestas pudieron comprobarse y cuáles no.

## Prompt utilizado (anonimizado)

> Analiza estos eventos Nginx anonimizados. Construye una línea de tiempo, separa
> hechos de inferencias, mapea cada observación a STRIDE, propone tres hipótesis
> defensivas y señala qué evidencia adicional falta. No inventes IP, CVE ni
> acciones ejecutadas.

**Fragmento de log entregado a la IA (IP sustituida por `RED_IP`):**

```
RED_IP - - [.../Sep/2026:.. +0000] "GET /.git/config HTTP/1.1" 200 106 "-" "curl/*"
RED_IP - - [.../Sep/2026:.. +0000] "GET /api/v1/debug HTTP/1.1" 200 ... "-" "curl/*"
RED_IP - - [.../Sep/2026:.. +0000] "GET /wp-login.php HTTP/1.1" 404 ... "-" "curl/*"
RED_IP - - [.../Sep/2026:.. +0000] "GET /phpinfo.php HTTP/1.1" 404 ... "-" "curl/*"
```

## Validación humana de la respuesta

| Afirmación de la IA | ¿Comprobable? | Evidencia que la confirma o refuta |
|---------------------|---------------|-------------------------------------|
| "El `GET /.git/config → 200` indica exposición de repositorio" | ✅ Sí | `evidence/red/hidden_paths.txt` muestra el 200 y el cuerpo servido |
| "La ráfaga de 404 sugiere enumeración automatizada" | ✅ Sí | `evidence/blue/deteccion-404.txt`: 16 × 404 desde una IP |
| "El User-Agent `curl/*` confirma automatización" | ⚠️ Parcial | `curl` puede falsificar su User-Agent; es indicio, no prueba |
| "Podría existir un CVE en la versión de Nginx expuesta" | ❌ No verificable | No se probó ningún CVE; la guía prohíbe explotación. Se marca como **no comprobado** |
| "El servidor podría estar comprometido por un webshell" | ❌ Alucinación | No hay evidencia de webshell; ninguna ruta lo indica. **Descartada** |

## Reglas cumplidas (§7)

- ✅ No se enviaron PCAP completos a servicios públicos.
- ✅ Se sustituyeron IP, hostnames y cualquier dato sensible (aquí ya son ficticios).
- ✅ Prompt y respuesta quedan adjuntos como evidencia.
- ✅ Se marcaron explícitamente las alucinaciones detectadas.

**Conclusión:** la IA ayudó a ordenar la narrativa, pero dos de sus afirmaciones
(CVE y webshell) no pudieron comprobarse y se descartaron. La calificación
depende de esta validación humana, no de la extensión del texto generado.
