# Equipo — FDSI Laboratorio 3

**Repositorio:** `Lanch3ros/fdsi-lab-3-lancheros-gomez`
**Temática:** CrowdStrike Incident Hub (Opción 1)
**Grupos registrados:** G03 + G04 (fusionados con autorización del docente)

## Integrantes y roles del Laboratorio 3

| ID | Integrante | Rol Lab 3 | Responsabilidad según la guía (§4) |
|----|-----------|-----------|-------------------------------------|
| E12 | Juan David Gómez Cuellar | 🔴 **Red Team** | Plantear hipótesis y ejecutar las pruebas autorizadas (Fase C) |
| E09 | Jeyder Nicolay León Lancheros | 🔵 **Blue Team** | Capturar tráfico, revisar logs y construir detecciones (Fases D y E) |
| E11 | José Luis Lancheros Ayora | 🟣 **Builder / Security Lead** | Publicar el sitio, mantener el repositorio, controlar el alcance y ejecutar la verificación final (Fases A y F) |

## Nota sobre el registro en el archivo de selección

El archivo `Seleccion_Parejas_y_Tematica.xlsx` registra a este equipo en **dos filas
separadas**, ambas apuntando a este mismo repositorio:

| Grupo | Integrante 1 | Rol | Integrante 2 | Rol |
|-------|--------------|-----|--------------|-----|
| G03 | Jeyder Nicolay León Lancheros (E09) | Blue Team | José Luis Lancheros Ayora (E11) | Red Team |
| G04 | Juan David Gómez Cuellar (E12) | Red Team | José Luis Lancheros Ayora (E11) | Blue Team |

Ese registro presenta dos inconsistencias que documentamos de forma explícita:

1. **El ID E11 aparece dos veces**, lo que contraviene la regla 2 de la hoja *Resumen*
   ("Cada ID solo puede aparecer una vez"). La hoja *Resumen* además contabiliza
   G03 y G04 como dos parejas independientes, no como un equipo de tres.
2. **A E11 se le asignan dos roles incompatibles** en el mismo laboratorio y sobre
   el mismo repositorio: Red Team en G03 y Blue Team en G04.

Con el visto bueno del docente, el equipo trabaja como **una sola unidad de tres
integrantes**. Para resolver la contradicción de roles se aplicó el reparto de la
tabla anterior, que utiliza los **cuatro roles definidos en la §4 de la guía**
(Product/Builder, Red Team, Blue Team, Security Lead/Relator) en lugar de forzar
únicamente la dupla Red/Blue. De ese modo:

- Juan David conserva el rol Red Team que le asigna G04.
- Jeyder conserva el rol Blue Team que le asigna G03.
- José Luis asume Builder y Security Lead, y ejecuta la Fase F
  ("Verificar y cerrar — Purple Team"), evitando la duplicidad Red/Blue.

## Rotación para el Laboratorio 4

La regla 4 de la hoja *Resumen* exige rotar los roles Red/Blue en cada laboratorio.
Rotación acordada para el Lab 4:

| Integrante | Lab 3 | Lab 4 (previsto) |
|-----------|-------|------------------|
| Juan David Gómez Cuellar | Red Team | Builder / Security Lead |
| Jeyder Nicolay León Lancheros | Blue Team | Red Team |
| José Luis Lancheros Ayora | Builder / Security Lead | Blue Team |

## Trazabilidad de contribuciones individuales

La regla 5 de la hoja *Resumen* exige que el repositorio permita revisar las
contribuciones individuales. El procedimiento acordado está en
[`CONTRIBUTING.md`](CONTRIBUTING.md): cada integrante versiona con su propia
identidad de Git la evidencia de su rol.

| Carpeta | Responsable de los commits |
|---------|----------------------------|
| `app/`, `infra/`, `deploy/` | José Luis (Builder) |
| `evidence/red/` | Juan David (Red Team) |
| `evidence/blue/` | Jeyder (Blue Team) |
| `evidence/retest/` | José Luis (Purple / Fase F) |
| `threat-model/` | Los tres (sesión conjunta, con trailers `Co-authored-by`) |
| `reflections/` | Cada quien firma la suya |
