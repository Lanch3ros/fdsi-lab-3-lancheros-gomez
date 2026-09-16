# OWASP ZAP — Inspección pasiva (Paso 10)

**Responsable:** Juan David Gómez (Red Team). Esta es la única parte del Red Team
que **no** se automatiza: ZAP es gráfico. Sigan estos pasos y exporten el reporte.

> Regla del Paso 10: **solo modo pasivo**. NO ejecutar Active Scan. Cada header
> ausente se registra como *observación*, no como vulnerabilidad explotable.

## Requisito previo

El laboratorio debe estar en **línea base**:

```bash
cd infra/docker && HARDENED=0 docker compose up -d
# objetivo: http://127.0.0.1:8080
```

## Pasos

1. Abrir OWASP ZAP → **Manual Explore** (o "Explorar manualmente").
2. En **URL to explore**, escribir únicamente: `http://127.0.0.1:8080`
   (este es `TARGET_URL`; no introducir ninguna otra URL).
3. Marcar **Enable HUD** si se desea, y pulsar **Launch Browser**.
4. Navegar manualmente por:
   - `/` (portal)
   - `/public-inventory.txt`
   - `/api/v1/alerts`
   - `/api/v1/debug`
5. Volver a ZAP y revisar los paneles **Sites** y **Alerts**.
   **No** ejecutar Active Scan (clic derecho → Attack está prohibido aquí).
6. Exportar el reporte: **Report → Generate HTML Report** y guardarlo como
   `evidence/red/passive/zap-report.html`.

## Qué se espera observar (línea base)

ZAP en modo pasivo debería marcar, entre otras, observaciones como:

- Ausencia de `X-Content-Type-Options` (anti-MIME-sniffing).
- Ausencia de `X-Frame-Options` / anti-clickjacking.
- Ausencia de `Content-Security-Policy`.
- Divulgación de la versión del servidor (`Server: nginx/1.27.5`).
- Cabecera `X-Powered-By` revelando la tecnología de la API.

Cada una se corresponde con las debilidades D1 y D3 de nuestro modelo. Anótenlas
como observaciones y contrasten contra `evidence/retest/headers_after.txt` para
ver cuáles desaparecen tras el hardening.

## Registro

Al terminar, completar aquí:

- Fecha/hora UTC de la sesión ZAP: _(completar)_
- Nº de alertas pasivas encontradas: _(completar)_
- Archivo de reporte: `zap-report.html`
