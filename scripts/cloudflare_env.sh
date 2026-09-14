# StaffDeck 公网穿透环境变量: source 后再执行 dev_up/dev_down
#   source scripts/cloudflare_env.sh
#   scripts/dev_up.sh --detach
# 说明: dev_supervisor 会用 CORS_ORIGINS 环境变量覆盖 backend/.env,
# 所以重启时必须带上公网域名,否则外网 https 会遇到 CORS 拦截。
export CORS_ORIGINS="http://localhost:5173,http://127.0.0.1:5173,http://0.0.0.0:5173,https://staffdeck.yaozheng.ccwu.cc"
export TOOL_BASE_URL="http://localhost:5173"
export EXTERNAL_TASK_CALLBACK_BASE_URL="https://staffdeck.yaozheng.ccwu.cc"
