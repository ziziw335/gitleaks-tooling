# Gitleaks Tooling

独立的 **Gitleaks + pre-commit + GitHub Actions** 项目，与业务代码仓库解耦。

## 三条能力

| # | 内容 | 文件 |
|---|------|------|
| 1 | 提交前扫描 | `.pre-commit-config.yaml` → `scripts/run-gitleaks.sh` |
| 2 | Push / PR 自动扫描（泄密即失败） | `.github/workflows/gitleaks.yml` |
| 3 | 测试目录误报过滤 | `gitleaks.toml` → `[allowlist]` |

`run-gitleaks.sh` 固定使用本仓库根目录的 **`gitleaks.toml`**，与 pre-commit 自动关联。

## 一键跑通（Mac 终端执行）

```bash
cd /Users/xiaoyang/gitleaks-tooling
bash scripts/activate-all.sh
```

会完成：安装 `bin/gitleaks`、安装钩子、本地扫描、提交、推送到 GitHub 并触发 Actions。

若 GitHub 上尚无仓库，先在网页创建空仓库 `gitleaks-tooling`，再执行上述命令。

查看 CI：https://github.com/ziziw335/gitleaks-tooling/actions

## 分步命令

```bash
cd /Users/xiaoyang/gitleaks-tooling
bash scripts/setup-gitleaks.sh
pre-commit install          # 或 activate-all 会写等效 .git/hooks/pre-commit
pre-commit run gitleaks --all-files
```

手动全量扫描：

```bash
./bin/gitleaks detect --source . --config gitleaks.toml --no-git --verbose --redact
```

## 扫描其它目录（可选）

```bash
bash scripts/scan-repo.sh /path/to/your-project
```

不修改目标项目的钩子或 CI。

## 文件说明

| 文件 | 作用 |
|------|------|
| `gitleaks.toml` | 规则与白名单 |
| `.pre-commit-config.yaml` | pre-commit 钩子定义 |
| `scripts/setup-gitleaks.sh` | 下载二进制并自检 |
| `scripts/run-gitleaks.sh` | 钩子入口（读 `gitleaks.toml`） |
| `scripts/activate-all.sh` | 本地 + 推送一键跑通 |
| `scripts/scan-repo.sh` | 扫描任意目录 |

---

## 团队代码安全规范

本仓库已接入 **Gitleaks**（本地 pre-commit + GitHub Actions）。任何包含真实密钥的提交会被拦截，请全员遵守以下约定。

### 1. 原则

| 可以做 | 禁止做 |
|--------|--------|
| 把密钥写在 **`.env`**（仅本机，勿提交） | 在 `.py` / `.md` / 配置里 **硬编码** 密码、Token、API Key |
| 在业务项目提交 **`.env.example`**（仅占位符） | 把 **`.env`** 提交到 Git |
| 误报测试数据放在 `tests/` 等目录 | 为通过扫描把真实密钥写进 allowlist |
| 在 `tests/` 放普通占位说明 | 在 `tests/` 放形似真密钥的字符串（如 `xoxb-` Slack Token，会触发 **GitHub Push Protection**） |

### 2. 首次环境准备（每位同事执行一次）

在本仓库根目录打开 **Mac 终端**：

```bash
cd /Users/xiaoyang/gitleaks-tooling

# 安装 pre-commit（任选其一）
pip install pre-commit
# 或: brew install pre-commit

# 下载 gitleaks 二进制并做首次全量扫描
bash scripts/setup-gitleaks.sh

# 激活提交前钩子（每次 commit 前自动跑 Gitleaks，读取 gitleaks.toml）
pre-commit install

# 可选：全量自检
pre-commit run gitleaks --all-files
```

钩子定义见 [.pre-commit-config.yaml](.pre-commit-config.yaml)，实际执行 [scripts/run-gitleaks.sh](scripts/run-gitleaks.sh)。

### 3. 日常开发流程

1. 在**业务项目**中：`cp .env.example .env`，在 **`.env`** 填写真实配置（业务项目的 `.env` 与本工具仓库无关）。
2. 在本仓库正常改配置/脚本 → `git add` → `git commit`。
3. 若 pre-commit 的 **gitleaks** 报错，说明暂存区疑似含密钥，**不要**用 `--no-verify` 跳过（除非维护者明确允许的一次性历史修复脚本）。

手动扫描（不提交也可跑）：

```bash
./bin/gitleaks detect --source . --config gitleaks.toml --no-git --verbose --redact
# 或
pre-commit run gitleaks --all-files
```

扫描**其它业务目录**（不安装对方仓库钩子）：

```bash
bash scripts/scan-repo.sh /path/to/your-project
```

### 4. 被 Gitleaks 拦截时怎么办

1. **看终端输出**：会标明文件路径、行号与规则类型（如 `generic-api-key`）。
2. **从代码中删除明文密钥**，改为从环境变量读取，例如：

   ```python
   import os
   from dotenv import load_dotenv

   load_dotenv()
   api_token = os.getenv("API_TOKEN", "").strip()
   if not api_token:
       raise RuntimeError("API_TOKEN is missing — set it in .env")
   ```

3. **把真实值只写入业务项目的 `.env`**（该文件应在业务项目的 `.gitignore` 中，不会进仓库）：

   ```bash
   # .env（勿提交）
   API_TOKEN=你的真实令牌
   DATABASE_PASSWORD=你的数据库密码
   ```

4. 若仓库需要文档说明变量名，只更新业务项目的 **`.env.example`**，值留空或写占位符：

   ```bash
   # .env.example（可提交）
   API_TOKEN=
   DATABASE_PASSWORD=
   ```

5. 再次 `git add` 并 `git commit`；确认 `git diff` 中 **没有** `.env` 文件。

6. **仅当**确认为测试假数据误报时，再在 [gitleaks.toml](gitleaks.toml) 的 `[allowlist]` 中按路径追加白名单，并经 Code Review；**禁止**把生产密钥加入白名单。

### 5. 本地应忽略的文件

业务项目请在各自 `.gitignore` 中保留：

- `.env` — 本地真实密钥
- `data/` — 本地数据库（若适用）
- `.venv/` — 虚拟环境

本工具仓库已忽略 `bin/gitleaks`（见 [.gitignore](.gitignore)）。

### 6. CI（GitHub Actions）

推送到本仓库或发起 Pull Request 时，[.github/workflows/gitleaks.yml](.github/workflows/gitleaks.yml) 会自动执行 Gitleaks（push 全量；PR 增量 + 全量）。发现泄露则 **CI 失败**，需修复后重新推送。

查看运行结果：https://github.com/ziziw335/gitleaks-tooling/actions

### 7. 联系人

对误报、白名单或扫描规则有疑问，请与仓库维护者沟通后再改 `gitleaks.toml`，避免为图省事关闭扫描。
