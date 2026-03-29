#!/bin/sh
set -e

LIVE_DIR="/etc/letsencrypt/live/$DOMAIN_NAME"
HAPROXY_CERT_PATH="$LIVE_DIR/haproxy.pem"
SOCKET_PATH="/var/run/haproxy/haproxy.sock"

if [ -z "${DOMAIN_NAME:-}" ]; then
    echo "ERROR: DOMAIN_NAME is empty" >&2
    exit 1
fi

if [ ! -s "$LIVE_DIR/fullchain.pem" ] || [ ! -s "$LIVE_DIR/privkey.pem" ]; then
    echo "ERROR: certificate files not found in $LIVE_DIR" >&2
    exit 1
fi

# Обновляем файл на диске
cat "$LIVE_DIR/fullchain.pem" "$LIVE_DIR/privkey.pem" > "$HAPROXY_CERT_PATH"
chmod 644 "$HAPROXY_CERT_PATH"

# Проверяем, существует ли сокет (HAProxy запущен и создал его)
if [ -S "$SOCKET_PATH" ]; then
    echo "Updating certificate in HAProxy via Unix socket..."
    socat "UNIX-CONNECT:$SOCKET_PATH" - <<EOF
set ssl cert $HAPROXY_CERT_PATH <<
$(cat "$HAPROXY_CERT_PATH")

commit ssl cert $HAPROXY_CERT_PATH
EOF
    echo "Certificate updated in HAProxy memory."
else
    echo "HAProxy socket not found — skipping Runtime API update."
fi
