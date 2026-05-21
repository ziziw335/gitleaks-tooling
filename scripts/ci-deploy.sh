#!/usr/bin/env bash
# 在服务器上执行：写 .env → git pull → docker compose 上线
set -euo pipefail

APP_DIR="${DEPLOY_PATH:-/opt/gitleaks-tooling}"
cd "${APP_DIR}"

echo ">>> [1/4] 写入 .env"
bash scripts/ci-write-env.sh .env

echo ">>> [2/4] 更新代码"
if [[ ! -d .git ]]; then
  echo "ERROR: ${APP_DIR} 不是 git 仓库，请先 clone 或检查 DEPLOY_PATH"
  exit 1
fi

BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)"
if [[ -n "${GIT_DEPLOY_TOKEN:-}" ]]; then
  ORIGIN="$(git remote get-url origin)"
  case "${ORIGIN}" in
    https://github.com/*)
      AUTH_ORIGIN="https://x-access-token:${GIT_DEPLOY_TOKEN}@${ORIGIN#https://}"
      git pull --ff-only "${AUTH_ORIGIN}" "${BRANCH}"
      ;;
    *)
      git fetch origin
      git pull --ff-only origin "${BRANCH}" \
        || git pull --ff-only origin main \
        || git pull --ff-only origin master
      ;;
  esac
else
  git fetch origin
  git pull --ff-only origin "${BRANCH}" \
    || git pull --ff-only origin main \
    || git pull --ff-only origin master
fi

echo ">>> [3/4] Docker Compose 构建并启动"
if docker compose version >/dev/null 2>&1; then
  DC="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  DC="docker-compose"
else
  echo "ERROR: 未安装 docker compose"
  exit 1
fi

${DC} up -d --build --remove-orphans

echo ">>> [4/4] 服务状态"
${DC} ps

echo "Deploy OK at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
