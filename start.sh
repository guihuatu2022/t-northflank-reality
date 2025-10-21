#!/bin/bash
set -e
DEBUG=true
debug() {
    if [ "$DEBUG" = "true" ]; then
        echo "[DEBUG] $1"
    fi
}
KEYS_DIR="/data/reality-keys"
CONFIG_FILE="/etc/singbox/config.json"
LOG_FILE="/var/log/singbox/singbox.log"
mkdir -p $KEYS_DIR || { echo "创建密钥目录失败"; exit 1; }
debug "密钥目录: $KEYS_DIR"
debug "===== 处理变量 ====="
CONTAINER_DOMAIN=${CONTAINER_DOMAIN:-""}
if [ -z "$CONTAINER_DOMAIN" ]; then
    echo "[ERROR] 必须设置CONTAINER_DOMAIN（容器子域名）"
    exit 1
fi
debug "容器域名: $CONTAINER_DOMAIN"
PORT=${PORT:-8443}
debug "端口: $PORT"
UUID=${UUID:-$(uuidgen)}
debug "UUID: $UUID"
REALITY_PRIVATE_KEY=${REALITY_PRIVATE_KEY:-""}
REALITY_PUBLIC_KEY=${REALITY_PUBLIC_KEY:-""}
if [ -z "$REALITY_PRIVATE_KEY" ] || [ -z "$REALITY_PUBLIC_KEY" ]; then
    debug "无用户密钥，加载或生成新密钥"
    if [ -f "$KEYS_DIR/private.key" ] && [ -f "$KEYS_DIR/public.key" ]; then
        REALITY_PRIVATE_KEY=$(cat $KEYS_DIR/private.key)
        REALITY_PUBLIC_KEY=$(cat $KEYS_DIR/public.key)
    else
        KEY_PAIR=$(sing-box generate reality-keypair)
        REALITY_PRIVATE_KEY=$(echo "$KEY_PAIR" | grep "Private Key" | awk '{print $3}')
        REALITY_PUBLIC_KEY=$(echo "$KEY_PAIR" | grep "Public Key" | awk '{print $3}')
        echo "$REALITY_PRIVATE_KEY" > $KEYS_DIR/private.key
        echo "$REALITY_PUBLIC_KEY" > $KEYS_DIR/public.key
    fi
else
    debug "使用用户提供的密钥"
    echo "$REALITY_PRIVATE_KEY" > $KEYS_DIR/private.key
    echo "$REALITY_PUBLIC_KEY" > $KEYS_DIR/public.key
fi
REALITY_SHORT_ID=${REALITY_SHORT_ID:-$(openssl rand -hex 4)}
debug "Short ID: $REALITY_SHORT_ID"
SERVER_NAME=${SERVER_NAME:-"www.apple.com"}
debug "SNI: $SERVER_NAME"
debug "===== 生成配置 ====="
cat > $CONFIG_FILE << EOF
{
  "log": {
    "level": "debug",
    "output": "$LOG_FILE",
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "vless",
      "listen": "0.0.0.0",
      "port": $PORT,
      "users": [{"uuid": "$UUID", "flow": "xtls-rprx-vision-udp443"}],
      "transport": {
        "type": "tcp",
        "tcp": {"accept_proxy_protocol": false, "no_delay": true},
        "tls": {
          "enabled": true,
          "type": "reality",
          "reality": {
            "private_key": "$REALITY_PRIVATE_KEY",
            "short_id": ["$REALITY_SHORT_ID"],
            "server_names": ["$SERVER_NAME"],
            "max_time_diff": 30,
            "fallbacks": [{"dest": "$SERVER_NAME:443", "xver": 0}]
          }
        }
      }
    }
  ],
  "outbounds": [{"type": "direct"}]
}
EOF
SHARE_LINK="vless://$UUID@$CONTAINER_DOMAIN:$PORT?encryption=none&flow=xtls-rprx-vision-udp443&security=reality&sni=$SERVER_NAME&fp=chrome&pbk=$REALITY_PUBLIC_KEY&sid=$REALITY_SHORT_ID&type=tcp&headerType=none#Northflank-Reality"
echo "===== 客户端链接 ====="
echo $SHARE_LINK
echo "======================"
sing-box run -c $CONFIG_FILE &
tail -f $LOG_FILE
