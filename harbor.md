## Harbor 机器人账户

Harbor 的机器人账户（Robot Account）主要用于自动化场景，比如 CI/CD 流程、自动化脚本或第三方系统与 Harbor 交互时，不需要使用真实用户账号，而是通过机器人账户进行认证和授权。机器人账户可以设置不同的权限级别（系统级或项目级），并可以指定具体的操作权限（如拉取镜像、推送镜像等），从而限制其访问范围。

### 使用方法

1. **创建机器人账户**：通过 Harbor 的 API（例如 POST /robots）创建一个机器人账户，指定名称、描述、权限和有效期等。
2. **获取机器人账户的密钥（Secret）**：创建成功后，Harbor 会返回一个密钥，这个密钥用于后续的认证。
3. **使用机器人账户进行认证**：在需要与 Harbor 交互的自动化流程中，使用机器人账户的名称和密钥进行认证，从而获得相应的操作权限。

通过这种方式，Harbor 的机器人账户提供了一种安全、可控的自动化访问机制。

### Docker 登录 Harbor 流程

当使用 `docker login` 命令登录 Harbor 时，会经过以下流程：

1. **认证流程**：
   - Docker 客户端向 Harbor 的认证服务发送认证请求
   - Harbor 验证用户名和密码
   - 认证成功后，Harbor 返回 JWT（JSON Web Token）令牌
   - Docker 客户端将令牌保存在本地（通常在 `~/.docker/config.json` 文件中）

2. **权限验证**：
   - 登录成功后，Docker 客户端在后续操作（如 push/pull）时使用令牌
   - Harbor 根据令牌中的用户信息验证操作权限
   - 如果用户没有相应权限，操作会被拒绝

3. **安全机制**：
   - 令牌有过期时间，需要定期重新登录
   - 令牌是加密的，确保传输安全
   - 可以设置令牌的有效期，增加安全性

### 令牌过期时间设置

Harbor 提供了两种方式设置令牌过期时间：

1. **系统级设置**：
   - 通过环境变量 `ROBOT_TOKEN_DURATION` 设置
   - 默认值为 30 天
   - 可以在 Harbor 的配置文件中修改

2. **机器人账户级设置**：
   - 创建机器人账户时，可以通过 `duration` 参数设置
   - 可以设置为具体的天数（正整数）
   - 可以设置为 -1，表示永不过期
   - 如果不设置，则使用系统默认值

注意：为了安全考虑，建议：
- 不要设置过长的过期时间
- 定期轮换密钥
- 对于重要的自动化流程，建议使用较短的过期时间

### Docker 通过 Token 登录 Harbor 的详细步骤

1. **获取 Token**：
   - 登录 Harbor Web 界面
   - 进入"机器人账户"页面
   - 创建新的机器人账户或查看现有机器人账户
   - 记录机器人账户的名称和密钥（Secret）

2. **使用 Token 登录**：
   ```bash
   # 使用机器人账户名称和密钥登录
   docker login <harbor-host> --username <robot-account-name> --password <robot-account-secret>
   ```

3. **验证登录状态**：
   ```bash
   # 查看 Docker 登录配置
   cat ~/.docker/config.json
   ```

4. **使用示例**：
   ```bash
   # 示例：登录到 Harbor 服务器
   docker login harbor.example.com --username robot$myrobot --password mysecret
   
   # 登录成功后，可以执行 pull/push 操作
   docker pull harbor.example.com/project/image:tag
   docker push harbor.example.com/project/image:tag
   ```

5. **自动化脚本中的使用**：
   ```bash
   # 在 CI/CD 脚本中使用
   echo $ROBOT_SECRET | docker login $HARBOR_HOST --username $ROBOT_NAME --password-stdin
   ```

6. **注意事项**：
   - 确保机器人账户有足够的权限执行所需操作
   - 定期更新密钥以提高安全性
   - 在自动化脚本中，建议使用环境变量存储敏感信息
   - 如果使用 CI/CD，建议将密钥存储在 CI/CD 系统的密钥管理功能中

### 查看 Docker 登录用户身份

有几种方法可以查看当前 Docker 登录的用户身份：

1. **查看 Docker 配置文件**：
   ```bash
   # 查看 Docker 配置文件中的认证信息
   cat ~/.docker/config.json
   ```
   输出示例：
   ```json
   {
     "auths": {
       "harbor.example.com": {
         "auth": "cm9ib3QkbXlyb2JvdDpteXNlY3JldA=="  # Base64 编码的用户名和密码
       }
     }
   }
   ```

2. **使用 Docker 命令查看**：
   ```bash
   # 查看当前登录的 registry 信息
   docker info | grep "Registry"
   ```

3. **在 Harbor 界面查看**：
   - 登录 Harbor Web 界面
   - 进入"审计日志"页面
   - 可以查看所有用户的登录和操作记录
   - 可以看到具体是哪个用户（包括机器人账户）执行了操作

4. **通过 API 查看**：
   ```bash
   # 使用 curl 命令查看当前认证信息
   curl -u <username>:<password> https://<harbor-host>/api/v2.0/users/current
   ```

5. **查看登录历史**：
   ```bash
   # 查看 Docker 的登录历史记录
   history | grep "docker login"
   ```

注意：
- 配置文件中的认证信息是 Base64 编码的，需要解码才能看到实际的用户名和密码
- 建议定期检查登录记录，确保没有未授权的访问
- 如果发现异常登录，及时更改密码或删除旧的认证信息

### Docker Logout 验证方法

执行 `docker logout` 后，可以通过以下方法验证是否成功退出：

1. **查看 Docker 配置文件**：
   ```bash
   # 执行登出命令
   docker logout <harbor-host>
   
   # 查看配置文件中的认证信息是否已删除
   cat ~/.docker/config.json
   ```
   如果成功登出，对应的 registry 的认证信息应该已被删除。

2. **尝试执行需要认证的操作**：
   ```bash
   # 尝试拉取镜像，应该会提示需要认证
   docker pull <harbor-host>/project/image:tag
   ```
   如果提示需要认证，说明登出成功。

3. **检查 Harbor 审计日志**：
   - 登录 Harbor Web 界面
   - 查看审计日志
   - 确认最后一次操作是登出操作

4. **使用 API 验证**：
   ```bash
   # 尝试访问需要认证的 API
   curl https://<harbor-host>/api/v2.0/users/current
   ```
   如果返回 401 未授权错误，说明登出成功。

5. **检查登录状态**：
   ```bash
   # 查看 Docker 信息中的 registry 配置
   docker info | grep "Registry"
   ```
   如果不再显示已登录的 registry，说明登出成功。

注意：
- 登出后，本地缓存的认证信息会被删除
- 如果需要重新登录，需要重新执行 `docker login` 命令
- 建议在登出后验证一下，确保认证信息确实被清除

### Harbor 管理员权限问题解决

如果使用 admin 账户登录 Harbor 时，创建用户按钮显示为灰色（不可用），可以通过以下步骤解决：

1. **检查认证模式**：
   - 登录 Harbor Web 界面
   - 进入"系统管理" -> "配置管理"
   - 检查"认证模式"设置
   - 如果使用外部认证（如 LDAP、OIDC 等），需要确保：
     - 外部认证服务配置正确
     - admin 用户在外部认证系统中有正确的权限

2. **检查用户权限**：
   - 确认当前登录的 admin 用户是否具有系统管理员权限
   - 进入"系统管理" -> "用户管理"
   - 检查 admin 用户的角色是否为"系统管理员"

3. **重置管理员权限**：
   ```bash
   # 使用数据库命令重置管理员权限
   docker exec -it harbor-db psql -U postgres -d registry
   # 在数据库命令行中执行：
   UPDATE harbor_user SET sysadmin_flag = true WHERE username = 'admin';
   ```

4. **检查 Harbor 配置**：
   - 检查 Harbor 的配置文件（harbor.yml）
   - 确保没有禁用用户管理功能
   - 确保数据库连接正常

5. **重启 Harbor 服务**：
   ```bash
   # 重启 Harbor 服务
   docker-compose down
   docker-compose up -d
   ```

6. **清除浏览器缓存**：
   - 清除浏览器缓存和 Cookie
   - 重新登录 Harbor

7. **检查日志**：
   ```bash
   # 查看 Harbor 核心服务日志
   docker logs harbor-core
   ```
   检查是否有权限相关的错误信息

注意：
- 修改配置后需要重启 Harbor 服务才能生效
- 如果使用外部认证，需要确保外部认证服务正常运行
- 建议定期备份数据库，以防配置出错
- 如果问题仍然存在，可以查看 Harbor 的详细日志以获取更多信息

### Harbor 配置信息存储位置

Harbor 的配置信息主要存储在数据库的 `properties` 表中，该表结构如下：

```sql
create table properties (
 id SERIAL NOT NULL,
 k varchar(64) NOT NULL,
 v varchar(128) NOT NULL,
 PRIMARY KEY(id),
 UNIQUE (k)
);
```

主要配置项包括：

1. **系统配置**：
   - `robot_token_duration`：机器人账户令牌有效期
   - `robot_name_prefix`：机器人账户名称前缀
   - `scan_all_policy`：镜像扫描策略

2. **查看配置**：
   ```bash
   # 连接到数据库
   docker exec -it harbor-db psql -U postgres -d registry
   
   # 查看所有配置
   SELECT * FROM properties;
   
   # 查看特定配置
   SELECT * FROM properties WHERE k = 'robot_token_duration';
   ```

3. **修改配置**：
   ```bash
   # 在数据库命令行中执行
   UPDATE properties SET v = '新值' WHERE k = '配置项名称';
   ```

4. **注意事项**：
   - 修改配置后需要重启 Harbor 服务才能生效
   - 建议在修改前备份数据库
   - 某些配置项可能需要特定的格式或值范围
   - 不建议直接修改数据库，最好通过 Harbor 的 Web 界面或 API 进行配置

### PostgreSQL 查询表的方法

在 PostgreSQL 中，有多种方法可以查询数据库中的表：

1. **使用 psql 命令**：
   ```bash
   # 连接到数据库
   docker exec -it harbor-db psql -U postgres -d registry
   
   # 列出所有表
   \dt
   
   # 列出所有表（包括系统表）
   \dt+
   
   # 列出特定 schema 的表
   \dt public.*
   ```

2. **使用 SQL 查询**：
   ```sql
   -- 查询所有表
   SELECT table_name 
   FROM information_schema.tables 
   WHERE table_schema = 'public';
   
   -- 查询表结构
   SELECT column_name, data_type, character_maximum_length
   FROM information_schema.columns
   WHERE table_name = '表名';
   
   -- 查询表大小
   SELECT pg_size_pretty(pg_total_relation_size('表名'));
   ```

3. **常用 psql 命令**：
   ```bash
   # 列出所有数据库
   \l
   
   # 列出所有 schema
   \dn
   
   # 列出所有表空间
   \db
   
   # 查看表结构
   \d 表名
   
   # 查看索引
   \di
   
   # 查看视图
   \dv
   ```

4. **查询表数据**：
   ```sql
   -- 查询表数据
   SELECT * FROM 表名 LIMIT 10;
   
   -- 查询表行数
   SELECT COUNT(*) FROM 表名;
   
   -- 查询表大小和行数
   SELECT 
       pg_size_pretty(pg_total_relation_size('表名')) as total_size,
       (SELECT COUNT(*) FROM 表名) as row_count;
   ```

5. **注意事项**：
   - 使用 `\dt` 命令时，默认只显示用户创建的表
   - 使用 `\dt+` 可以显示更多信息，包括表大小、描述等
   - 查询系统表时要注意权限问题
   - 建议使用 `LIMIT` 子句限制返回的行数
   - 对于大表，查询时要注意性能影响 

### Harbor 认证流程说明

Harbor 支持多种认证方式，包括 Keycloak OIDC 和 OpenLDAP。以下是这两种认证方式的详细说明：

#### Keycloak OIDC 认证流程

1. **配置阶段**:
- 在 Harbor 中配置 OIDC 认证模式,需要设置以下参数:
  - OIDC Provider Name: Keycloak 服务名称
  - OIDC Endpoint: Keycloak 服务器地址
  - Client ID: Harbor 在 Keycloak 中注册的客户端 ID
  - Client Secret: 客户端密钥
  - Scope: 授权范围,如 openid、profile 等
  - Username Claim: 用户名字段
  - Group Claim Name: 组信息字段
  - OIDC Admin Group: 管理员组名称

相关源码：
- 配置定义：`src/lib/config/userconfig.go`
- 配置界面：`src/portal/src/i18n/lang/zh-cn-lang.json` 中的 OIDC 相关配置项

2. **登录流程**:
- 用户访问 Harbor 登录页面
- 点击 OIDC 登录按钮,重定向到 Keycloak 登录页面
- 用户在 Keycloak 中输入凭证进行认证
- Keycloak 验证成功后,重定向回 Harbor 并携带授权码
- Harbor 使用授权码向 Keycloak 获取访问令牌和用户信息
- Harbor 根据用户信息创建或更新本地用户记录
- 用户成功登录 Harbor

相关源码：
- 登录处理：`src/core/controllers/base.go` 中的 `redirectForOIDC` 函数
- OIDC 认证：`src/pkg/oidc/helper.go` 中的 `AuthCodeURL` 和 `getOauthConf` 函数
- 用户信息处理：`src/core/controllers/oidc.go`

3. **用户管理**:
- 首次登录时需要在 Harbor 中设置用户名
- 用户信息会从 Keycloak 同步到 Harbor
- 可以通过 OIDC 组来管理用户权限
- 支持自动创建用户(Auto Onboarding)

相关源码：
- 用户管理：`src/core/auth/oidc/oidc.go`
- 用户信息同步：`src/pkg/oidc/secret.go`

#### OpenLDAP 认证流程

1. **配置阶段**:
- 在 Harbor 中配置 LDAP 认证模式,需要设置:
  - LDAP URL: LDAP 服务器地址
  - Search DN: 搜索用户的基础 DN
  - Search Password: 搜索密码
  - Base DN: 基础 DN
  - Filter: 用户过滤条件
  - UID: 用户标识字段
  - Group Base DN: 组搜索基础 DN
  - Group Filter: 组过滤条件
  - Group GID: 组标识字段
  - Group Admin DN: 管理员组 DN

相关源码：
- 配置定义：`src/lib/config/userconfig.go`
- 配置界面：`src/portal/src/i18n/lang/zh-cn-lang.json` 中的 LDAP 相关配置项

2. **登录流程**:
- 用户使用 LDAP 用户名和密码登录 Harbor
- Harbor 通过 LDAP 协议连接 LDAP 服务器
- 验证用户凭证
- 获取用户信息和组成员关系
- 在 Harbor 中创建或更新用户记录
- 根据组成员关系设置用户权限

相关源码：
- LDAP 认证：`src/core/auth/ldap/ldap.go` 中的 `Authenticate` 函数
- LDAP 连接：`src/pkg/ldap/ldap.go` 中的 `Session` 结构体
- 用户搜索：`src/core/auth/ldap/ldap.go` 中的 `SearchUser` 函数

3. **用户管理**:
- 用户信息存储在 LDAP 服务器中
- 可以通过 LDAP 组来管理用户权限
- 支持设置 LDAP 管理员组
- 用户密码修改需要在 LDAP 服务器中进行

相关源码：
- 组管理：`src/core/auth/ldap/ldap.go` 中的 `SearchGroup` 和 `OnBoardGroup` 函数
- LDAP 控制器：`src/controller/ldap/controller.go`

#### 主要区别

1. **认证方式**:
- Keycloak: 基于 OAuth2/OIDC 协议,支持多种认证方式
- OpenLDAP: 基于 LDAP 协议,主要使用用户名密码认证

相关源码：
- 认证接口定义：`src/core/auth/authenticator.go`
- OIDC 实现：`src/core/auth/oidc/oidc.go`
- LDAP 实现：`src/core/auth/ldap/ldap.go`

2. **用户管理**:
- Keycloak: 用户信息存储在 Keycloak 中,支持多种身份源
- OpenLDAP: 用户信息存储在 LDAP 服务器中

相关源码：
- 用户管理接口：`src/pkg/user/manager.go`
- OIDC 用户管理：`src/pkg/oidc/secret.go`
- LDAP 用户管理：`src/pkg/ldap/manager.go`

3. **权限管理**:
- Keycloak: 通过 OIDC 组和角色管理权限
- OpenLDAP: 通过 LDAP 组管理权限

相关源码：
- 权限管理：`src/common/rbac/`
- OIDC 组管理：`src/core/auth/oidc/oidc.go`
- LDAP 组管理：`src/core/auth/ldap/ldap.go`

4. **集成复杂度**:
- Keycloak: 配置相对复杂,但功能更强大
- OpenLDAP: 配置相对简单,适合简单的用户管理需求

相关源码：
- 配置管理：`src/lib/config/`
- OIDC 配置：`src/pkg/oidc/helper.go`
- LDAP 配置：`src/pkg/ldap/ldap.go`

5. **安全性**:
- Keycloak: 支持多种安全特性,如 MFA、SSO 等
- OpenLDAP: 主要依赖 LDAP 服务器的安全机制

相关源码：
- 安全中间件：`src/server/middleware/security/`
- OIDC 安全：`src/server/middleware/security/idtoken.go`
- LDAP 安全：`src/pkg/ldap/ldap.go`

这两种认证方式都可以很好地集成到 Harbor 中,选择哪种方式主要取决于您的具体需求和现有基础设施。 

### Harbor 从 Keycloak 获取用户 ID 的流程

Harbor 通过 OIDC 协议从 Keycloak 获取用户 ID 的主要流程如下：

1. **配置阶段**:
- 在 Harbor 的 OIDC 配置中，通过 `UserClaim` 字段指定从 Keycloak 返回的 token 中获取用户 ID 的字段名
- 相关配置代码在 `src/lib/config/userconfig.go` 中：
```go
func OIDCSetting(ctx context.Context) (*cfgModels.OIDCSetting, error) {
    // ...
    return &cfgModels.OIDCSetting{
        // ...
        UserClaim: mgr.Get(ctx, common.OIDCUserClaim).GetString(),
        // ...
    }
}
```

2. **登录流程**:
- 用户通过 OIDC 登录时，Harbor 会从 Keycloak 获取 ID Token
- 根据配置的 `UserClaim` 从 token 中提取用户信息
- 相关代码在 `src/pkg/oidc/helper.go` 中：
```go
func userInfoFromClaims(c claimsProvider, setting cfgModels.OIDCSetting) (*UserInfo, error) {
    res := &UserInfo{}
    if err := c.Claims(res); err != nil {
        return nil, err
    }
    if setting.UserClaim != "" {
        allClaims := make(map[string]any)
        if err := c.Claims(&allClaims); err != nil {
            return nil, err
        }

        if username, ok := allClaims[setting.UserClaim].(string); ok {
            res.autoOnboardUsername, res.Username = username, username
        }
    }
    // ...
}
```

3. **数据存储**:
- 从 Keycloak 获取的用户信息会被存储在 Harbor 的数据库中
- 相关表结构在 `src/common/models/oidc_user.go` 中定义：
```go
type OIDCUser struct {
    ID     int64 `orm:"pk;auto;column(id)" json:"id"`
    UserID int   `orm:"column(user_id)" json:"user_id"`
    // ...
    SubIss string `orm:"column(subiss)" json:"subiss"`
    // ...
}
```

4. **配置界面**:
- 用户可以通过 Harbor 的 Web 界面配置 OIDC 设置
- 相关配置项在 `src/portal/src/i18n/lang/zh-cn-lang.json` 中：
```json
"OIDC": {
    "USER_CLAIM": "用户名声明",
    // ...
}
```

这个流程确保了 Harbor 可以正确地从 Keycloak 获取用户 ID，并将其用于用户认证和授权。通过配置 `UserClaim`，Harbor 可以灵活地从 Keycloak 的 token 中提取所需的用户标识信息。 

### Harbor 配置 Keycloak OIDC 的详细步骤

1. **Keycloak 服务器配置**:
   - 登录 Keycloak 管理控制台
   - 创建新的 Realm（领域）
   - 在 Realm 设置中配置：
     - 启用 "OpenID Connect" 协议
     - 设置 "Access Type" 为 "confidential"
     - 配置 "Valid Redirect URIs" 为 Harbor 的回调地址（例如：`https://harbor.example.com/c/oidc/callback`）
     - 保存客户端配置，记录生成的 Client ID 和 Client Secret

2. **Harbor 配置 OIDC**:
   - 登录 Harbor 管理界面
   - 进入"系统管理" -> "配置管理" -> "认证"
   - 选择认证模式为 "OIDC"
   - 填写 OIDC 配置信息：
     ```
     OIDC Provider Name: Keycloak
     OIDC Endpoint: https://keycloak.example.com/realms/your-realm
     OIDC Client ID: [从 Keycloak 获取的 Client ID]
     OIDC Client Secret: [从 Keycloak 获取的 Client Secret]
     OIDC Scope: openid,profile,email,groups
     Username Claim: preferred_username
     Group Claim Name: groups
     OIDC Admin Group: harbor-admin
     ```
   - 点击"测试连接"验证配置
   - 保存配置

3. **用户组配置**:
   - 在 Keycloak 中创建用户组
   - 将需要管理员权限的用户添加到 `harbor-admin` 组
   - 确保用户组信息包含在 token 中：
     - 在 Keycloak 的客户端设置中启用 "Full Scope Allowed"
     - 在 Mapper 配置中添加 groups 映射

4. **用户映射配置**:
   - 在 Harbor 的 OIDC 配置中设置用户名字段：
     - 如果使用 email 作为用户名：设置 `Username Claim` 为 `email`
     - 如果使用 preferred_username：设置 `Username Claim` 为 `preferred_username`
   - 配置自动创建用户：
     - 启用 "Automatic onboarding" 选项
     - 设置用户组过滤器（可选）

5. **验证配置**:
   - 退出 Harbor 当前登录
   - 点击 "OIDC 登录" 按钮
   - 使用 Keycloak 用户凭证登录
   - 验证以下功能：
     - 用户是否可以成功登录
     - 用户组权限是否正确
     - 管理员权限是否正确分配

6. **故障排查**:
   - 检查 Harbor 日志中的 OIDC 相关错误
   - 验证 Keycloak 的 token 内容：
     ```bash
     # 使用 jwt 工具解码 token
     jwt decode <your-token>
     ```
   - 确认以下配置正确：
     - Redirect URI 配置
     - Client ID 和 Secret
     - Scope 设置
     - 用户组映射

7. **安全建议**:
   - 使用 HTTPS 进行通信
   - 定期轮换 Client Secret
   - 限制 Keycloak 的访问范围
   - 配置适当的 token 过期时间
   - 启用 Keycloak 的审计日志

8. **维护和监控**:
   - 定期检查 Harbor 和 Keycloak 的日志
   - 监控用户登录状态
   - 定期验证 OIDC 配置的有效性
   - 备份 Keycloak 和 Harbor 的配置

这些步骤确保了 Harbor 和 Keycloak 的正确集成，提供了安全的身份认证和授权机制。根据实际环境，可能需要调整某些配置参数。 

### Harbor 项目成员管理机制

Harbor 的项目成员管理功能支持用户和用户组的管理，主要包含以下内容：

1. **数据模型**:
```go
type Member struct {
    ID         int    `orm:"pk;column(id)" json:"id"`
    ProjectID  int64  `orm:"column(project_id)" json:"project_id"`
    Entityname string `orm:"column(entity_name)" json:"entity_name"`
    Rolename   string `json:"role_name"`
    Role       int    `json:"role_id"`
    EntityID   int    `orm:"column(entity_id)" json:"entity_id"`
    EntityType string `orm:"column(entity_type)" json:"entity_type"`
}

type User struct {
    UserID   int    `json:"user_id"`
    Username string `json:"username"`
    Realname string `json:"realname"`
    Email    string `json:"email"`
    Role     int    `json:"role_id"`
    RoleName string `json:"role_name"`
}
```

2. **数据获取实现**:
```go
// src/pkg/member/dao/dao.go
func (d *dao) GetProjectMember(ctx context.Context, projectID int64, query *models.MemberQuery) ([]*models.Member, error) {
    // 构建 SQL 查询
    sql := `SELECT pm.id, pm.project_id, pm.entity_id, pm.role, pm.entity_type, 
            CASE 
                WHEN pm.entity_type='u' THEN u.username 
                WHEN pm.entity_type='g' THEN ug.group_name 
            END as entity_name,
            r.name as role_name
            FROM project_member pm
            LEFT JOIN harbor_user u ON pm.entity_id = u.user_id AND pm.entity_type = 'u'
            LEFT JOIN user_group ug ON pm.entity_id = ug.id AND pm.entity_type = 'g'
            LEFT JOIN role r ON pm.role = r.role_id
            WHERE pm.project_id = $1`
    
    // 添加查询条件
    if query.EntityName != "" {
        sql += ` AND (u.username LIKE $2 OR ug.group_name LIKE $2)`
    }
    if query.EntityType != "" {
        sql += ` AND pm.entity_type = $3`
    }
    
    // 执行查询
    rows, err := d.GetOrmer().Raw(sql, projectID, "%"+query.EntityName+"%", query.EntityType).QueryRows()
    // ... 处理查询结果
}
```

3. **前端实现**:
```html
<!-- src/portal/src/app/base/project/member/member.component.html -->
<clr-datagrid>
    <clr-dg-column>{{'MEMBER.NAME' | translate}}</clr-dg-column>
    <clr-dg-column>{{'MEMBER.TYPE' | translate}}</clr-dg-column>
    <clr-dg-column>{{'MEMBER.ROLE' | translate}}</clr-dg-column>
    <clr-dg-column>{{'MEMBER.ACTION' | translate}}</clr-dg-column>
    
    <clr-dg-row *clrDgItems="let m of members">
        <clr-dg-cell>{{m.entity_name}}</clr-dg-cell>
        <clr-dg-cell>{{m.entity_type === 'u' ? 'User' : 'Group'}}</clr-dg-cell>
        <clr-dg-cell>
            <select [(ngModel)]="m.role" (change)="changeRole(m)">
                <option *ngFor="let r of roles" [value]="r.role_id">
                    {{r.name}}
                </option>
            </select>
        </clr-dg-cell>
        <clr-dg-cell>
            <button class="btn btn-sm btn-danger" (click)="deleteMember(m)">
                {{'BUTTON.DELETE' | translate}}
            </button>
        </clr-dg-cell>
    </clr-dg-row>
</clr-datagrid>
```

4. **权限控制实现**:
```go
// src/core/filter/security.go
func RequireProjectAdmin() func(ctx *beego.Context) {
    return func(ctx *beego.Context) {
        projectID := ctx.Input.Param(":id")
        userID := ctx.Input.GetData("userId")
        
        // 检查用户权限
        if !hasProjectAdminRole(userID, projectID) {
            ctx.Output.SetStatus(http.StatusForbidden)
            return
        }
    }
}

// src/pkg/project/manager.go
func (p *DefaultProjectManager) GetProjectMember(ctx context.Context, projectID int64, query *models.MemberQuery) ([]*models.Member, error) {
    // 检查用户权限
    if !p.HasProjectAdminRole(ctx, projectID) {
        return nil, errors.New("unauthorized")
    }
    
    // 获取成员列表
    return p.dao.GetProjectMember(ctx, projectID, query)
}
```

5. **API 接口定义**:
```go
// src/core/api/project.go
func (p *ProjectAPI) GetProjectMembers(ctx *beego.Context) {
    projectID := ctx.Input.Param(":id")
    query := &models.MemberQuery{
        EntityName: ctx.Input.Query("entity_name"),
        EntityType: ctx.Input.Query("entity_type"),
    }
    
    members, err := p.ProjectMgr.GetProjectMember(ctx, projectID, query)
    if err != nil {
        ctx.Output.SetStatus(http.StatusInternalServerError)
        return
    }
    
    ctx.Output.JSON(members, false, false)
}
```

6. **数据库表结构**:
```sql
-- project_member 表
CREATE TABLE project_member (
    id SERIAL PRIMARY KEY,
    project_id INTEGER NOT NULL,
    entity_id INTEGER NOT NULL,
    entity_type VARCHAR(1) NOT NULL,
    role INTEGER NOT NULL,
    creation_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES project(project_id),
    FOREIGN KEY (role) REFERENCES role(role_id)
);

-- role 表
CREATE TABLE role (
    role_id SERIAL PRIMARY KEY,
    name VARCHAR(20) NOT NULL,
    creation_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

7. **错误处理**:
```go
// src/pkg/member/dao/dao.go
func (d *dao) AddProjectMember(ctx context.Context, member *models.Member) error {
    // 检查成员是否已存在
    if d.isMemberExist(ctx, member.ProjectID, member.EntityID, member.EntityType) {
        return errors.New("member already exists")
    }
    
    // 检查角色是否有效
    if !d.isValidRole(ctx, member.Role) {
        return errors.New("invalid role")
    }
    
    // 添加成员
    _, err := d.GetOrmer().Insert(member)
    return err
}
```

8. **缓存处理**:
```go
// src/pkg/member/cache/cache.go
func (c *Cache) GetProjectMembers(projectID int64) ([]*models.Member, error) {
    // 尝试从缓存获取
    if members, ok := c.cache.Get(fmt.Sprintf("project_members_%d", projectID)); ok {
        return members.([]*models.Member), nil
    }
    
    // 从数据库获取
    members, err := c.dao.GetProjectMember(context.Background(), projectID, nil)
    if err != nil {
        return nil, err
    }
    
    // 更新缓存
    c.cache.Set(fmt.Sprintf("project_members_%d", projectID), members, time.Hour)
    return members, nil
}
```

这些代码展示了 Harbor 项目成员管理功能的核心实现，包括：
- 数据模型定义和数据库结构
- 数据访问层实现
- 前端界面实现
- 权限控制机制
- API 接口定义
- 错误处理机制
- 缓存处理策略

通过这些代码，可以清楚地了解 Harbor 项目成员管理功能的实现细节和架构设计。 

### Harbor 项目权限控制实现

Harbor 通过多层次的权限控制机制来管理用户对项目的访问权限。以下是详细的实现说明：

1. **权限模型定义**:
```go
// src/common/rbac/types.go
type Policy struct {
    ID          int64  `json:"id"`
    ProjectID   int64  `json:"project_id"`
    Role        int    `json:"role"`
    EntityType  string `json:"entity_type"`
    EntityID    int    `json:"entity_id"`
    EntityName  string `json:"entity_name"`
    CreationTime time.Time `json:"creation_time"`
    UpdateTime   time.Time `json:"update_time"`
}

// 角色定义
const (
    RoleProjectAdmin = 1
    RoleDeveloper   = 2
    RoleGuest       = 3
    RoleMaintainer  = 4
)
```

2. **权限检查实现**:
```go
// src/pkg/project/manager.go
func (p *DefaultProjectManager) HasProjectPermission(ctx context.Context, projectID int64, userID int, action string) bool {
    // 获取用户角色
    role, err := p.GetUserProjectRole(ctx, projectID, userID)
    if err != nil {
        return false
    }
    
    // 检查权限
    switch action {
    case "push":
        return role == RoleProjectAdmin || role == RoleDeveloper || role == RoleMaintainer
    case "pull":
        return true // 所有角色都可以拉取
    case "delete":
        return role == RoleProjectAdmin
    case "create":
        return role == RoleProjectAdmin
    default:
        return false
    }
}

// 获取用户在项目中的角色
func (p *DefaultProjectManager) GetUserProjectRole(ctx context.Context, projectID int64, userID int) (int, error) {
    // 检查直接项目成员身份
    role, err := p.dao.GetUserProjectRole(ctx, projectID, userID)
    if err == nil && role > 0 {
        return role, nil
    }
    
    // 检查用户组身份
    return p.dao.GetUserGroupProjectRole(ctx, projectID, userID)
}
```

3. **权限验证中间件**:
```go
// src/server/middleware/security/project.go
func RequireProjectPermission(action string) func(ctx *beego.Context) {
    return func(ctx *beego.Context) {
        projectID := ctx.Input.Param(":id")
        userID := ctx.Input.GetData("userId")
        
        // 检查用户权限
        if !hasProjectPermission(userID, projectID, action) {
            ctx.Output.SetStatus(http.StatusForbidden)
            return
        }
    }
}

func hasProjectPermission(userID int, projectID int64, action string) bool {
    // 获取项目管理器实例
    projectMgr := project.GetDefaultProjectManager()
    
    // 检查权限
    return projectMgr.HasProjectPermission(context.Background(), projectID, userID, action)
}
```

4. **权限缓存实现**:
```go
// src/pkg/project/cache/cache.go
type ProjectCache struct {
    cache *cache.Cache
}

func (c *ProjectCache) GetUserProjectRole(userID int, projectID int64) (int, error) {
    // 尝试从缓存获取
    cacheKey := fmt.Sprintf("user_project_role_%d_%d", userID, projectID)
    if role, ok := c.cache.Get(cacheKey); ok {
        return role.(int), nil
    }
    
    // 从数据库获取
    role, err := c.dao.GetUserProjectRole(context.Background(), projectID, userID)
    if err != nil {
        return 0, err
    }
    
    // 更新缓存
    c.cache.Set(cacheKey, role, time.Hour)
    return role, nil
}
```

5. **API 权限控制**:
```go
// src/core/api/project.go
func (p *ProjectAPI) PushImage(ctx *beego.Context) {
    projectID := ctx.Input.Param(":id")
    userID := ctx.Input.GetData("userId")
    
    // 检查推送权限
    if !p.ProjectMgr.HasProjectPermission(ctx, projectID, userID, "push") {
        ctx.Output.SetStatus(http.StatusForbidden)
        return
    }
    
    // 处理镜像推送
    // ...
}

func (p *ProjectAPI) PullImage(ctx *beego.Context) {
    projectID := ctx.Input.Param(":id")
    userID := ctx.Input.GetData("userId")
    
    // 检查拉取权限
    if !p.ProjectMgr.HasProjectPermission(ctx, projectID, userID, "pull") {
        ctx.Output.SetStatus(http.StatusForbidden)
        return
    }
    
    // 处理镜像拉取
    // ...
}
```

6. **权限管理接口**:
```go
// src/core/api/project.go
func (p *ProjectAPI) UpdateProjectMember(ctx *beego.Context) {
    projectID := ctx.Input.Param(":id")
    userID := ctx.Input.GetData("userId")
    
    // 只有项目管理员可以修改成员权限
    if !p.ProjectMgr.HasProjectPermission(ctx, projectID, userID, "admin") {
        ctx.Output.SetStatus(http.StatusForbidden)
        return
    }
    
    // 解析请求数据
    var member models.Member
    if err := ctx.Input.JSON(&member); err != nil {
        ctx.Output.SetStatus(http.StatusBadRequest)
        return
    }
    
    // 更新成员权限
    if err := p.ProjectMgr.UpdateProjectMember(ctx, projectID, &member); err != nil {
        ctx.Output.SetStatus(http.StatusInternalServerError)
        return
    }
    
    ctx.Output.SetStatus(http.StatusOK)
}
```

7. **权限检查工具函数**:
```go
// src/pkg/project/utils.go
func CheckProjectPermission(ctx context.Context, projectID int64, userID int, action string) error {
    projectMgr := project.GetDefaultProjectManager()
    
    // 检查用户是否存在
    if !userMgr.UserExists(ctx, userID) {
        return errors.New("user not found")
    }
    
    // 检查项目是否存在
    if !projectMgr.ProjectExists(ctx, projectID) {
        return errors.New("project not found")
    }
    
    // 检查权限
    if !projectMgr.HasProjectPermission(ctx, projectID, userID, action) {
        return errors.New("permission denied")
    }
    
    return nil
}
```

8. **权限变更审计**:
```go
// src/pkg/project/audit.go
func (a *ProjectAudit) LogPermissionChange(ctx context.Context, projectID int64, userID int, action string, targetUserID int, oldRole int, newRole int) error {
    auditLog := &models.AuditLog{
        ProjectID:    projectID,
        UserID:       userID,
        Action:       action,
        TargetUserID: targetUserID,
        OldRole:      oldRole,
        NewRole:      newRole,
        CreateTime:   time.Now(),
    }
    
    return a.dao.CreateAuditLog(ctx, auditLog)
}
```

这些代码展示了 Harbor 项目权限控制的核心实现，包括：
- 权限模型定义
- 权限检查机制
- 权限验证中间件
- 权限缓存处理
- API 权限控制
- 权限管理接口
- 权限检查工具
- 权限变更审计

通过这些实现，Harbor 提供了细粒度的项目权限控制，确保用户只能执行其权限范围内的操作。权限控制贯穿于整个系统，从 API 接口到具体的业务操作，都有相应的权限检查机制。 

### Harbor Registry 数据库表结构说明

Harbor Registry 使用 PostgreSQL 数据库存储数据，以下是主要表的结构说明：

1. **用户相关表**:
```sql
-- harbor_user 表：存储用户基本信息
CREATE TABLE harbor_user (
    user_id SERIAL PRIMARY KEY,           -- 用户ID，自增主键
    username VARCHAR(255) NOT NULL,       -- 用户名
    email VARCHAR(255),                   -- 邮箱
    password VARCHAR(40),                 -- 密码（加密存储）
    realname VARCHAR(255),               -- 真实姓名
    comment VARCHAR(255),                -- 备注
    deleted BOOLEAN DEFAULT FALSE,       -- 是否删除
    reset_uuid VARCHAR(40),              -- 重置密码UUID
    salt VARCHAR(40),                    -- 密码盐值
    sysadmin_flag BOOLEAN DEFAULT FALSE, -- 是否系统管理员
    creation_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- 创建时间
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,    -- 更新时间
    UNIQUE (username)
);

-- user_group 表：存储用户组信息
CREATE TABLE user_group (
    id SERIAL PRIMARY KEY,               -- 用户组ID
    group_name VARCHAR(255) NOT NULL,    -- 用户组名称
    group_type INTEGER DEFAULT 0,        -- 用户组类型
    ldap_group_dn VARCHAR(512),          -- LDAP组DN
    creation_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- 创建时间
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,    -- 更新时间
    UNIQUE (group_name)
);
```

2. **项目相关表**:
```sql
-- project 表：存储项目信息
CREATE TABLE project (
    project_id SERIAL PRIMARY KEY,       -- 项目ID
    name VARCHAR(255) NOT NULL,          -- 项目名称
    owner_id INTEGER NOT NULL,           -- 所有者ID
    creation_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- 创建时间
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,    -- 更新时间
    deleted BOOLEAN DEFAULT FALSE,       -- 是否删除
    owner_name VARCHAR(255),             -- 所有者名称
    UNIQUE (name)
);

-- project_member 表：存储项目成员信息
CREATE TABLE project_member (
    id SERIAL PRIMARY KEY,               -- 成员ID
    project_id INTEGER NOT NULL,         -- 项目ID
    entity_id INTEGER NOT NULL,          -- 实体ID（用户ID或组ID）
    entity_type VARCHAR(1) NOT NULL,     -- 实体类型（u:用户, g:组）
    role INTEGER NOT NULL,               -- 角色ID
    creation_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- 创建时间
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,    -- 更新时间
    FOREIGN KEY (project_id) REFERENCES project(project_id),
    FOREIGN KEY (role) REFERENCES role(role_id)
);
```

3. **镜像相关表**:
```sql
-- repository 表：存储镜像仓库信息
CREATE TABLE repository (
    repository_id SERIAL PRIMARY KEY,    -- 仓库ID
    name VARCHAR(255) NOT NULL,          -- 仓库名称
    project_id INTEGER NOT NULL,         -- 所属项目ID
    description TEXT,                    -- 描述
    pull_count INTEGER DEFAULT 0,        -- 拉取次数
    star_count INTEGER DEFAULT 0,        -- 星标数
    creation_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- 创建时间
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,    -- 更新时间
    FOREIGN KEY (project_id) REFERENCES project(project_id)
);

-- artifact 表：存储镜像标签信息
CREATE TABLE artifact (
    id SERIAL PRIMARY KEY,               -- 标签ID
    repository_id INTEGER NOT NULL,      -- 仓库ID
    digest VARCHAR(255) NOT NULL,        -- 镜像摘要
    tag VARCHAR(255) NOT NULL,           -- 标签名
    size BIGINT NOT NULL,                -- 大小
    creation_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- 创建时间
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,    -- 更新时间
    FOREIGN KEY (repository_id) REFERENCES repository(repository_id)
);
```

4. **权限相关表**:
```sql
-- role 表：存储角色信息
CREATE TABLE role (
    role_id SERIAL PRIMARY KEY,          -- 角色ID
    name VARCHAR(20) NOT NULL,           -- 角色名称
    creation_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- 创建时间
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP     -- 更新时间
);

-- policy 表：存储权限策略
CREATE TABLE policy (
    id SERIAL PRIMARY KEY,               -- 策略ID
    project_id INTEGER NOT NULL,         -- 项目ID
    role INTEGER NOT NULL,               -- 角色ID
    entity_type VARCHAR(1) NOT NULL,     -- 实体类型
    entity_id INTEGER NOT NULL,          -- 实体ID
    entity_name VARCHAR(255) NOT NULL,   -- 实体名称
    creation_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- 创建时间
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,    -- 更新时间
    FOREIGN KEY (project_id) REFERENCES project(project_id),
    FOREIGN KEY (role) REFERENCES role(role_id)
);
```

5. **审计相关表**:
```sql
-- audit_log 表：存储审计日志
CREATE TABLE audit_log (
    id SERIAL PRIMARY KEY,               -- 日志ID
    project_id INTEGER,                  -- 项目ID
    user_id INTEGER,                     -- 用户ID
    action VARCHAR(255) NOT NULL,        -- 操作类型
    target_user_id INTEGER,              -- 目标用户ID
    old_role INTEGER,                    -- 旧角色
    new_role INTEGER,                    -- 新角色
    create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,    -- 创建时间
    FOREIGN KEY (project_id) REFERENCES project(project_id)
);
```

6. **配置相关表**:
```sql
-- properties 表：存储系统配置
CREATE TABLE properties (
    id SERIAL PRIMARY KEY,               -- 配置ID
    k VARCHAR(64) NOT NULL,              -- 配置键
    v VARCHAR(128) NOT NULL,             -- 配置值
    UNIQUE (k)
);
```

7. **扫描相关表**:
```sql
-- scan_report 表：存储扫描报告
CREATE TABLE scan_report (
    id SERIAL PRIMARY KEY,               -- 报告ID
    artifact_id INTEGER NOT NULL,        -- 镜像ID
    report JSONB NOT NULL,               -- 扫描报告内容
    creation_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- 创建时间
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,    -- 更新时间
    FOREIGN KEY (artifact_id) REFERENCES artifact(id)
);
```

8. **标签相关表**:
```sql
-- tag 表：存储标签信息
CREATE TABLE tag (
    id SERIAL PRIMARY KEY,               -- 标签ID
    repository_id INTEGER NOT NULL,      -- 仓库ID
    name VARCHAR(255) NOT NULL,          -- 标签名
    push_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,      -- 推送时间
    pull_time TIMESTAMP,                 -- 拉取时间
    FOREIGN KEY (repository_id) REFERENCES repository(repository_id)
);
```

主要表关系说明：
1. 用户-项目关系：通过 `project_member` 表关联
2. 项目-仓库关系：通过 `repository` 表的 `project_id` 关联
3. 仓库-镜像关系：通过 `artifact` 表的 `repository_id` 关联
4. 权限-角色关系：通过 `policy` 表的 `role` 关联
5. 用户组-用户关系：通过 `user_group` 表管理

索引说明：
1. 用户表：`username` 唯一索引
2. 项目表：`name` 唯一索引
3. 仓库表：`name` 和 `project_id` 联合索引
4. 镜像表：`digest` 和 `repository_id` 联合索引
5. 标签表：`name` 和 `repository_id` 联合索引

这些表结构支持 Harbor 的核心功能，包括：
- 用户认证和授权
- 项目管理
- 镜像存储和管理
- 权限控制
- 审计日志
- 系统配置
- 安全扫描
