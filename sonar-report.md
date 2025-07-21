# SonarQube PDF 报告下载与常见问题排查

## 1. 通过 REST API 下载 PDF 报告

SonarQube 支持通过 REST API 下载治理报告（Governance Report）PDF 文件。以下为标准用法：

### 示例命令

```bash
curl -X GET "${SONAR_URL}/api/governance_reports/download?componentKey=${PROJECT_KEY}&branchKey=main" \
  -H "Authorization: Bearer ${TOKEN}" \
  --output "governance_report_$(date +%Y%m%d_%H%M%S).pdf"
```

#### 参数说明
- `${SONAR_URL}`：SonarQube 服务器地址（如 http://sonarqube.example.com:9000）
- `${PROJECT_KEY}`：项目 key
- `branchKey=main`：指定分支（如 main、develop、feature/xxx 等）
- `${TOKEN}`：SonarQube API Token（推荐 Bearer 方式）

#### 其他用法
- 也可以用 `-G -d` 方式传参，和直接拼接到 URL 效果一样。
- `--output` 后面可自定义保存的文件名。

#### 权限说明
- 需要有权限的 Token，否则会报 401/403。
- 治理报告接口通常需要企业版/治理插件支持，社区版无 PDF 报告功能。

---

## 2. 401 错误排查

出现 401 错误，说明认证失败，常见原因和解决办法如下：

### 2.1 Token 是否正确
- 确认 `${TOKEN}` 是有效的 SonarQube 用户 Token，且有权限访问该项目。
- 推荐用 Bearer 方式：
  ```bash
  -H "Authorization: Bearer ${TOKEN}"
  ```
- 也可以用 Basic 方式（老版本）：
  ```bash
  -u "${TOKEN}:"
  ```

### 2.2 Token 权限
- Token 所属用户必须有浏览项目和下载报告的权限。
- 治理报告（governance_reports）需要更高权限（如管理员或项目管理员）。

### 2.3 Token 生成方式
- 登录 SonarQube → 右上角头像 → My Account → Security → 生成 Token。
- 复制完整 Token，只显示一次。

### 2.4 服务器地址和 API 路径
- 确认 `${SONAR_URL}` 没有拼写错误，能正常访问。
- 访问 `${SONAR_URL}/api/system/status` 能返回 JSON 说明服务正常。

### 2.5 其他排查
- Token 是否过期/被删除：重新生成试试。
- 是否有代理/防火墙：有时会拦截请求头。
- SonarQube 版本：部分 API 只在企业版/治理插件下可用，社区版无此功能。

### 2.6 检查 Token 是否生效
可以先用 curl 测试一个简单的 API，比如：

```bash
curl -X GET "${SONAR_URL}/api/authentication/validate" -H "Authorization: Bearer ${TOKEN}"
```
返回
```json
{"valid":true}
```
说明 Token 有效。

---

## 3. 常见问题总结
- 401 基本都是 Token 问题或权限不足。
- 建议重新生成 Token，确认权限，优先用 Bearer 方式。
- 如果是企业版功能，社区版无效也会报 401/403。

如还有问题，请贴出完整 curl 命令（可打码 Token），以及 SonarQube 版本和 Token 生成方式，可进一步定位！ 
