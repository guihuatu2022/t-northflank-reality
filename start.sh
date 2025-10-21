#!/bin/bash

UUID=${UUID:-$(uuidgen)}
REALITY_PRIVATE_KEY=${REALITY_PRIVATE_KEY:-$(sing-box generate reality-keypair | grep "PrivateKey" | cut -d'"' -f4)}
REALITY_PUBLIC_KEY=${REALITY_PUBLIC_KEY:-$(sing-box generate reality-keypair | grep "PublicKey" | cut -d'"' -f4)}
SHORT_ID=${SHORT_ID:-$(openssl rand -hex 8 | cut -c1-8)}
SNI=${SNI:-www.google.com}
SERVER_PORT=${SERVER_PORT:-443}
ENABLE_MULTIPLEX=${ENABLE_MULTIPLEX:-false}  # 新增：1.12+ 默认关闭，设 true 启用

sed -i "s|{{UUID}}|$UUID|g" /etc/sing-box/config.json
sed -i "s|{{REALITY_PRIVATE_KEY}}|$REALITY_PRIVATE_KEY|g" /etc/sing-box/config.json
sed -i "s|{{SHORT_ID}}|$SHORT_ID|g" /etc/sing-box/config.json
sed -i "s|{{SNI}}|$SNI|g" /etc/sing-box/config.json
sed -i "s|{{SERVER_PORT}}|$SERVER_PORT|g" /etc/sing-box/config.json
sed -i "s|{{ENABLE_MULTIPLEX}}|$ENABLE_MULTIPLEX|g" /etc/sing-box/config.json

echo "Generated Config (1.12+ Compatible):"
echo "UUID: $UUID"
echo "REALITY Private Key: $REALITY_PRIVATE_KEY"
echo "Public Key for Client: $REALITY_PUBLIC_KEY"
echo "Short ID: $SHORT_ID"
echo "SNI: $SNI"
echo "Multiplex Enabled: $ENABLE_MULTIPLEX"

exec sing-box run -c /etc/sing-box/config.json
