t-northflank-reality: Sing-box VLESS+TCP+REALITY (1.12+ Compatible)
支持 sing-box 1.12+ 的 VLESS+TCP+REALITY 部署。新增 TLS 碎片化提升伪装。
快速部署

Fork/上传此仓库到 guihuatu2022/t-northflank-reality.
在 Northflank 创建 Free Project > Service > 链接 GitHub 仓库 > 选择 Docker 构建。
配置端口：443 (TCP)。
添加环境变量（可选，默认自动生成）：
UUID: 自定义 UUID (e.g., bf000d23-0752-40b4-affe-68f7707a9661)。
REALITY_PRIVATE_KEY: REALITY 私钥。
SHORT_ID: 8 位 hex (e.g., 01234567)。
SNI: 伪装域名 (默认 www.apple.com)。
SERVER_PORT: 端口 (默认 443)。
ENABLE_MULTIPLEX: true/false (默认 false)。
SERVER_ADDRESS: Northflank 域名 (e.g., your-service.nf.app)，用于分享链接。


部署！Northflank 提供公网域名。

客户端配置

查看日志中的 VLESS Share Link（格式：vless://UUID@your-domain:443?...）。
示例 URI：vless://{{UUID}}@your-domain:443?security=reality&pbk={{PUBLIC_KEY}}&sid={{SHORT_ID}}&type=tcp&fp=chrome&sni={{SNI}}#Northflank-Reality-1.12
替换 your-domain 为 Northflank 分配的域名（或设置 SERVER_ADDRESS 环境变量）。

调试

查看 Northflank 日志，确认：
Starting script in bash...
Sing-box Version（1.12+）
VLESS Share Link（完整 URI）
Config file content（无占位符，变量正确替换）


若失败，检查：
config.json 格式（JSON 需严格，无 listen_options 等废弃字段）。
工具缺失（uuidgen, openssl）。
环境变量注入（Northflank UI）。


本地测试：docker build -t test . && docker run -p 443:443 test.

变更日志

修复：移除 listen_options，使用 tcp_reuseaddr（1.12+ 兼容）。
修复：更新 DNS 格式，移除 default_nameserver。
修复：安装 util-linux（uuidgen）和 openssl。
修复：ENTRYPOINT ["/bin/bash"] 确保脚本执行。
新增：默认 SNI 为 www.apple.com，输出 VLESS 分享链接。
