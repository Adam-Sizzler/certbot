# certbot

Контейнер выпускает/обновляет wildcard-сертификат через Cloudflare DNS challenge
и обновляет сертификат в HAProxy через Runtime API (`/var/run/haproxy/haproxy.sock`).

Обязательные переменные окружения:

- `DOMAIN_NAME`
- `DNS_CLOUDFLARE_API_TOKEN`

Опционально для обновления через HAProxy Runtime API:

- `HAPROXY_SOCKET_RETRIES` (по умолчанию `5`)
- `HAPROXY_SOCKET_RETRY_DELAY` (по умолчанию `30` сек)
- `HAPROXY_SOCKET_TIMEOUT` (по умолчанию `3` сек)
- `RENEW_INTERVAL` (по умолчанию `12h`)

Если сокет HAProxy временно недоступен при старте, контейнер делает ограниченное число попыток, пишет warning и продолжает работу без падения. Следующая попытка будет на следующем цикле renew.

Рекомендуемые volume:

- `letsencrypt:/etc/letsencrypt`
- `haproxy-socket:/var/run/haproxy`
