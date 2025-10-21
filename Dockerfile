FROM ghcr.io/sagernet/sing-box:latest

# 设置工作目录
WORKDIR /app

# 安装必要的软件包
RUN apk add --no-cache \
    jq \
    openssl \
    bash

# 复制配置文件和脚本
COPY entrypoint.sh ./
COPY config.json ./

# 给予执行权限
RUN chmod +x ./entrypoint.sh

# 暴露端口
EXPOSE 8443

# 设置入口点
ENTRYPOINT [ "./entrypoint.sh" ]
