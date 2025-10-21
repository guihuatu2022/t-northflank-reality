#!/bin/bash
set -e  # 遇到错误立即退出（便于调试）

#######################################
# 调试配置：开启详细输出
#######################################
DEBUG=true  # 设为true启用调试输出，false关闭
debug() {
    if [ "$DEBUG" = "true" ]; then
        echo "[DEBUG] $1"
    fi
}

#######################################
# 路径定义
#######################################
KEYS_DIR="/data/reality-keys"       # 持久化密钥目录
CONFIG_FILE="/etc/singbox/config.json"  # singbox配置文件
LOG_FILE="/var/log/singbox/singbox.log" # 运行日志

# 确保目录存在（调试：打印创建过程）
debug "创建密钥目录: $KEYS_DIR"
mkdir -p $KEYS_DIR || { echo "创建密钥目录失败"; exit 1; }
debug "密钥目录权限: $(ls -ld $KEYS_DIR)"

#######################################
# 变量处理（支持用户自定义，未提供则自动生成）
#######################################
debug "===== 开始处理变量 ====="

# 1. 容器访问域名（必填：Northflank子域名，如xxx.northflank.app）
CONTAINER_DOMAIN=${CONTAINER_DOMAIN:-""}
if [ -z "$CONTAINER_DOMAIN" ]; then
    echo "[ERROR] 未设置CONTAINER_DOMAIN（容器子域名），请在Northflank控制台获取后配置"
    exit 1
fi
debug "CONTAINER_DOMAIN: $CONTAINER_DOMAIN"

# 2. 端口（默认8443，需与Northflank暴露端口一致）
PORT=${PORT:-8443}
debug "端口: $PORT"

# 3. vless用户UUID（用户可自定义，默认自动生成）
UUID=${UUID:-$(uuidgen)}
debug "UUID: $UUID"

# 4. Reality密钥对（用户可自定义，未提供则自动生成）
# 私钥（服务器端用）
REALITY_PRIVATE_KEY=${REALITY_PRIVATE_KEY:-""}
# 公钥（客户端用）
REALITY_PUBLIC_KEY=${REALITY_PUBLIC_KEY:-""}

# 若用户未提供密钥对，则自动生成并持久化
if [ -z "$REALITY_PRIVATE_KEY" ] || [ -z "$REALITY_PUBLIC_KEY" ]; then
    debug "未检测到用户提供的密钥对，开始自动生成..."
    # 检查是否有历史密钥（容器重启时复用）
    if [ -f "$KEYS_DIR/private.key" ] && [ -f "$KEYS_DIR/public.key" ]; then
        debug "发现历史密钥，加载中..."
        REALITY_PRIVATE_KEY=$(cat $KEYS_DIR/private.key)
        REALITY_PUBLIC_KEY=$(cat $KEYS_DIR/public.key)
    else
        debug "生成新的Reality密钥对..."
        # 使用singbox生成密钥对（1.12+兼容）
        KEY_PAIR=$(singbox generate reality-keypair)
        REALITY_PRIVATE_KEY=$(echo "$KEY_PAIR" | grep "Private Key" | awk '{print $3}')
        REALITY_PUBLIC_KEY=$(echo "$KEY_PAIR" | grep "Public Key" | awk '{print $3}')
        # 持久化保存（避免重启丢失）
        echo "$REALITY_PRIVATE_KEY" > $KEYS_DIR/private.key
        echo "$REALITY_PUBLIC_KEY" > $KEYS_DIR/public.key
        debug "密钥对已保存至: $KEYS_DIR"
        debug "私钥长度: ${#REALITY_PRIVATE_KEY}，公钥长度: ${#REALITY_PUBLIC_KEY}"  # 校验密钥格式
    fi
else
    debug "使用用户提供的密钥对"
    # 保存用户提供的密钥（便于后续复用）
    echo "$REALITY_PRIVATE_KEY" > $KEYS_DIR/private.key
    echo "$REALITY_PUBLIC_KEY" > $KEYS_DIR/public.key
fi

# 5. Reality Short ID（非空，1.12+要求，默认生成8位16进制）
REALITY_SHORT_ID=${REALITY_SHORT_ID:-$(openssl rand -hex 4)}  # 4字节=8位16进制
debug "REALITY_SHORT_ID: $REALITY_SHORT_ID"

# 6. SNI（目标域名，默认www.apple.com，增强兼容性）
SERVER_NAME=${SERVER_NAME:-"www.apple.com"}
debug "SNI (server_names): $SERVER_NAME"

debug "===== 变量处理完成 ====="

#######################################
# 生成singbox 1.12+配置文件（带调试信息）
#######################################
debug "开始生成配置文件: $CONFIG_FILE"
cat > $CONFIG_FILE << EOF
{
  "log": {
    "level": "debug",  # 调试模式：输出详细日志
    "output": "$LOG_FILE",
    "timestamp": true  # 日志带时间戳，便于排查问题
  },
  "inbounds": [
    {
      "type": "vless",
      "listen": "0.0.0.0",  # 必须监听0.0.0.0，否则容器外无法访问
      "port": $PORT,
      "users": [
        {
          "uuid": "$UUID",
          "flow": "xtls-rprx-vision-udp443"  # 1.12+推荐flow，支持UDP
        }
      ],
      "transport": {
        "type": "tcp",
        "tcp": {
          "accept_proxy_protocol": false,
          "no_delay": true,
          "keep_alive": true
        },
        "tls": {  # 1.12+关键变化：reality配置移至transport.tls
          "enabled": true,
          "type": "reality",
          "reality": {
            "private_key": "$REALITY_PRIVATE_KEY",
            "short_id": ["$REALITY_SHORT_ID"],  # 非空数组
            "server_names": ["$SERVER_NAME"],
            "max_time_diff": 30,  # 1.12+新增：允许的时间偏差（秒）
            "fallbacks": [
              {
                "dest": "$SERVER_NAME:443",  # 回落地址与SNI一致
                "xver": 0
              }
            ]
          }
        }
      }
    }
  ],
  "outbounds": [
    {
      "type": "direct"
    }
  ]
}
EOF

# 调试：打印配置文件内容（敏感信息打码）
debug "配置文件生成完成，内容如下（私钥已打码）:"
cat $CONFIG_FILE | sed "s/$REALITY_PRIVATE_KEY/[PRIVATE_KEY_HIDDEN]/g"

#######################################
# 生成客户端分享链接
#######################################
debug "生成客户端分享链接..."
SHARE_LINK="vless://$UUID@$CONTAINER_DOMAIN:$PORT?encryption=none&flow=xtls-rprx-vision-udp443&security=reality&sni=$SERVER_NAME&fp=chrome&pbk=$REALITY_PUBLIC_KEY&sid=$REALITY_SHORT_ID&type=tcp&headerType=none#Northflank-Reality"

echo "===== 部署成功！客户端配置链接 ====="
echo $SHARE_LINK
echo "==================================="

#######################################
# 启动singbox并输出实时日志（便于调试）
#######################################
debug "启动singbox，日志输出至: $LOG_FILE"
echo "singbox启动中，实时日志如下："
sing-box run -c $CONFIG_FILE &  # 后台启动，便于同时输出日志
tail -f $LOG_FILE  # 实时显示日志（容器退出时终止）
