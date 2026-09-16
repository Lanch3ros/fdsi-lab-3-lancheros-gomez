#!/bin/bash
# Ejecuta la ronda Red Team dentro del contenedor 'redteam' (la estacion Kali).
# La evidencia queda en ./evidence/red/ (montado como /evidence en el contenedor).
set -euo pipefail
cd "$(dirname "$0")/.."
docker cp scripts/red-team.sh redteam:/tmp/red-team.sh
docker exec -e TARGET_IP=172.28.0.10 redteam sh /tmp/red-team.sh
echo "Evidencia Red Team en: $(pwd)/evidence/red/"
