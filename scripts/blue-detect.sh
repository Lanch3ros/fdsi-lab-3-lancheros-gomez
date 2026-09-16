#!/bin/sh
# ============================================================================
# Blue Team - deteccion reproducible (Paso 13) - FDSI Lab 3 Grupos G03+G04
# Responsable: Jeyder Leon (Blue Team)
#
# Regla del laboratorio: una misma IP con 5 o mas respuestas 404 en 5 minutos
# se considera senal de enumeracion. El script la evalua sobre access.log.
# ============================================================================
LOG="${1:-evidence/blue/access.log}"
echo "== Deteccion sobre $LOG =="
echo
echo "-- Top rutas 404 por IP (posible enumeracion) --"
awk '$9 == "404" {print $1, $7}' "$LOG" | sort | uniq -c | sort -nr | head
echo
echo "-- Conteo de 404 por IP --"
awk '$9 == "404" {print $1}' "$LOG" | sort | uniq -c | sort -nr \
  | awk '{ip=$2;c=$1; flag=(c>=5)?"  <== SUPERA UMBRAL (>=5)":""; print c" 404 desde "ip flag}'
echo
echo "-- Distribucion de codigos de estado --"
awk '{print $9}' "$LOG" | sort | uniq -c | sort -nr
echo
echo "-- Accesos a rutas sensibles (H5/H6/H7) --"
grep -E '\.git|\.env|/files/|/api/v1/debug' "$LOG" | awk '{print $1, $6, $7, $9}' | sed 's/"//g'
