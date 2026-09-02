#!/bin/sh
# Selecciona la configuracion de Nginx segun la variable HARDENED, de modo que un
# solo comando reproduzca el estado ANTES o el estado DESPUES del Paso 15.
#   HARDENED=0 -> linea base insegura (objetivo autorizado del Red Team)
#   HARDENED=1 -> hardening aplicado  (estado verificado en el retest)
set -e
if [ "${HARDENED:-0}" = "1" ]; then
    cp /etc/nginx/lab-configs/hardened.conf /etc/nginx/conf.d/default.conf
    echo "[lab3] Nginx: configuracion ENDURECIDA (HARDENED=1)"
else
    cp /etc/nginx/lab-configs/baseline.conf /etc/nginx/conf.d/default.conf
    echo "[lab3] Nginx: configuracion LINEA BASE (HARDENED=0)"
fi
