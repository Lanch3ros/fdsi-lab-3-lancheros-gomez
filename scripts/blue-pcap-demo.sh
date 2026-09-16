#!/bin/bash
# ============================================================================
# Blue Team - demo de captura en UN solo comando. FDSI Lab 3 Grupos G03+G04.
# Hace las 4 cosas en orden: (1) inicia tcpdump, (2) lanza el ataque,
# (3) cierra la captura, (4) demuestra que el contenido viaja en claro (H1).
# ============================================================================
set -e
cd "$(dirname "$0")/.."
echo "[1/4] iniciando captura tcpdump en el host de la app..."
docker exec incident-hub-web sh -c 'rm -f /tmp/demo.pcap /tmp/demo.done; (timeout 40 tcpdump -i any -nn -s0 -w /tmp/demo.pcap "tcp port 80" 2>/tmp/tcpdump.log; echo done >/tmp/demo.done) &'
until docker exec incident-hub-web sh -c '[ -f /tmp/demo.pcap ]'; do sleep 1; done
sleep 2
echo "[2/4] lanzando la ronda Red Team (genera el trafico que se captura)..."
bash scripts/run-red-team.sh >/dev/null 2>&1
sleep 2
echo "[3/4] cerrando la captura y extrayendo el PCAP..."
docker exec incident-hub-web sh -c 'kill $(pidof tcpdump) 2>/dev/null; sleep 1'
mkdir -p evidence/blue
docker cp incident-hub-web:/tmp/demo.pcap evidence/blue/demo.pcap >/dev/null
# recoger tambien los logs frescos de ESTA corrida
docker exec incident-hub-web sh -c 'cat /var/log/nginx/lab3_access.log' > evidence/blue/access.log
echo "[4/4] ¿el contenido viaja en claro? (H1)"
N=$(docker exec incident-hub-web sh -c 'tcpdump -nn -A -r /tmp/demo.pcap 2>/dev/null' | grep -c composite_id || true)
echo
echo "  -> 'composite_id' aparece $N veces EN CLARO dentro del PCAP"
if [ "$N" -gt 0 ]; then
  echo "  -> CONFIRMADO: el JSON de alertas se lee sin cifrar en la red (H1)."
else
  echo "  -> algo fallo: revisa que los contenedores esten arriba."
fi
echo
echo "PCAP guardado en evidence/blue/demo.pcap ($(ls -la evidence/blue/demo.pcap | awk '{print $5}') bytes)"
echo "Ahora corre:  bash scripts/blue-detect.sh evidence/blue/access.log"
