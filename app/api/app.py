"""
CrowdStrike Incident Hub - Prototipo de laboratorio (FDSI Lab 3, Grupos G03+G04).

ADVERTENCIA ACADEMICA
---------------------
Este servicio expone DATOS FICTICIOS. No se conecta a CrowdStrike Falcon ni a
ningun entorno real. Se publica deliberadamente por HTTP y SIN autenticacion
porque el objetivo del Laboratorio 3 es identificar y evidenciar los riesgos de
esa configuracion. La autenticacion, TLS e identidad corresponden al Lab 4.

La variable de entorno HARDENED controla la linea base:
    HARDENED=0  -> configuracion insegura (estado "ANTES")
    HARDENED=1  -> correcciones del Paso 15/16 aplicadas (estado "DESPUES")
Esto permite reproducir la comparacion antes/despues sin cambiar el codigo.
"""

import json
import logging
import os
import pathlib
import sys
import uuid
from datetime import datetime, timezone

from flask import Flask, jsonify, request, g

BASE_DIR = pathlib.Path(__file__).resolve().parent
HARDENED = os.environ.get("HARDENED", "0") == "1"
APP_VERSION = "0.1.0-lab3"

with open(BASE_DIR / "alerts.json", encoding="utf-8") as fh:
    DATASET = json.load(fh)
ALERTS = DATASET["resources"]

# Campos que solo deberian viajar en el detalle, no en el listado masivo.
SENSITIVE_FIELDS = ("cmdline", "user_name", "sha256", "filename")

app = Flask(__name__)

# --- Telemetria de aplicacion -------------------------------------------------
# En modo hardened el log de auditoria incluye IP origen, timestamp UTC,
# correlation-id y user-agent. En modo inseguro se registra solo la accion,
# lo que produce la "trazabilidad insuficiente" descrita en el modelo STRIDE.
AUDIT_LOG = []

audit_logger = logging.getLogger("incident-hub.audit")
audit_logger.setLevel(logging.INFO)
_handler = logging.StreamHandler(sys.stdout)
_handler.setFormatter(logging.Formatter("%(message)s"))
audit_logger.addHandler(_handler)


def utcnow():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def client_ip_declarado():
    """Origen tal como lo declara el cliente.

    NO es confiable: X-Forwarded-For es una cabecera que el propio emisor puede
    fijar. Nginx la concatena con $proxy_add_x_forwarded_for, asi que el primer
    valor de la lista es exactamente lo que el cliente quiso poner.
    """
    xff = request.headers.get("X-Forwarded-For")
    if xff:
        return xff.split(",")[0].strip()
    return request.remote_addr


def client_ip_observado():
    """Origen observado por el proxy.

    La configuracion endurecida fija X-Real-IP con $remote_addr, un valor que el
    cliente no puede alterar. Si la cabecera no viene, se usa el peer directo.
    """
    return request.headers.get("X-Real-IP") or request.remote_addr


def record(action, detail):
    if HARDENED:
        # Trazabilidad suficiente: hora, correlacion, origen observado por el
        # proxy y, por separado, el origen que el cliente declaro. La diferencia
        # entre ambos es en si misma una senal de deteccion.
        entry = {
            "ts_utc": utcnow(),
            "correlation_id": g.get("correlation_id"),
            "action": action,
            "detail": detail,
            "src_ip": client_ip_observado(),
            "xff_declarado": request.headers.get("X-Forwarded-For", "-"),
            "user_agent": request.headers.get("User-Agent", "-"),
        }
    else:
        # Linea base: no hay hora ni identificador de correlacion, y el unico
        # campo de atribucion proviene de una cabecera que el cliente controla.
        entry = {
            "action": action,
            "detail": detail,
            "src_ip": client_ip_declarado(),
        }
    AUDIT_LOG.append(entry)
    audit_logger.info(json.dumps(entry))
    return entry


def find_alert(composite_id):
    return next((a for a in ALERTS if a["composite_id"] == composite_id), None)


@app.before_request
def assign_correlation_id():
    g.correlation_id = str(uuid.uuid4())


@app.after_request
def response_headers(response):
    if HARDENED:
        # Paso 15: hardening inicial. No se agrega HSTS: sigue siendo HTTP.
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["Referrer-Policy"] = "no-referrer"
        response.headers["Cache-Control"] = "no-store"
        response.headers["X-Correlation-Id"] = g.get("correlation_id", "-")
        response.headers.pop("Server", None)
    else:
        # Estado inseguro: banner de version y CORS abierto.
        response.headers["X-Powered-By"] = f"incident-hub/{APP_VERSION} (Flask)"
        response.headers["Access-Control-Allow-Origin"] = "*"
    return response


# --- Endpoints ----------------------------------------------------------------
@app.get("/api/v1/health")
def health():
    return jsonify({"status": "ok", "hardened": HARDENED, "ts_utc": utcnow()})


@app.get("/api/v1/alerts")
def list_alerts():
    """Listado de alertas. Espeja el estilo de POST /alerts/v1 de Falcon."""
    record("list_alerts", {"count": len(ALERTS)})
    if HARDENED:
        # Paso 16: se reduce la exposicion. El listado ya no entrega cmdline,
        # usuario, hash ni nombre de archivo; solo lo necesario para triage.
        trimmed = [
            {k: v for k, v in a.items() if k not in SENSITIVE_FIELDS}
            for a in ALERTS
        ]
        return jsonify({"resources": trimmed, "meta": {"count": len(trimmed)}})
    return jsonify(DATASET)


@app.get("/api/v1/alerts/<composite_id>")
def get_alert(composite_id):
    alert = find_alert(composite_id)
    if alert is None:
        record("get_alert_not_found", {"composite_id": composite_id})
        return jsonify({"errors": [{"code": 404, "message": "alert not found"}]}), 404
    record("get_alert", {"composite_id": composite_id})
    return jsonify({"resources": [alert]})


@app.post("/api/v1/alerts/aggregates")
def aggregates():
    """Agregacion por campo, equivalente simplificado de PostAggregatesAlertsV1."""
    payload = request.get_json(silent=True) or {}
    field = payload.get("field", "severity_name")
    buckets = {}
    for alert in ALERTS:
        buckets[str(alert.get(field, "unknown"))] = buckets.get(str(alert.get(field, "unknown")), 0) + 1
    record("aggregates", {"field": field})
    return jsonify(
        {"resources": [{"name": field, "buckets": [{"label": k, "count": v} for k, v in buckets.items()]}]}
    )


@app.get("/api/v1/audit")
def audit():
    """Registro de acciones.

    Sin hardening este endpoint es publico: cualquiera puede leer el historial de
    consultas del SOC (Information Disclosure). Ademas las entradas no llevan hora
    ni identificador de correlacion, por lo que no se pueden ordenar ni cruzar con
    access.log (Repudiation), y su unico campo de origen proviene de una cabecera
    que el cliente controla (Spoofing).
    """
    if HARDENED:
        # El detalle de auditoria deja de ser publico; queda en el log del host.
        return jsonify({"errors": [{"code": 403, "message": "audit is not public"}]}), 403
    return jsonify({"resources": AUDIT_LOG, "meta": {"count": len(AUDIT_LOG)}})


@app.get("/api/v1/debug")
def debug_info():
    """Endpoint de diagnostico dejado por error en la linea base.

    Es el hallazgo de "configuracion insegura" que el Red Team debe encontrar
    por enumeracion. En modo hardened desaparece.
    """
    if HARDENED:
        return jsonify({"errors": [{"code": 404, "message": "not found"}]}), 404
    return jsonify(
        {
            "app_version": APP_VERSION,
            "python": sys.version,
            "cwd": str(BASE_DIR),
            "hardened": HARDENED,
            "dataset_file": str(BASE_DIR / "alerts.json"),
            "env": {k: v for k, v in os.environ.items() if "SECRET" not in k.upper()},
            "routes": sorted(str(r) for r in app.url_map.iter_rules()),
        }
    )


@app.post("/api/v1/alerts/<composite_id>/assign")
def assign_alert(composite_id):
    """Cambio de estado sin autenticacion: Tampering / Elevation of Privilege.

    Se conserva en ambos modos porque el control que falta (identidad y roles)
    pertenece al Laboratorio 4. En modo hardened al menos queda trazado.
    """
    alert = find_alert(composite_id)
    if alert is None:
        return jsonify({"errors": [{"code": 404, "message": "alert not found"}]}), 404
    payload = request.get_json(silent=True) or {}
    analyst = payload.get("assigned_to", "desconocido")
    previous = alert.get("assigned_to")
    alert["assigned_to"] = analyst
    alert["status"] = payload.get("status", alert["status"])
    record("assign_alert", {"composite_id": composite_id, "from": previous, "to": analyst})
    return jsonify({"resources": [alert]})


@app.errorhandler(404)
def not_found(_):
    return jsonify({"errors": [{"code": 404, "message": "not found"}]}), 404


if __name__ == "__main__":
    # debug=True en la linea base expone el depurador y trazas completas.
    app.run(host="0.0.0.0", port=8000, debug=not HARDENED)
