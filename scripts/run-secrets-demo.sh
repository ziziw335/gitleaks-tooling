#!/usr/bin/env bash
# 运行 secrets_demo.py（Mac 请用 python3，不要用已废弃的 python/pip 命令）
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo ">>> 已创建 .env，请编辑后填入 DATABASE_PASSWORD 和 API_TOKEN，再执行本脚本"
  exit 1
fi

python3 -m pip install -q -r requirements.txt
python3 secrets_demo.py
