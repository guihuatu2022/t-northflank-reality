FROM alpine:latest

# 设置工作目录
WORKDIR /app

# 安装必要的软件包
RUN apk add --no-cache \
    wget \
    unzip \
    curl \
    jq \
    openssl \
    bash \
    libc6-compat \
    ca-certificates

# 下载并安装sing-box
RUN wget -O temp.zip $(wget -qO- "https://api.github.com/repos/SagerNet/sing-box/releases/latest" | grep -m1 -o "https.*linux-amd64.*zip") && \
    unzip temp.zip && \
    mv sing-box*/* /usr/local/bin/sing-box && \
    rm -rf temp.zip sing-box*

# 复制配置文件和脚本
COPY entrypoint.sh ./
COPY config.json ./

# 给予执行权限
RUN chmod +x ./entrypoint.sh

# 暴露端口
EXPOSE 443

# 设置入口点
ENTRYPOINT [ "./entrypoint.sh" ]