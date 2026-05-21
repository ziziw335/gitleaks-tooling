#!/usr/bin/env bash
# 在 GitHub 已创建空仓库 gitleaks-tooling 后执行（仅推送，触发 Actions）
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

GITHUB_REPO="${GITHUB_REPO:-git@github.com:ziziw335/gitleaks-tooling.git}"
SSH_KEY="${SSH_KEY:-${HOME}/.ssh/id_ed25519_github}"

if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "${GITHUB_REPO}"
else
  git remote add origin "${GITHUB_REPO}"
fi

export GIT_SSH_COMMAND="ssh -i ${SSH_KEY} -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"
git push -u origin main

echo "✅ 已推送。查看 Actions: https://github.com/ziziw335/gitleaks-tooling/actions"
