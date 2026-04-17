#!/bin/sh
set -e

LIVE_DIR="/etc/letsencrypt/live/$DOMAIN_NAME"
HAPROXY_CERT_PATH="$LIVE_DIR/haproxy.pem"
SOCKET_PATH="/var/run/haproxy/haproxy.sock"
MAX_RETRIES="${HAPROXY_SOCKET_RETRIES:-5}"
RETRY_DELAY="${HAPROXY_SOCKET_RETRY_DELAY:-30}"
SOCKET_TIMEOUT="${HAPROXY_SOCKET_TIMEOUT:-3}"

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

update_runtime_cert() {
    socat -T "$SOCKET_TIMEOUT" "UNIX-CONNECT:$SOCKET_PATH" - <<EOF
set ssl cert $HAPROXY_CERT_PATH <<
$(cat "$HAPROXY_CERT_PATH")

commit ssl cert $HAPROXY_CERT_PATH
EOF
}

# Не выходим с ошибкой, если HAProxy ещё не поднялся.
# Это важно при старте stack, когда certbot может стартовать раньше haproxy.
attempt=1
while [ "$attempt" -le "$MAX_RETRIES" ]; do
    if [ -S "$SOCKET_PATH" ]; then
        echo "Updating certificate in HAProxy via Unix socket (attempt $attempt/$MAX_RETRIES)..."
        if update_runtime_cert; then
            echo "Certificate updated in HAProxy memory."
            exit 0
        fi
        echo "WARN: Runtime API update failed; retrying in ${RETRY_DELAY}s..."
    else
        echo "WARN: HAProxy socket not ready ($SOCKET_PATH); retrying in ${RETRY_DELAY}s..."
    fi
    attempt=$((attempt + 1))
    sleep "$RETRY_DELAY"
done

echo "WARN: Could not update cert in HAProxy Runtime API after ${MAX_RETRIES} attempts."
echo "WARN: On-disk certificate is updated; container will keep running and retry on next renew cycle."
exit 0
