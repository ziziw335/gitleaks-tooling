#!/usr/bin/env bash
# 扫描任意项目目录（不修改对方仓库的 pre-commit / CI）
# 用法: bash scripts/scan-repo.sh /path/to/PyCharmMiscProject
set -euo pipefail

TOOL_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${1:-}"

if [[ -z "${TARGET}" ]]; then
  echo "用法: bash scripts/scan-repo.sh <项目目录>"
  echo "示例: bash scripts/scan-repo.sh /Users/xiaoyang/PyCharmMiscProject"
  exit 1
fi

if [[ ! -d "${TARGET}" ]]; then
  echo "ERROR: 目录不存在: ${TARGET}"
  exit 1
fi

TARGET="$(cd "${TARGET}" && pwd)"
cd "${TOOL_ROOT}"

if [[ ! -x bin/gitleaks ]]; then
  bash scripts/setup-gitleaks.sh
fi

echo ">>> Gitleaks 扫描: ${TARGET}"
echo ">>> 配置: ${TOOL_ROOT}/gitleaks.toml"
bin/gitleaks detect \
  --source "${TARGET}" \
  --config gitleaks.toml \
  --no-git \
  --verbose \
  --redact

echo "✅ 扫描完成（未修改目标仓库）"
