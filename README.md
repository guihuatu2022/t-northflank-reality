# Singbox VLESS+TCP+REALITY for Northflank

本项目用于在 Northflank 免费容器服务上部署基于 sing-box 内核的 VLESS+TCP+REALITY 协议代理服务。

## 项目特点

1. 使用最新的 sing-box 内核
2. 实现 VLESS+TCP+REALITY 协议组合
3. 无需域名和证书，使用 REALITY 伪装技术
4. 支持环境变量自定义配置
5. 自动生成配置和分享链接
6. 专为 Northflank 容器环境优化

## 部署方式

### 1. 在 Northflank 上创建服务

1. 注册 [Northflank](https://northflank.com/) 账号
2. 创建一个新的服务 (Service)
3. 选择从 Dockerfile 构建
4. 连接你的 GitHub 仓库或直接上传代码
5. 设置构建路径为 `t-northflank-reality`
6. 添加端口: 
   - Name: `proxy`
   - Port: `8443`
   - Protocol: `TCP`

### 2. 环境变量配置

支持以下环境变量来自定义配置：

| 变量名 | 是否必须 | 默认值 | 说明 |
|--------|---------|--------|------|
| `PORT` | 否 | `8443` | 服务监听端口 |
| `UUID` | 否 | 自动生成 | 用户UUID |
| `SHORT_ID` | 否 | 自动生成 | REALITY Short ID |
| `SERVER_NAME` | 否 | `m.media-amazon.com` | 伪装的服务器名称（SNI） |
| `PRIVATE_KEY` | 否 | 自动生成 | REALITY私钥 |

注意：如果未设置 `PRIVATE_KEY`，系统会在每次启动时生成新的密钥对。

### 3. 部署和运行

1. 完成环境变量设置后，点击部署
2. 等待构建和部署完成
3. 在服务详情页面找到分配的域名或 IP 地址
4. 将日志中生成的分享链接中的 `0.0.0.0` 替换为该域名或 IP 地址

## 连接方式

部署成功后，从日志中获取生成的 VLESS 链接，并将其中的 `0.0.0.0` 替换为 Northflank 为你的服务分配的域名或 IP 地址，然后复制到支持的客户端中使用，如:

- v2rayN (Windows)
- v2rayNG (Android)
- Shadowrocket (iOS)
- NekoBox (Android/Linux)
- V2RayXTLS (MacOS)

## 技术说明

### REALITY 介绍

REALITY 是一种新的传输协议，具有以下优势：

1. 无需域名和 TLS 证书
2. 流量伪装程度高，难以被检测识别
3. 性能优于传统 TLS
4. 防止主动探测

### 项目结构

```
t-northflank-reality/
├── Dockerfile          # Docker 镜像构建文件
├── entrypoint.sh       # 容器入口点脚本
├── config.json         # sing-box 配置模板
└── README.md           # 说明文档
```

## 故障排除

### 无法连接

1. 检查 Northflank 服务日志
2. 确认端口设置正确（TCP 8443）
3. 检查环境变量配置
4. 验证分享链接格式是否正确

### 性能优化

如果遇到性能问题，可以尝试：

1. 更换 `SERVER_NAME` 为其他知名网站
2. 更换不同的 `SHORT_ID`
3. 使用固定的 `PRIVATE_KEY` 而不是每次都生成新的

## 扩展功能

未来计划增加的功能：

1. 支持多用户
2. 集成更多协议 (VMess, Trojan等)
3. 添加流量统计面板
4. 支持更多伪装网站选项

## 许可证

本项目基于 MIT 许可证开源，详情请见 [LICENSE](LICENSE) 文件。

## 免责声明

本项目仅供学习和技术研究使用，请遵守当地法律法规，不要用于任何非法用途。
