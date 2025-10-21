FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends wget uuid-runtime openssl curl && rm -rf /var/lib/apt/lists/*
ENV SINGBOX_VERSION=v1.12.3
ENV SINGBOX_ARCH=linux-amd64
RUN set -eux; SINGBOX_URL="https://github.com/SagerNet/sing-box/releases/download/${SINGBOX_VERSION}/sing-box-${SINGBOX_VERSION}-${SINGBOX_ARCH}.tar.gz"; wget -q -O singbox.tar.gz "${SINGBOX_URL}"; tar -zxf singbox.tar.gz --strip-components=1; cp sing-box /usr/local/bin/; chmod +x /usr/local/bin/sing-box; sing-box --version; rm -rf singbox.tar.gz sing-box
RUN mkdir -p /etc/singbox /data /var/log/singbox && chmod -R 777 /etc/singbox /data /var/log/singbox
VOLUME ["/data"]
COPY start.sh /start.sh
RUN chmod +x /start.sh
CMD ["/start.sh"]
