# 定义singbox版本变量（便于后续升级，只需修改此处）
ENV SINGBOX_VERSION=v1.12.3
ENV SINGBOX_ARCH=linux-amd64  # 架构可按需修改（如linux-arm64）

# 下载、安装并清理（添加容错与简化路径）
RUN set -eux; \
    # 拼接下载URL
    SINGBOX_URL="https://github.com/SagerNet/sing-box/releases/download/${SINGBOX_VERSION}/sing-box-${SINGBOX_VERSION}-${SINGBOX_ARCH}.tar.gz"; \
    # 下载压缩包（-q静音模式，-O指定输出文件名）
    wget -q -O singbox.tar.gz "${SINGBOX_URL}"; \
    # 解压（--strip-components=1 移除顶层目录，直接提取文件）
    tar -zxf singbox.tar.gz --strip-components=1; \
    # 复制二进制文件到系统路径
    cp sing-box /usr/local/bin/; \
    # 验证文件存在且可执行
    chmod +x /usr/local/bin/sing-box; \
    sing-box --version;  # 验证安装成功（失败则构建终止）
    # 彻底清理临时文件
    rm -rf singbox.tar.gz sing-box;
