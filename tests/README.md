# tests/

此目录用于验证 `gitleaks.toml` 的 **路径白名单**（`tests/` 下内容不触发告警）。

请勿在此放入形似真实密钥的字符串（如 `xoxb-` Slack Token），否则 **GitHub Push Protection** 会拒绝推送。
