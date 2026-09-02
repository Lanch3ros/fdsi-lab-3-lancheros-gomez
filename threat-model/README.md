# Modelo de amenazas — Fase B del Laboratorio 3

Esta carpeta contiene el trabajo del **Paso 6 (DFD)** y el **Paso 7 (hipótesis STRIDE)**
de la guía, elaborado en sesión conjunta **antes** de ejecutar cualquier prueba ofensiva.

| Archivo | Contenido |
|---------|-----------|
| [`dfd-lab3.png`](dfd-lab3.png) | Diagrama de flujo de datos con las tres fronteras de confianza |
| [`dfd-lab3.svg`](dfd-lab3.svg) | Fuente editable del diagrama (versionable, se rinde a PNG) |
| [`stride.md`](stride.md) | Fronteras, elementos, flujos, tabla STRIDE y las once fichas de hipótesis |

## Resumen

**Tres fronteras de confianza** (la guía exige dos):

| ID | Frontera | Pregunta que responde |
|----|----------|------------------------|
| TB1 | Red externa → servidor | ¿Quién puede llegar, y qué ve mientras llega? |
| TB2 | Red → aplicación | ¿En qué confía la aplicación de lo que le pasa el proxy? |
| TB3 | Proceso → almacenamiento y telemetría | ¿Qué queda registrado, y sirve para atribuir? |

**Once hipótesis STRIDE** (la guía exige cuatro). H1–H4 conservan el enunciado de la
tabla de ejemplo del Paso 7; H5–H11 añaden las debilidades propias de este prototipo.
Las seis categorías de STRIDE quedan cubiertas.

## Cómo regenerar el diagrama

El PNG se produce desde el SVG, que es el archivo que se edita:

```bash
docker run --rm -v "$PWD/threat-model":/w -w /w alpine:3.20 \
  sh -c "apk add --no-cache rsvg-convert ttf-dejavu >/dev/null 2>&1; \
         rsvg-convert -w 1920 -f png -o dfd-lab3.png dfd-lab3.svg"
```

## Regla de ejecución

Ninguna hipótesis se da por válida sin recorrer la cadena completa que exige la
condición de aprobación de la guía:

```
hipótesis → comando → timestamp → resultado → interpretación → corrección → retest
```

Las fichas de `stride.md` traen esa cadena como plantilla: los campos *Timestamp*,
*Resultado observado* e *Interpretación* se completan durante las Fases C y D, y su
evidencia se guarda en `evidence/`.
