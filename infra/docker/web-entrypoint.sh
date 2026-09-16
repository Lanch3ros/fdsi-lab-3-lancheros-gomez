#!/bin/sh
# Selecciona la configuracion de Nginx segun las variables del laboratorio, de
# modo que un solo comando reproduzca cada estado:
#   HARDENED=0            -> linea base insegura (objetivo del Red Team)
#   HARDENED=1            -> hardening HTTP aplicado (retest del Lab 3)
#   TLS=1                 -> CAPA DE MITIGACION completa: hardening + HTTPS
#                           (tiene prioridad sobre HARDENED)
set -e
if [ "${TLS:-0}" = "1" ]; then
    cp /etc/nginx/lab-configs/mitigado-tls.conf /etc/nginx/conf.d/default.conf
    echo "[lab3] Nginx: CAPA DE MITIGACION con TLS (HTTPS :443, redireccion 80->443)"
elif [ "${HARDENED:-0}" = "1" ]; then
    cp /etc/nginx/lab-configs/hardened.conf /etc/nginx/conf.d/default.conf
    echo "[lab3] Nginx: configuracion ENDURECIDA (HARDENED=1)"
else
    cp /etc/nginx/lab-configs/baseline.conf /etc/nginx/conf.d/default.conf
    echo "[lab3] Nginx: configuracion LINEA BASE (HARDENED=0)"
fi
