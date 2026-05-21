#!/usr/bin/env bash
# 在 Mac「终端」执行一次，跑通三条：pre-commit + gitleaks.toml + 推送 GitHub Actions
# 仅用于 gitleaks-tooling，与记账机器人无关
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"
export PATH="${HOME}/Library/Python/3.14/bin:${HOME}/.local/bin:/opt/homebrew/bin:${PATH}"
GITHUB_REPO="${GITHUB_REPO:-git@github.com:ziziw335/gitleaks-tooling.git}"
SSH_KEY="${SSH_KEY:-${HOME}/.ssh/id_ed25519_github}"

echo ">>> 1/5 修复 Git 仓库（若曾用 gitdir 分离）"
if [[ -f .git ]] && grep -q '^gitdir:' .git 2>/dev/null; then
  OLD_GITDIR="$(sed 's/^gitdir: *//' .git | tr -d '[:space:]')"
  rm -f .git
  if [[ -d "${OLD_GITDIR}" ]]; then
    mv "${OLD_GITDIR}" .git
  else
    git init -b main
  fi
fi
if [[ ! -d .git ]]; then
  git init -b main
fi
git config user.email "${GIT_AUTHOR_EMAIL:-gitleaks-tooling@users.noreply.github.com}"
git config user.name "${GIT_AUTHOR_NAME:-gitleaks-tooling}"

echo ">>> 2/5 Gitleaks 二进制 + 全量扫描"
bash scripts/setup-gitleaks.sh

echo ">>> 3/5 安装提交前钩子（关联 gitleaks.toml）"
if command -v pre-commit >/dev/null 2>&1; then
  pre-commit install
  pre-commit run gitleaks --all-files
else
  echo "pre-commit 未安装，写入等效钩子 scripts/run-gitleaks.sh"
  install -m 755 scripts/run-gitleaks.sh "${ROOT}/scripts/run-gitleaks.sh"
  cat > .git/hooks/pre-commit <<'HOOK'
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
exec "${ROOT}/scripts/run-gitleaks.sh"
HOOK
  chmod +x .git/hooks/pre-commit
  bin/gitleaks detect --source . --config gitleaks.toml --no-git --redact
fi

echo ">>> 4/5 提交"
git add -A
if ! git diff --cached --quiet; then
  git commit -m "chore: gitleaks tooling setup"
fi

echo ">>> 5/5 推送到 GitHub（触发 Actions）"
if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "${GITHUB_REPO}"
else
  git remote add origin "${GITHUB_REPO}"
fi
export GIT_SSH_COMMAND="ssh -i ${SSH_KEY} -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"

if ! git push -u origin main 2>&1; then
  echo ""
  echo "❌ 推送失败。若提示 Repository not found："
  echo "   1. 浏览器打开 https://github.com/new"
  echo "   2. Repository name 填: gitleaks-tooling"
  echo "   3. 选 Private 或 Public，不要勾选 README（保持空仓库）"
  echo "   4. 创建后在本目录再执行:"
  echo "      bash scripts/push-github.sh"
  exit 1
fi

echo ""
echo "✅ 完成。查看 CI: https://github.com/ziziw335/gitleaks-tooling/actions"
