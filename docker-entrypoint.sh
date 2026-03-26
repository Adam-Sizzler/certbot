#!/bin/sh
set -e

# Проверяем, что переменная окружения задана
if [ -z "$DNS_CLOUDFLARE_API_TOKEN" ]; then
    echo "ERROR: DNS_CLOUDFLARE_API_TOKEN is not set" >&2
    exit 1
fi

# Создаём cloudflare.ini
CLOUDFLARE_INI="/app/cloudflare.ini"
cat > "$CLOUDFLARE_INI" <<EOF
# Cloudflare API token
dns_cloudflare_api_token = $DNS_CLOUDFLARE_API_TOKEN
EOF

# Права: только владелец может читать
chmod 600 "$CLOUDFLARE_INI"

echo "cloudflare.ini created successfully"

# Запускаем основной скрипт, передавая ему управление
exec /app/renew.sh
