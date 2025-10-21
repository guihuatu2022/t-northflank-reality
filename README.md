# t-northflank-reality  
基于Northflank免费容器服务部署singbox 1.12+，支持vless+tcp+reality协议，含自动配置与调试功能。


## 项目特点  
- 适配singbox 1.12+最新配置规范，支持reality协议  
- 自动生成密钥对、UUID等参数，也支持用户自定义  
- 包含详细调试日志，便于排查部署问题  
- 持久化存储密钥，容器重启后配置不变  


## 部署前提  
1. 注册Northflank账号（免费计划即可）  
2. 创建项目（如`reality-project`）  
3. 创建1GB持久卷（如`reality-keys`），挂载路径设为`/data`  


## 部署步骤  
1. 克隆仓库：  
   ```bash
   git clone https://github.com/你的用户名/t-northflank-reality.git
