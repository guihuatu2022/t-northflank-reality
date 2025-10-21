# 使用 singbox 官方镜像（最新稳定版，对应 1.12+）
FROM ghcr.io/sagernet/sing-box:latest

# 安装必要工具（生成UUID、随机数等）
RUN apt-get update && apt-get install -y --no-install-recommends \
    uuid-runtime \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# 创建持久化目录并设置权限
RUN mkdir -p /data/reality-keys /etc/singbox /var/log/singbox \
    && chmod -R 777 /data /etc/singbox /var/log/singbox

# 挂载持久卷（保存密钥）
VOLUME ["/data"]

# 复制启动脚本
COPY start.sh /start.sh
RUN chmod +x /start.sh

# 启动命令
CMD ["/start.sh"]
