# Используем официальный образ certbot с плагином для Cloudflare
FROM certbot/dns-cloudflare:latest

# Устанавливаем зависимости:
#   docker-cli – для проверки наличия контейнера HAProxy
#   openssl    – для возможной генерации dhparam
#   socat      – для отправки команд в HAProxy Runtime API
RUN apk add --no-cache docker-cli openssl socat

# Создаём рабочие каталоги
WORKDIR /app

# Копируем скрипт обновления и docker-entrypoint
COPY certbot/renew.sh /app/renew.sh
COPY certbot/update-haproxy.sh /app/update-haproxy.sh
COPY docker-entrypoint.sh /app/docker-entrypoint.sh

# Делаем скрипты исполняемыми
RUN chmod +x /app/renew.sh /app/update-haproxy.sh /app/docker-entrypoint.sh

# Точка входа — наш entrypoint
ENTRYPOINT ["/app/docker-entrypoint.sh"]
