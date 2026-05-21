# GitHub Actions 部署 Secrets

仓库 → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

## 必填（SSH）

| Secret | 说明 |
|--------|------|
| `SSH_HOST` | 服务器 IP 或域名 |
| `SSH_USER` | SSH 用户名（如 `root`） |
| `SSH_PRIVATE_KEY` | 私钥全文（PEM，含 BEGIN/END 行） |

## 建议填写（写入服务器 `.env`）

| Secret | 说明 |
|--------|------|
| `DATABASE_PASSWORD` | 数据库密码 |
| `API_TOKEN` | API 令牌 |

## 可选

| Secret | 说明 |
|--------|------|
| `SSH_PORT` | 非 22 时填写 |
| `DEPLOY_PATH` | 默认 `/opt/gitleaks-tooling` |
| `GIT_DEPLOY_TOKEN` | 私有库 `git pull` 用 PAT |

## 服务器一次性准备

```bash
# 安装 Docker 与 Compose 插件
mkdir -p /opt/gitleaks-tooling
```

推送 `main` 后，在 **Actions** 查看 **Deploy to Production**。
