#!/bin/sh
set -e

# Скрипт для обновления сертификата в HAProxy через Runtime API
LIVE_DIR="/etc/letsencrypt/live/$DOMAIN_NAME"
HAPROXY_CERT_PATH="/etc/haproxy/certs/$DOMAIN_NAME.pem"

# Обновляем файл на диске
cat "$LIVE_DIR/fullchain.pem" "$LIVE_DIR/privkey.pem" > "$HAPROXY_CERT_PATH"
chmod 644 "$HAPROXY_CERT_PATH"

# Обновляем сертификат в HAProxy, если контейнер запущен
if docker ps --format "table {{.Names}}" | grep -q "^haproxy$"; then
    echo "Updating certificate in HAProxy via Runtime API..."
    socat tcp:haproxy:9999 - <<EOF
set ssl cert $HAPROXY_CERT_PATH <<
$(cat "$HAPROXY_CERT_PATH")

commit ssl cert $HAPROXY_CERT_PATH
EOF
    echo "Certificate updated in HAProxy memory."
else
    echo "HAProxy container not running — skipping Runtime API update."
fi
