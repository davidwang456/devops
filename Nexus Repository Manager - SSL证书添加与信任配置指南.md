# Nexus Repository Manager - SSL证书添加与信任配置指南

本文档基于Sonatype官方文档，详细说明了如何在Nexus Repository Manager中添加和信任SSL证书，特别是针对远程仓库的SSL证书信任配置。

## 概述

Nexus Repository Manager需要信任SSL证书的主要场景包括：

1. 连接到使用HTTPS的远程代理仓库
2. 连接到SSL/TLS加密的服务器（如SMTP邮件服务器）
3. 连接到配置了LDAPS的LDAP服务器
4. 连接到特定的认证领域（如Crowd）

当远程仓库的SSL证书不被信任时，仓库可能会被自动阻止，外部请求会失败并显示类似`PKIX path building failed`的错误信息。

## 方法一：为特定远程仓库添加SSL证书信任

适用场景：仅需要为特定的远程代理仓库配置SSL证书信任

### 操作步骤：

1. 登录Nexus Repository Manager管理界面
2. 导航到需要配置的代理仓库设置页面
3. 在代理仓库配置中找到"**Use the Nexus truststore**"部分（仅当远程存储使用HTTPS URL时才会显示）
4. 点击"**View certificate**"按钮，弹出SSL证书详情对话框
5. 在证书详情对话框中，点击"**Add certificate to truststore**"按钮将证书添加到Nexus的信任存储中
6. 勾选"**Use certificates stored in Nexus to connect to external systems**"复选框，确认仓库管理器在验证远程仓库证书时应同时查询内部信任存储和JVM信任存储
7. 保存配置

### 注意事项：

- 此功能适用于远程证书不是由默认Java信任存储中包含的知名公共证书颁发机构颁发的情况，特别是组织内部使用的自签名证书
- 如果证书已添加，按钮文本会变为"**Remove certificate from trust store**"，可用于撤销信任
- 从信任存储中移除远程受信任证书后，需要重启仓库管理器才能使仓库变为不受信任状态

## 方法二：全局管理SSL证书信任

适用场景：需要集中管理所有远程SSL证书的信任，或管理非仓库类远程安全连接的证书

### 操作步骤：

1. 登录Nexus Repository Manager管理界面
2. 从设置菜单中选择"**Security**"子菜单中的"**SSL Certificates**"菜单项（需要有`nx-ssl-truststore`权限）
3. 在SSL证书管理界面中，可以查看已信任的证书列表
4. 点击列表中的证书行可以查看证书详情，包括主题、颁发者和证书详细信息
5. 要添加新证书，点击列表上方的"**Load certificate**"按钮，有两种添加方式：
   
   a. **从服务器加载**：
   - 选择"**Load from server**"
   - 输入远程站点的完整`https://`URL（例如`https://repo1.maven.org`）
   - 如果远程不可通过`https://`访问，则只输入主机名或IP地址，可选择后跟冒号和端口号（例如`example.com:8443`）
   - 点击"**Retrieve**"获取证书
   
   b. **粘贴PEM格式证书**：
   - 选择"**Paste PEM**"选项
   - 粘贴Base64编码的X.509 DER证书文本（必须包含在`-----BEGIN CERTIFICATE-----`和`-----END CERTIFICATE-----`行之间）
   - 可以使用以下命令获取PEM格式证书：`keytool -printcert -rfc -sslserver repo1.maven.org > repo1.pem`

6. 查看显示的证书详情，确认无误后点击"**Add Certificate**"完成添加

### 注意事项：

- 仓库管理器会合并默认JVM信任存储和私有信任存储，用于决定对远程服务器的信任
- 如果远程证书由默认Java信任存储中已包含的公共证书颁发机构签名，则无需显式信任远程证书
- 对于通过全局配置的代理服务器访问的所有远程站点，可以考虑信任代理服务器的根证书，简化证书管理

## 方法三：使用Keytool命令行工具管理SSL证书信任

适用场景：需要通过命令行管理SSL证书信任，或在无法访问Web界面的环境中配置

### 前提条件：

- 对SSL证书技术和Java VM如何实现此功能有基本了解
- 对主机操作系统和`keytool`程序有命令行访问权限
- 从运行仓库管理器的主机到要信任的远程SSL服务器有网络访问权限

### 操作步骤：

1. 复制默认JVM信任存储文件到自定义位置：
   ```bash
   cp $JAVA_HOME/jre/lib/security/cacerts $data-dir/custom-truststore.jks
   ```
   确保文件权限允许仓库管理器用户读取

2. 将额外的受信任证书导入到复制的信任存储文件中：
   ```bash
   # 从服务器获取证书并导入
   keytool -printcert -rfc -sslserver repo1.maven.org > repo1.pem
   keytool -importcert -file repo1.pem -alias repo1 -keystore $data-dir/custom-truststore.jks
   ```

3. 配置仓库管理器进程的JSSE系统属性，使其使用自定义信任存储而非默认文件：
   - 编辑Nexus启动脚本或配置文件
   - 添加以下JVM参数：
     ```
     -Djavax.net.ssl.trustStore=$data-dir/custom-truststore.jks
     -Djavax.net.ssl.trustStorePassword=changeit
     ```
   - 重启Nexus服务

### 注意事项：

- 这是一种更复杂的选项，建议仅在无法使用仓库管理器的SSL证书管理功能时使用
- 默认的truststore密码通常是"changeit"，但可能因安装而异
- 修改JVM参数后需要重启Nexus服务才能生效

## 常见问题与解决方案

1. **证书信任后仍然出现连接问题**：
   - 确认证书是否已过期
   - 检查证书的域名是否与访问的URL匹配
   - 验证是否启用了"Use certificates stored in Nexus"选项

2. **移除证书后仓库仍然可以连接**：
   - 移除证书后需要重启Nexus服务才能使更改生效

3. **通过代理服务器访问多个远程站点**：
   - 如果组织中所有远程站点都通过全局配置的代理服务器访问，且该代理服务器重写了每个SSL证书，可以考虑仅信任代理服务器的根证书

4. **证书格式转换**：
   - 如果收到的证书格式不是PEM，可以使用以下命令转换：
     ```bash
     # DER格式转PEM
     openssl x509 -inform der -in certificate.der -out certificate.pem
     ```

## 最佳实践

1. 优先使用Nexus Web界面管理SSL证书，这是最简单和推荐的方法
2. 为特定仓库添加证书时，确保同时勾选"Use certificates stored in Nexus"选项
3. 定期审核和更新证书，确保证书不会过期
4. 在生产环境中修改证书配置前，先在测试环境验证
5. 保持Nexus Repository Manager更新到最新版本，以获取最新的安全和功能改进
