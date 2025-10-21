#!/bin/bash

# 调试：确认 bash 环境
echo "Starting script in bash..."

# 检查必要工具
command -v uuidgen >/dev/null 2>&1 || { echo "Error: uuidgen not found"; exit 1; }
command -v openssl >/dev/null 2>&1 || { echo "Error: openssl not found"; exit 1; }
command -v sing-box >/dev/null 2>&1 || { echo "Error: sing-box not found"; exit 1; }

# 默认值
UUID=${UUID:-$(uuidgen)} || { echo "Error: Failed to generate UUID"; exit 1; }
REALITY_KEYPAIR=$(sing-box generate reality-keypair) || { echo "Error: Failed to generate reality keypair"; exit 1; }
REALITY_PRIVATE_KEY=${REALITY_PRIVATE_KEY:-$(echo "$REALITY_KEYPAIR" | grep "PrivateKey" | cut -d'"' -f4)}
REALITY_PUBLIC_KEY=${REALITY_PUBLIC_KEY:-$(echo "$REALITY_KEYPAIR" | grep "PublicKey" | cut -d'"' -f4)}
SHORT_ID=${SHORT_ID:-$(openssl rand -hex 8 | cut -c1-8)} || { echo "Error: Failed to generate Short ID"; exit 1; }
SNI=${SNI:-www.apple.com}
SERVER_PORT=${SERVER_PORT:-443}
ENABLE_MULTIPLEX=${ENABLE_MULTIPLEX:-false}
# Northflank 域名（占位符，需用户替换）
SERVER_ADDRESS=${SERVER_ADDRESS:-your-northflank-domain.nf.app}

# 验证变量非空
[ -z "$UUID" ] && { echo "Error: UUID is empty"; exit 1; }
[ -z "$REALITY_PRIVATE_KEY" ] && { echo "Error: REALITY_PRIVATE_KEY is empty"; exit 1; }
[ -z "$REALITY_PUBLIC_KEY" ] && { echo "Error: REALITY_PUBLIC_KEY is empty"; exit 1; }
[ -z "$SHORT_ID" ] && { echo "Error: SHORT_ID is empty"; exit 1; }

# 替换 config.json 中的占位符
sed -i "s|{{UUID}}|$UUID|g" /etc/sing-box/config.json
sed -i "s|{{REALITY_PRIVATE_KEY}}|$REALITY_PRIVATE_KEY|g" /etc/sing-box/config.json
sed -i "s|{{SHORT_ID}}|$SHORT_ID|g" /etc/sing-box/config.json
sed -i "s|{{SNI}}|$SNI|g" /etc/sing-box/config.json
sed -i "s|{{SERVER_PORT}}|$SERVER_PORT|g" /etc/sing-box/config.json
sed -i "s|{{ENABLE_MULTIPLEX}}|$ENABLE_MULTIPLEX|g" /etc/sing-box/config.json

# 输出配置到日志
echo "Generated Config (1.12+ Compatible):"
echo "UUID: $UUID"
echo "REALITY Private Key: $REALITY_PRIVATE_KEY"
echo "Public Key for Client: $REALITY_PUBLIC_KEY"
echo "Short ID: $SHORT_ID"
echo "SNI: $SNI"
echo "Server Address: $SERVER_ADDRESS"
echo "Server Port: $SERVER_PORT"
echo "Multiplex Enabled: $ENABLE_MULTIPLEX"

# 生成分享链接
VLESS_URI="vless://$UUID@$SERVER_ADDRESS:$SERVER_PORT?security=reality&pbk=$REALITY_PUBLIC_KEY&sid=$SHORT_ID&type=tcp&fp=chrome&sni=$SNI#Northflank-Reality-1.12"
echo "VLESS Share Link: $VLESS_URI"

# 验证 sing-box 版本
echo "Sing-box Version:"
sing-box version

# 调试：检查 config.json
echo "Config file content:"
cat /etc/sing-box/config.json

# 运行 sing-box
exec sing-box run -c /etc/sing-box/config.json || {
  echo "Failed to start sing-box. Check config or logs."
  exit 1
}
