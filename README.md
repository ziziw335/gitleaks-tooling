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

## 团队约定

| 可以做 | 禁止做 |
|--------|--------|
| 密钥写在目标项目的 `.env` | 代码里硬编码 Token |
| 误报数据放在 `tests/` | 把真实密钥写进 allowlist |

## 文件说明

| 文件 | 作用 |
|------|------|
| `gitleaks.toml` | 规则与白名单 |
| `.pre-commit-config.yaml` | pre-commit 钩子定义 |
| `scripts/setup-gitleaks.sh` | 下载二进制并自检 |
| `scripts/run-gitleaks.sh` | 钩子入口（读 `gitleaks.toml`） |
| `scripts/activate-all.sh` | 本地 + 推送一键跑通 |
| `scripts/scan-repo.sh` | 扫描任意目录 |
