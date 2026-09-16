# Despliegue sobre Ubuntu Server + Kali (VM reales)

Alternativa al laboratorio en Docker, para cuando el docente asigne máquinas.
Reproduce la **misma** aplicación y configuración de `infra/`.

> Antes de empezar, fijar las variables (§3 de la guía) con los valores **reales**
> asignados:
> ```bash
> export TARGET_IP=IP_ASIGNADA
> export TARGET_URL=http://$TARGET_IP
> export LAB_CIDR=CIDR_AUTORIZADO
> ```

## En el Ubuntu Server (Builder)

```bash
# 1. Nginx
sudo apt update && sudo apt install -y nginx python3-flask gunicorn jq

# 2. Aplicación
sudo mkdir -p /var/www/incident-hub
sudo cp app/static/index.html app/static/public-inventory.txt /var/www/incident-hub/
sudo mkdir -p /opt/incident-hub && sudo cp app/api/app.py app/api/alerts.json /opt/incident-hub/

# 3. API como servicio (gunicorn, 1 worker: la auditoría vive en memoria)
sudo tee /etc/systemd/system/incident-hub.service >/dev/null <<UNIT
[Unit]
Description=CrowdStrike Incident Hub API (lab3)
After=network.target
[Service]
WorkingDirectory=/opt/incident-hub
Environment=HARDENED=0
ExecStart=/usr/bin/gunicorn --bind 127.0.0.1:8000 --workers 1 app:app
Restart=on-failure
[Install]
WantedBy=multi-user.target
UNIT
sudo systemctl daemon-reload && sudo systemctl enable --now incident-hub

# 4. Virtual host (línea base). Ajustar proxy_pass a 127.0.0.1:8000.
sudo cp infra/nginx/incident-hub.baseline.conf /etc/nginx/sites-available/incident-hub
#   editar: proxy_pass http://incident-hub-api:8000  ->  http://127.0.0.1:8000
sudo ln -sf /etc/nginx/sites-available/incident-hub /etc/nginx/sites-enabled/incident-hub
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx
curl -i http://127.0.0.1/

# 5. Firewall limitado al segmento del laboratorio (Paso 5)
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from "$LAB_CIDR" to any port 80 proto tcp
sudo ufw allow OpenSSH
sudo ufw enable
sudo ufw status numbered
```

## En Kali (Red Team)

```bash
export TARGET_IP=IP_ASIGNADA
export OUT=evidence/red
bash scripts/red-team.sh     # mismos comandos que en Docker
```

## En el Ubuntu Server (Blue Team)

```bash
# Captura durante la ventana de pruebas
sudo timeout 90 tcpdump -i any -nn -s0 -w evidence/blue/lab3-http.pcap 'tcp port 80'
# Logs
sudo cp /var/log/nginx/access.log evidence/blue/access.log
sudo cp /var/log/nginx/error.log  evidence/blue/error.log
bash scripts/blue-detect.sh evidence/blue/access.log | tee evidence/blue/deteccion-404.txt
```

## Hardening + retest

```bash
# Cambiar el servicio a HARDENED=1 y usar la conf endurecida
sudo sed -i 's/HARDENED=0/HARDENED=1/' /etc/systemd/system/incident-hub.service
sudo systemctl daemon-reload && sudo systemctl restart incident-hub
sudo cp infra/nginx/incident-hub.hardened.conf /etc/nginx/sites-available/incident-hub
#   reajustar proxy_pass a 127.0.0.1:8000
sudo nginx -t && sudo systemctl reload nginx
bash scripts/retest.sh
```

La lógica es idéntica a la de Docker; solo cambian las rutas y el firewall real.
