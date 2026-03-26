#!/bin/sh
set -e

CERT_NAME="$DOMAIN_NAME"
LIVE_DIR="/etc/letsencrypt/live/$CERT_NAME"
HAPROXY_DIR="/etc/haproxy/certs"
DHPARAM="$HAPROXY_DIR/dhparam.pem"
HAPROXY_CERT_PATH="$HAPROXY_DIR/$CERT_NAME.pem"

echo "=== Certbot Universal Manager started for $CERT_NAME ==="

# 1. Генерация dhparam — только если включено и файла нет
if [ "$DHPARAM_ENABLED" = "true" ]; then
    if [ ! -f "$DHPARAM" ] || [ ! -s "$DHPARAM" ]; then
        echo "Generating dhparam.pem (2048 bit)..."
        openssl dhparam -out "$DHPARAM" 2048
        chmod 644 "$DHPARAM"
        echo "dhparam.pem ready"
    else
        echo "dhparam.pem already exists — skipped"
    fi
fi

EMAIL_OPT=""
if [ -n "$EMAIL" ]; then
    EMAIL_OPT="--email $EMAIL"
fi

# 2. Первый выпуск сертификата, если его нет
if [ ! -d "$LIVE_DIR" ] || [ ! -f "$LIVE_DIR/fullchain.pem" ]; then
    echo "No certificate found — requesting new one..."
    certbot certonly --quiet --non-interactive --agree-tos --expand \
        --dns-cloudflare \
        --dns-cloudflare-credentials /app/cloudflare.ini \
        --dns-cloudflare-propagation-seconds 60 \
        --rsa-key-size 4096 \
        -d "$CERT_NAME" \
        -d "*.$CERT_NAME" \
        --cert-name "$CERT_NAME" \
        $EMAIL_OPT

    echo "Initial certificate issued"
else
    echo "Certificate already exists — skipping initial issuance"
    # Если combined.pem повреждён — восстанавливаем
    if [ ! -f "$HAPROXY_CERT_PATH" ] || [ ! -s "$HAPROXY_CERT_PATH" ]; then
        echo "combined.pem missing or empty — recreating..."
        cat "$LIVE_DIR/fullchain.pem" "$LIVE_DIR/privkey.pem" > "$HAPROXY_CERT_PATH"
        chmod 644 "$HAPROXY_CERT_PATH"
    fi
fi

# 3. Обновляем HAProxy (первичная загрузка сертификата)
/app/update-haproxy.sh

# 4. Бесконечный цикл обновления
echo "Starting renew loop (every 24 hours)..."
while true; do
    echo "[$(date)] Running certbot renew..."
    certbot renew --quiet --deploy-hook "/app/update-haproxy.sh"
    echo "[$(date)] Sleeping 24 hours..."
    sleep 24h
done