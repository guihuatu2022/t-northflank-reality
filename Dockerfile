# 基于debian稳定版，确保兼容singbox 1.12+的libc依赖
FROM debian:bookworm-slim

# 安装必要工具：wget（下载singbox）、uuid-runtime（生成UUID）、openssl（生成随机数）、curl（调试用）
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    uuid-runtime \
    openssl \
    curl \
    && rm -rf /var/lib/apt/lists/*  # 清理缓存减小镜像体积

# 下载singbox 1.12.3（最新稳定版，amd64架构）
# 若需其他架构，可修改URL中的"linux-amd64"为"linux-arm64"等
RUN wget -q https://github.com/SagerNet/sing-box/releases/download/v1.12.3/sing-box-1.12.3-linux-amd64.tar.gz \
    && tar -zxf sing-box-1.12.3-linux-amd64.tar.gz \
    && cp sing-box-1.12.3-linux-amd64/sing-box /usr/local/bin/ \
    && chmod +x /usr/local/bin/sing-box \
    && rm -rf sing-box-1.12.3*  # 清理安装包

# 创建工作目录与持久化目录，设置宽松权限避免启动失败（调试用）
RUN mkdir -p /etc/singbox /data /var/log/singbox \
    && chmod -R 777 /etc/singbox /data /var/log/singbox

# 挂载持久化卷（保存密钥对，容器重启不丢失）
VOLUME ["/data"]

# 复制启动脚本到容器
COPY start.sh /start.sh
RUN chmod +x /start.sh

# 启动命令（执行脚本）
CMD ["/start.sh"]
