# Cómo contribuir a este repositorio

Este laboratorio se califica también por la **trazabilidad de las contribuciones
individuales** (regla 5 de la hoja *Resumen* del archivo de selección). Si todos
los commits salen a nombre de una sola persona, el docente no puede atribuir la
evidencia a cada integrante. Este documento evita ese problema.

## 1. Configurar tu identidad de Git (una sola vez, en tu equipo)

Cada integrante ejecuta esto **con su propio nombre y con el correo asociado a su
cuenta de GitHub**:

```bash
git config user.name "Tu Nombre Completo"
git config user.email "tu-correo-de-github@ejemplo.com"
```

> Usa `git config` sin `--global` para que aplique solo a este repositorio.

Para confirmar que quedó bien:

```bash
git config user.name && git config user.email
```

> **Importante:** si el correo no coincide con el de tu cuenta de GitHub, el commit
> aparecerá en el historial pero **no** se te atribuirá en el perfil ni en la
> pestaña *Contributors*. Verifica tus correos en
> <https://github.com/settings/emails>.

## 2. Quién commitea qué

| Carpeta | Responsable | Rol |
|---------|-------------|-----|
| `app/`, `infra/`, `deploy/` | José Luis Lancheros Ayora | Builder |
| `evidence/red/` | Juan David Gómez Cuellar | Red Team |
| `evidence/blue/` | Jeyder Nicolay León Lancheros | Blue Team |
| `evidence/retest/` | José Luis Lancheros Ayora | Purple / Fase F |
| `threat-model/` | Los tres | Sesión conjunta |
| `reflections/<nombre>.md` | Cada quien la suya | — |

Regla práctica: **si la evidencia la generaste tú, el commit lo haces tú.**

## 3. Formato de los mensajes de commit

```
lab3(<rol>): <qué se hizo>

<por qué / a qué paso de la guía corresponde>
```

Ejemplos reales del laboratorio:

```
lab3(red): reconocimiento nmap y curl sobre el objetivo autorizado
lab3(blue): captura PCAP y correlacion de access.log
lab3(builder): hardening inicial de Nginx (Paso 15)
```

## 4. Trabajo conjunto: trailers `Co-authored-by`

Cuando dos o tres trabajen sobre el mismo archivo en la misma sesión (por ejemplo
el modelo STRIDE), quien commitea añade a los demás al final del mensaje, después
de **una línea en blanco**:

```
lab3(threat-model): DFD y tabla STRIDE con cuatro hipotesis

Sesion conjunta de la Fase B. Cada hipotesis se conecta con las
debilidades D1-D9 de la linea base.

Co-authored-by: Juan David Gómez Cuellar <correo-de-juan@ejemplo.com>
Co-authored-by: Jeyder Nicolay León Lancheros <correo-de-jeyder@ejemplo.com>
```

GitHub muestra a los tres como autores del commit.

> ⚠️ Sustituyan los correos de ejemplo por los reales antes de usarlos. Un correo
> inventado hace que el trailer no atribuya a nadie.

## 5. Antes de entregar

```bash
# Verificar que los tres aparecen en el historial
git shortlog -sne

# Verificar que la evidencia no quedó excluida por .gitignore
git status --short evidence/

# Etiquetar la entrega final (Paso 18 de la guía)
git tag lab-3
git show --stat --oneline lab-3
```

`git shortlog -sne` debe listar **tres** autores distintos. Si aparece uno solo,
la regla 5 no se cumple y hay que redistribuir los commits antes del tag.

## 6. Datos que nunca deben entrar al repositorio

La guía es explícita en su §2 y §7:

- IP públicas reales, hostnames o usuarios reales.
- Tokens, credenciales o claves, aunque sean de prueba.
- PCAP con tráfico ajeno al laboratorio.
- Cualquier dato que no sea ficticio.

Todo dato del prototipo es inventado y así está marcado en cada archivo.
