# 使用官方 sing-box 镜像（latest 为 1.12+）
FROM ghcr.io/sagernet/sing-box:latest

# 安装 bash、uuidgen 和 openssl
RUN apk add --no-cache bash util-linux openssl

# 复制配置和启动脚本
COPY config.json /etc/sing-box/config.json
COPY start.sh /start.sh
RUN chmod +x /start.sh

# 暴露 VLESS+TCP+REALITY 端口
EXPOSE 443/tcp

# 覆盖默认 ENTRYPOINT，指定 bash
ENTRYPOINT ["/bin/bash"]

# 执行 start.sh
CMD ["/start.sh"]
