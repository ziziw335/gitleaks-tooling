#!/usr/bin/env bash
# 在服务器上由 CI 调用：根据已注入的环境变量生成 .env（不打印密钥）
set -euo pipefail

TARGET="${1:-.env}"
umask 077

write_kv() {
  local key="$1"
  local val="${!key:-}"
  if [[ -n "${val}" ]]; then
    printf '%s=%s\n' "${key}" "${val}"
  fi
}

{
  write_kv DATABASE_PASSWORD
  write_kv API_TOKEN
} > "${TARGET}.tmp"

mv "${TARGET}.tmp" "${TARGET}"
chmod 600 "${TARGET}"
echo "Wrote ${TARGET} ($(wc -l < "${TARGET}") keys, values hidden)"
