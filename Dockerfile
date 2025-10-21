# 使用官方 sing-box 镜像（latest 为 1.12+）
FROM ghcr.io/sagernet/sing-box:latest

RUN apk add --no-cache bash

COPY config.json /etc/sing-box/config.json
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 443/tcp

CMD ["/start.sh"]
