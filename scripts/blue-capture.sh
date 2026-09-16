#!/bin/sh
# ============================================================================
# Blue Team - captura de trafico (Paso 11) - se ejecuta EN el host de la app.
# FDSI Laboratorio 3 - Grupos G03+G04 - Responsable: Jeyder Leon (Blue Team)
#
# Inicia una captura tcpdump limitada al puerto 80 y del laboratorio, durante
# la ventana en que el Red Team ejecuta sus pruebas. Solo trafico del lab.
# ============================================================================
set -u
DUR="${DUR:-90}"
OUT="/tmp/lab3-http.pcap"
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Blue: iniciando tcpdump ${DUR}s en puerto 80 -> $OUT"
tcpdump -i any -nn -s0 -w "$OUT" 'tcp port 80' &
TCPID=$!
echo "$TCPID" > /tmp/tcpid
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Blue: captura en curso (pid $TCPID)"
