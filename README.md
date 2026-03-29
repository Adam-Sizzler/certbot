# certbot

Контейнер выпускает/обновляет wildcard-сертификат через Cloudflare DNS challenge
и обновляет сертификат в HAProxy через Runtime API (`/var/run/haproxy/haproxy.sock`).

Обязательные переменные окружения:

- `DOMAIN_NAME`
- `DNS_CLOUDFLARE_API_TOKEN`

Рекомендуемые volume:

- `letsencrypt:/etc/letsencrypt`
- `haproxy-socket:/var/run/haproxy`
