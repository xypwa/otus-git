if ! [[ -f /usr/local/bin/node_exporter ]]; then 
  cp /home/xypwa/node_exporter-*.linux-amd64/node_exporter /usr/local/bin
fi;
SERVICE_CONF="
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
"
echo "$SERVICE_CONF" > /etc/systemd/system/node_exporter.service
systemctl daemon-reload
systemctl start node_exporter
systemctl status node_exporter
systemctl enable node_exporter
