# CrowdStrike Incident Hub — FDSI Laboratorio 3

Prototipo académico publicado **por HTTP y sin autenticación** para el
Laboratorio 3 de Fundamentos de Seguridad de la Información: construir, atacar,
detectar, corregir y verificar.

> ### ⚠️ Todos los datos son ficticios
> Este servicio **no** se integra con CrowdStrike Falcon ni con ningún entorno
> real. Hostnames, IP, usuarios, hashes y alertas son inventados. La ausencia de
> HTTPS y de autenticación es **intencional**: es la línea base que el
> laboratorio exige analizar. Uso académico autorizado, dentro del alcance y la
> ventana definidos por el docente.

| | |
|---|---|
| **Grupos** | G03 + G04 (fusionados con autorización del docente — ver [`TEAM.md`](TEAM.md)) |
| **Temática** | CrowdStrike Incident Hub (Opción 1) |
| **Integrantes** | Juan David Gómez Cuellar 🔴 Red · Jeyder Nicolay León Lancheros 🔵 Blue · José Luis Lancheros Ayora 🟣 Builder/Security Lead |
| **Tag de entrega** | `lab-3` |

## Arquitectura

```
                    FRONTERA 1                      FRONTERA 2
                  (red externa /                  (Nginx / aplicación)
                   red del lab)
                        │                                │
  ┌──────────────┐      │      ┌──────────────────┐      │      ┌─────────────────┐
  │  Red Team    │      │      │  incident-hub-   │      │      │ incident-hub-   │
  │  (Kali /     │──────┼─────▶│  web             │──────┼─────▶│ api             │
  │  redteam)    │ HTTP │      │  Nginx :80       │ HTTP │      │ Flask :8000     │
  │ 172.28.0.30  │  80  │      │  172.28.0.10     │ 8000 │      │ 172.28.0.20     │
  └──────────────┘      │      └────────┬─────────┘      │      └────────┬────────┘
                        │               │                │               │
                        │      ┌────────▼─────────┐      │      ┌────────▼────────┐
                        │      │ access.log       │      │      │ alerts.json     │
                        │      │ error.log        │      │      │ (datos falsos)  │
                        │      └──────────────────┘      │      └─────────────────┘
                        │               ▲
                        │               │ observa
                        │      ┌────────┴─────────┐
                        │      │   Blue Team      │
                        │      │ tcpdump + logs   │
                        │      └──────────────────┘
```

El diagrama de flujo de datos formal, con las fronteras de confianza y su
justificación, está en [`threat-model/`](threat-model/).

## Estructura del repositorio

```
├── app/
│   ├── static/         Portal HTML e inventario público
│   └── api/            API Flask + dataset de alertas ficticias
├── infra/
│   ├── nginx/          Configuración baseline (ANTES) y hardened (DESPUÉS)
│   └── docker/         Topología del laboratorio en contenedores
├── deploy/             Despliegue sobre Ubuntu Server real
├── threat-model/       DFD, fronteras de confianza y tabla STRIDE
├── evidence/
│   ├── red/            Nmap, curl y reporte ZAP pasivo
│   ├── blue/           Logs, PCAP y regla de detección
│   └── retest/         Verificación posterior al hardening
├── risk/               Registro de riesgos (corregido/mitigado/aceptado/Lab 4)
├── reflections/        Reflexión individual de cada integrante
└── scripts/            Automatización reproducible de las pruebas
```

## Variables del laboratorio

Acordar **antes** de empezar (§3 de la guía):

```bash
export TARGET_IP=172.28.0.10          # host del Incident Hub
export TARGET_URL=http://$TARGET_IP
export LAB_CIDR=172.28.0.0/24         # único segmento autorizado
date -u +%Y-%m-%dT%H:%M:%SZ           # timestamp de cada evidencia
```

> Al trabajar sobre VM asignadas por el docente, sustituir estos valores por la
> IP y el CIDR autorizados. **Nunca** ampliar el alcance sin autorización.

## Reproducción

### Opción A — Laboratorio en contenedores

Requiere Docker. Levanta los tres componentes en una red aislada `172.28.0.0/24`.

```bash
cd infra/docker && docker compose up -d --build
```

Acceso desde el equipo anfitrión: <http://127.0.0.1:8080>
Acceso desde la estación ofensiva: `docker exec -it redteam bash`

Detener y limpiar:

```bash
cd infra/docker && docker compose down -v
```

### Opción B — Ubuntu Server + Kali

Ver [`deploy/`](deploy/) para el procedimiento equivalente sobre máquinas reales.

## Comparación antes / después

Las correcciones del Paso 15 se activan con una variable, de modo que el docente
pueda **reproducir ambos estados** en lugar de confiar en capturas:

| Estado | Comando | Configuración de Nginx |
|--------|---------|------------------------|
| **ANTES** (línea base) | `HARDENED=0 docker compose up -d --build` | `infra/nginx/incident-hub.baseline.conf` |
| **DESPUÉS** (hardening) | `HARDENED=1 docker compose up -d --build` | `infra/nginx/incident-hub.hardened.conf` |

El `diff` entre ambas configuraciones documenta cada corrección y la debilidad
que resuelve:

```bash
diff -u infra/nginx/incident-hub.baseline.conf infra/nginx/incident-hub.hardened.conf
```

## Endpoints publicados

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/` | Portal del Incident Hub |
| GET | `/public-inventory.txt` | Inventario público de demostración |
| GET | `/api/v1/health` | Estado del servicio |
| GET | `/api/v1/alerts` | Listado de alertas ficticias |
| GET | `/api/v1/alerts/{composite_id}` | Detalle de una alerta |
| POST | `/api/v1/alerts/aggregates` | Agregación por campo |
| POST | `/api/v1/alerts/{composite_id}/assign` | Asignación a un analista |
| GET | `/api/v1/audit` | Registro de acciones |
| GET | `/api/v1/debug` | Diagnóstico *(solo en la línea base)* |

## Alcance y ética

- Solo se prueba contra `LAB_CIDR`, dentro de la ventana autorizada.
- Sin denegación de servicio, fuerza bruta, explotación destructiva ni persistencia.
- Palabra de seguridad para detener cualquier prueba: **`STOP-LAB`**.
- Todo dato es ficticio; nada se anonimiza porque nada es real.
- Uso de IA: prompts y respuestas se adjuntan como evidencia, con las
  afirmaciones no verificables marcadas explícitamente (§7 de la guía).

## Documentos del equipo

- [`TEAM.md`](TEAM.md) — integrantes, roles y nota sobre el registro G03/G04
- [`CONTRIBUTING.md`](CONTRIBUTING.md) — trazabilidad de contribuciones individuales
