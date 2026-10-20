---
module: auth
status: living
code_paths:
  - src/modules/auth/
contract_entry: src/modules/auth/index.ts
last_updated: 2026-10-19
---

# 模块活态架构说明书：认证与权限 (Auth Module)

> 本文件代表 `auth` 模块**此时此刻的最新生产状态**。修改 `src/modules/auth/**` 前必读。

## 1. 模块职责与边界
- 负责用户登录、JWT 签发与刷新、RBAC 权限校验。
- **不负责**：用户基础资料修改（归属 `user` 模块）。

## 2. 对外暴露的公共契约 (Public Contracts)
其它模块仅允许调用 `src/modules/auth/index.ts` 中的以下方法：
- `verifyToken(token: string): Promise<AuthPayload>`
- `checkPermission(userId: string, resource: string, action: string): Promise<boolean>`

## 3. 核心数据表结构摘要
- `users_auth`: 存储密码哈希、盐值、MFA 密钥、最后登录时间。

## 4. 本模块专属红线 (Module-Specific Guardrails)
1. 任何密码与密钥比对必须使用恒定时间比较函数（`crypto.timingSafeEqual`），防止时序攻击。
2. 严禁在任何日志中打印明文 Token 或 `totp_secret`。
3. 修改本模块任何文件后，必须运行：`bash scripts/ai-verify.sh <修改的文件路径>`。
