#!/bin/sh
# ============================================================================
# Ronda Red Team - Paso 8 al 11 de la guia (Fase C)
# FDSI Laboratorio 3 - Grupos G03+G04 - Responsable: Juan David Gomez (Red Team)
#
# Reconocimiento y validacion AUTORIZADA contra el unico objetivo permitido.
# Solo lectura: nmap -p 80, curl y consultas a la API. Sin fuerza bruta, sin
# DoS, sin explotacion destructiva. Cada comando registra su timestamp.
#
# Uso (desde el host):  docker exec redteam sh /evidence/../scripts/red-team.sh
# En la practica se invoca via scripts/run-red-team.sh, que lo monta y ejecuta.
# ============================================================================
set -u

TARGET_IP="${TARGET_IP:-172.28.0.10}"
TARGET_URL="${TARGET_URL:-http://$TARGET_IP}"
OUT="${OUT:-/evidence/red}"
mkdir -p "$OUT"

ts() { date -u +%Y-%m-%dT%H:%M:%SZ; }
banner() { echo; echo "===== $1 ====="; }
log() { echo "[$(ts)] $1"; }

# Encabezado de la evidencia: quien, cuando, contra que.
{
  echo "# Evidencia Red Team - FDSI Lab 3 - Grupos G03+G04"
  echo "Responsable : Juan David Gomez Cuellar (Red Team)"
  echo "Inicio (UTC): $(ts)"
  echo "Objetivo    : $TARGET_URL  ($TARGET_IP)"
  echo "Alcance     : puerto 80/TCP unicamente, dentro de LAB_CIDR 172.28.0.0/24"
  echo "Origen      : estacion redteam 172.28.0.30"
  echo "Reglas      : solo lectura; sin DoS, fuerza bruta ni explotacion destructiva"
} | tee "$OUT/00-contexto.txt"

# --- Paso 8: reconocimiento de puerto y servicio -----------------------------
banner "H2 - Paso 8: Nmap -sV puerto 80"
log "nmap -Pn -sV -p 80 $TARGET_IP"
nmap -Pn -sV -p 80 "$TARGET_IP" -oN "$OUT/nmap_port80.txt" 2>&1 | tee -a "$OUT/nmap_console.txt"

banner "H2 - Paso 8: cabeceras de la pagina y de la API"
log "curl -i / (home)"
curl -si "$TARGET_URL/" | tee "$OUT/curl_home.txt" >/dev/null
log "curl -I / (solo headers)"
curl -sI "$TARGET_URL/" | tee "$OUT/curl_headers_home.txt"
log "curl -I /api/v1/alerts (banner de la API)"
curl -sI "$TARGET_URL/api/v1/alerts" | tee "$OUT/curl_headers_api.txt"

# --- H1 / H8: contenido y exposicion de datos --------------------------------
banner "H1 + H8 - Contenido de la API y campos expuestos"
log "curl /api/v1/alerts -> listado completo"
curl -s "$TARGET_URL/api/v1/alerts" | tee "$OUT/api_alerts.json" >/dev/null
log "claves presentes en cada alerta del listado (H8: exposicion excesiva)"
curl -s "$TARGET_URL/api/v1/alerts" \
  | jq -r '.resources[0] | keys[]' 2>/dev/null | tee "$OUT/api_alerts_keys.txt"

# --- H5: rutas ocultas desplegadas por error ---------------------------------
banner "H5 - Rutas ocultas (.git, .env)"
for path in ".git/config" ".env"; do
  code=$(curl -s -o /dev/null -w '%{http_code}' "$TARGET_URL/$path")
  log "GET /$path -> HTTP $code"
  echo "GET /$path -> HTTP $code" >> "$OUT/hidden_paths.txt"
  curl -si "$TARGET_URL/$path" >> "$OUT/hidden_paths_full.txt"
done

# --- Enumeracion de rutas comunes (genera 404 para la deteccion Blue) ---------
banner "Enumeracion de rutas comunes (superficie de ataque)"
log "sondeo de rutas frecuentes; se esperan varios 404"
for p in admin login wp-login.php .htaccess backup.zip config.php server-status \
         phpinfo.php api/v1/users robots.txt old index.bak; do
  code=$(curl -s -o /dev/null -w '%{http_code}' "$TARGET_URL/$p")
  echo "GET /$p -> $code" >> "$OUT/enumeracion.txt"
done
log "enumeracion registrada en enumeracion.txt"

# --- H6: listado de directorio -----------------------------------------------
banner "H6 - Autoindex en /files/"
log "curl /files/ (autoindex)"
curl -si "$TARGET_URL/files/" | tee "$OUT/autoindex_files.txt" >/dev/null
grep -qi "Index of" "$OUT/autoindex_files.txt" && log "autoindex CONFIRMADO" || log "sin autoindex"

# --- H7: endpoint de diagnostico ---------------------------------------------
banner "H7 - Endpoint de diagnostico /api/v1/debug"
log "curl /api/v1/debug"
curl -s "$TARGET_URL/api/v1/debug" | tee "$OUT/api_debug.json" >/dev/null
curl -s "$TARGET_URL/api/v1/debug" | jq -r '.env | keys[]?' 2>/dev/null \
  | tee "$OUT/api_debug_envkeys.txt" >/dev/null && log "variables de entorno expuestas: $(wc -l < "$OUT/api_debug_envkeys.txt")"

# --- H9: escritura sin autenticacion -----------------------------------------
banner "H9 - Cambio de estado sin identidad (assign)"
log "POST /api/v1/alerts/ldt:mock:0001/assign (sin credenciales)"
curl -si -X POST "$TARGET_URL/api/v1/alerts/ldt:mock:0001/assign" \
  -H 'Content-Type: application/json' \
  -d '{"assigned_to":"prueba_red_team","status":"closed"}' \
  | tee "$OUT/assign_sin_auth.txt" >/dev/null
log "estado tras el POST:"
curl -s "$TARGET_URL/api/v1/alerts/ldt:mock:0001" | jq -c '.resources[0] | {composite_id, assigned_to, status}' 2>/dev/null | tee -a "$OUT/assign_sin_auth.txt"

# --- H10: spoofing de origen via X-Forwarded-For -----------------------------
banner "H10 - Falsificacion de origen (X-Forwarded-For)"
log "GET /api/v1/alerts con X-Forwarded-For: 203.0.113.99 (IP de documentacion RFC5737)"
curl -s -o /dev/null "$TARGET_URL/api/v1/alerts" -H 'X-Forwarded-For: 203.0.113.99'
log "registro de auditoria de la aplicacion (H3+H10):"
curl -s "$TARGET_URL/api/v1/audit" | tee "$OUT/api_audit.json" >/dev/null
curl -s "$TARGET_URL/api/v1/audit" | jq -c '.resources[-1]' 2>/dev/null | tee "$OUT/api_audit_ultima.txt"

# --- H4: ausencia de proteccion de integridad (sin ejecutar MITM) ------------
banner "H4 - Ausencia de TLS / HSTS (documental, sin MITM)"
log "buscar cabeceras de integridad/transporte (no deben existir)"
curl -sI "$TARGET_URL/" | grep -iE 'strict-transport-security|content-security-policy' \
  | tee "$OUT/tls_ausente.txt" >/dev/null
if [ ! -s "$OUT/tls_ausente.txt" ]; then
  echo "Sin Strict-Transport-Security ni Content-Security-Policy. Servicio 100% HTTP." | tee "$OUT/tls_ausente.txt"
fi
log "puerto 443 (TLS) no forma parte del alcance; el servicio solo expone 80/TCP"

banner "FIN"
echo "[$(ts)] Ronda Red Team completada. Evidencia en $OUT" | tee "$OUT/99-fin.txt"
