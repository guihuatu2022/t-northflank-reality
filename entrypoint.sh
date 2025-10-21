#!/usr/bin/env bash

# 显示sing-box版本信息
echo "sing-box 版本信息:"
/usr/local/bin/sing-box version
echo "========================"

# 生成配置文件
echo "正在生成配置文件..."

# 检查并安装openssl（如果缺失）
if ! command -v openssl &> /dev/null; then
    echo "正在安装openssl..."
    if command -v apk &> /dev/null; then
        apk add --no-cache openssl
    elif command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y openssl
    elif command -v yum &> /dev/null; then
        yum install -y openssl
    fi
fi

# 检查并安装wget（如果缺失）
if ! command -v wget &> /dev/null; then
    echo "正在安装wget..."
    if command -v apk &> /dev/null; then
        apk add --no-cache wget
    elif command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y wget
    elif command -v yum &> /dev/null; then
        yum install -y wget
    fi
fi

# 读取环境变量或使用默认值
PORT=${PORT:-8443}
UUID=${UUID:-$(cat /proc/sys/kernel/random/uuid)}
SHORT_ID=${SHORT_ID:-$(openssl rand -hex 8)}
SERVER_NAME=${SERVER_NAME:-"m.media-amazon.com"}

# 检查并生成UUID
if [[ -z "${UUID}" ]]; then
    echo "生成新的UUID..."
    UUID=$(cat /proc/sys/kernel/random/uuid)
fi
echo "使用的UUID: $UUID"

# 检查并生成SHORT_ID
if [[ -z "${SHORT_ID}" ]]; then
    echo "生成新的Short ID..."
    SHORT_ID=$(openssl rand -hex 8)
fi
echo "使用的Short ID: $SHORT_ID"

echo "使用的服务器名称: $SERVER_NAME"

# 检查并生成REALITY密钥对
if [[ -z "${PRIVATE_KEY}" ]]; then
    echo "生成新的REALITY密钥对..."
    # 使用sing-box生成密钥对
    KEY_OUTPUT=$(/usr/local/bin/sing-box generate reality-keypair 2>&1)
    echo "密钥对生成输出: $KEY_OUTPUT"
    
    # 提取私钥和公钥（根据实际输出格式）
    if echo "$KEY_OUTPUT" | grep -q "PrivateKey:"; then
        # 处理新格式输出（每行一个字段）
        PRIVATE_KEY=$(echo "$KEY_OUTPUT" | grep "PrivateKey:" | awk '{print $2}')
        PUBLIC_KEY=$(echo "$KEY_OUTPUT" | grep "PublicKey:" | awk '{print $2}')
    else
        # 处理旧格式输出（JSON格式）
        PRIVATE_KEY=$(echo "$KEY_OUTPUT" | grep -o '"PrivateKey":"[^"]*"' | sed 's/"PrivateKey":"//' | sed 's/"$//')
        PUBLIC_KEY=$(echo "$KEY_OUTPUT" | grep -o '"PublicKey":"[^"]*"' | sed 's/"PublicKey":"//' | sed 's/"$//')
    fi
else
    # 如果提供了私钥，生成对应的公钥
    KEY_OUTPUT=$(/usr/local/bin/sing-box generate reality-keypair --private-key "${PRIVATE_KEY}" 2>&1)
    echo "公钥生成输出: $KEY_OUTPUT"
    if echo "$KEY_OUTPUT" | grep -q "PublicKey:"; then
        # 处理新格式输出（每行一个字段）
        PUBLIC_KEY=$(echo "$KEY_OUTPUT" | grep "PublicKey:" | awk '{print $2}')
    else
        # 处理旧格式输出（JSON格式）
        PUBLIC_KEY=$(echo "$KEY_OUTPUT" | grep -o '"PublicKey":"[^"]*"' | sed 's/"PublicKey":"//' | sed 's/"$//')
    fi
fi

echo "使用的私钥: $PRIVATE_KEY"
echo "使用的公钥: $PUBLIC_KEY"

# 验证所有参数
if [[ -z "$UUID" ]]; then
    echo "错误：UUID生成失败"
    exit 1
fi

if [[ -z "$SHORT_ID" ]]; then
    echo "错误：Short ID生成失败"
    exit 1
fi

if [[ -z "$PRIVATE_KEY" || ${#PRIVATE_KEY} -lt 32 ]]; then
    echo "错误：私钥生成失败或无效"
    exit 1
fi

if [[ -z "$PUBLIC_KEY" || ${#PUBLIC_KEY} -lt 32 ]]; then
    echo "错误：公钥生成失败或无效"
    exit 1
fi

# 从模板生成配置文件
echo "从模板生成配置文件..."
cp /app/config.json /tmp/config.json.template
sed -i "s/UUID_PLACEHOLDER/${UUID}/g" /tmp/config.json.template
sed -i "s/SNI_PLACEHOLDER/${SERVER_NAME}/g" /tmp/config.json.template
sed -i "s/PRIVATE_KEY_PLACEHOLDER/${PRIVATE_KEY}/g" /tmp/config.json.template
sed -i "s/SHORT_ID_PLACEHOLDER/${SHORT_ID}/g" /tmp/config.json.template

mv /tmp/config.json.template /app/config.json

# 显示配置信息
echo "==================== 配置信息 ===================="
echo "端口 (PORT): ${PORT}"
echo "UUID: ${UUID}"
echo "服务器名称 (SERVER_NAME): ${SERVER_NAME}"
echo "Short ID: ${SHORT_ID}"
echo "Public Key: ${PUBLIC_KEY}"
echo "=================================================="

# 显示生成的配置文件用于调试
echo "生成的配置文件:"
cat /app/config.json
echo "=================================================="

# 验证配置文件
echo "验证配置文件..."
if /usr/local/bin/sing-box check -c /app/config.json; then
    echo "配置文件验证通过"
else
    echo "配置文件验证失败"
    cat /app/config.json
    exit 1
fi

# 获取公网IP地址
PUBLIC_IP=""
if command -v wget &> /dev/null; then
    PUBLIC_IP=$(wget -qO- https://ipinfo.io/ip 2>/dev/null)
fi

# 生成分享链接
ENCODED_UUID=$(echo -n "${UUID}" | sed 's/+/%2B/g; s/\//%2F/g; s/=/%3D/g')
ENCODED_SNI=$(echo -n "${SERVER_NAME}" | sed 's/+/%2B/g; s/\//%2F/g; s/=/%3D/g')
ENCODED_PBK=$(echo -n "${PUBLIC_KEY}" | sed 's/+/%2B/g; s/\//%2F/g; s/=/%3D/g')
ENCODED_SID=$(echo -n "${SHORT_ID}" | sed 's/+/%2B/g; s/\//%2F/g; s/=/%3D/g')

SHARE_LINK="vless://${ENCODED_UUID}@0.0.0.0:${PORT}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${ENCODED_SNI}&fp=chrome&pbk=${ENCODED_PBK}&sid=${ENCODED_SID}&type=tcp&headerType=none#northflank-reality"

echo ""
echo "==================== 分享链接 ===================="
if [[ -n "$PUBLIC_IP" ]]; then
    echo "容器公网IP: $PUBLIC_IP"
    echo "你可以使用以下链接连接（将0.0.0.0替换为公网IP）:"
else
    echo "注意：部署完成后，请将链接中的 0.0.0.0 替换为 Northflank 分配给你的域名或 IP 地址"
fi
echo "${SHARE_LINK}"
echo "=================================================="
echo ""
echo "在 Northflank 上，你需要在服务配置中查看分配的域名或 IP 地址"
echo ""
echo "客户端配置参数："
echo "  UUID: ${UUID}"
echo "  服务器地址: 部署后替换为 Northflank 分配的地址"
echo "  服务器端口: ${PORT}"
echo "  流控: xtls-rprx-vision"
echo "  传输协议: tcp"
echo "  TLS: reality"
echo "  SNI: ${SERVER_NAME}"
echo "  指纹: chrome"
echo "  PublicKey: ${PUBLIC_KEY}"
echo "  ShortID: ${SHORT_ID}"
echo ""

# 启动sing-box
echo "启动sing-box..."
/usr/local/bin/sing-box run -c /app/config.json
