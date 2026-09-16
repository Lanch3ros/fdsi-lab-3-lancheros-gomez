#!/bin/sh
# ============================================================================
# Retest / verificacion (Paso 17) - FDSI Lab 3 Grupos G03+G04
# Responsable: Jose Luis Lancheros (Purple / Fase F)
#
# Repite exactamente las pruebas clave contra el estado ENDURECIDO y guarda la
# evidencia en evidence/retest/ para la comparacion antes/despues.
# ============================================================================
set -u
T="${TARGET_URL:-http://172.28.0.10}"
OUT="${OUT:-/evidence/retest}"
mkdir -p "$OUT"
ts() { date -u +%Y-%m-%dT%H:%M:%SZ; }
echo "# Retest Red/Blue - estado ENDURECIDO - $(ts)" | tee "$OUT/00-contexto.txt"

echo "== H2: banner de version =="
curl -sI "$T/" | tee "$OUT/headers_after.txt"
echo "== H2: nmap -sV =="
nmap -Pn -sV -p 80 "${TARGET_IP:-172.28.0.10}" -oN "$OUT/nmap_after.txt" >/dev/null 2>&1
grep -iE 'server|version' "$OUT/nmap_after.txt" | head -3

echo "== H5: rutas ocultas =="
for p in ".git/config" ".env"; do
  echo "GET /$p -> $(curl -s -o /dev/null -w '%{http_code}' "$T/$p")" | tee -a "$OUT/hidden_after.txt"
done

echo "== H6: autoindex =="
echo "GET /files/ -> $(curl -s -o /dev/null -w '%{http_code}' "$T/files/")" | tee "$OUT/autoindex_after.txt"

echo "== H7: endpoint debug =="
echo "GET /api/v1/debug -> $(curl -s -o /dev/null -w '%{http_code}' "$T/api/v1/debug")" | tee "$OUT/debug_after.txt"

echo "== H8: exposicion de campos en el listado =="
curl -s "$T/api/v1/alerts" | jq -r '.resources[0] | keys[]' 2>/dev/null | tee "$OUT/alerts_keys_after.txt"

echo "== H9+H10+H3: escritura y auditoria trazable =="
curl -s -o /dev/null -X POST "$T/api/v1/alerts/ldt:mock:0002/assign" \
  -H 'Content-Type: application/json' -H 'X-Forwarded-For: 203.0.113.99' \
  -d '{"assigned_to":"retest","status":"in_progress"}'
echo "auditoria publica? -> $(curl -s -o /dev/null -w '%{http_code}' "$T/api/v1/audit") (403 esperado)"  | tee "$OUT/audit_after.txt"

echo "== headers de seguridad presentes =="
curl -sI "$T/" | grep -iE 'x-content-type-options|x-frame-options|referrer-policy' | tee "$OUT/security_headers_after.txt"

echo "== D6 sigue abierto: no hay TLS/HSTS (limite pedagogico) =="
curl -sI "$T/" | grep -iE 'strict-transport-security' || echo "Sin HSTS: HTTP sigue siendo el transporte (riesgo trasladado a Lab 4)" | tee "$OUT/tls_still_open.txt"

echo "[$(ts)] retest completado" | tee "$OUT/99-fin.txt"
