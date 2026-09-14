#!/usr/bin/env bash
# StaffDeck Cloudflare 内网穿透助手
# 用法:
#   scripts/cloudflare_tunnel.sh quick [--port 5173]   # 临时域名,无需备案/托管,适合联调
#   scripts/cloudflare_tunnel.sh run                   # 运行已配置的命名隧道 staffdeck (-> 5173)
#   scripts/cloudflare_tunnel.sh status                # 查看隧道 + 本地 5173 状态
#   scripts/cloudflare_tunnel.sh logs [-f]             # 查看命名隧道日志
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TUNNEL_ID="26711921-9610-4183-b3f9-867d33a17081"
HOSTNAME="staffdeck.yaozheng.ccwu.cc"
CONFIG="/etc/cloudflared/staffdeck.yml"
SERVICE="cloudflared-staffdeck.service"
APP_PORT="${APP_PORT:-5173}"

cmd="${1:-status}"
case "$cmd" in
  quick)
    port="${3:-$APP_PORT}"
    if [[ "${2:-}" =~ ^[0-9]+$ ]]; then port="$2"; fi
    # 解析 --port 5173 形式
    for ((i=1; i<=$#; i++)); do
      if [[ "${!i}" == "--port" ]]; then
        j=$((i+1)); port="${!j}"
      fi
    done
    echo "Starting Cloudflare Quick Tunnel -> http://127.0.0.1:${port}"
    echo "公网 URL 会打印在输出的 trycloudflare.com 那一行 (Ctrl-C 停止)"
    exec cloudflared tunnel --no-autoupdate --url "http://127.0.0.1:${port}"
    ;;
  run)
    if systemctl list-unit-files | grep -q "$SERVICE"; then
      sudo systemctl enable --now "$SERVICE"
      sudo systemctl status "$SERVICE" --no-pager -l | head -n 20
    else
      echo "systemd service 未安装,前台运行 (Ctrl-C 停止): $CONFIG"
      exec cloudflared tunnel --no-autoupdate --config "$CONFIG" run
    fi
    ;;
  status)
    echo "== StaffDeck 本地 =="
    (curl -s -o /dev/null -w "local 5173 /api/health: %{http_code}\n" "http://127.0.0.1:${APP_PORT}/api/health" || echo "local 5173: unreachable") | head -n 5
    echo "== DNS =="
    getent hosts "$HOSTNAME" | head -n 3 || nslookup "$HOSTNAME" | tail -n 5 || true
    echo "== Tunnel =="
    cloudflared tunnel info "$TUNNEL_ID" 2>&1 | head -n 20 || true
    echo "== Service =="
    systemctl is-active "$SERVICE" 2>&1 || true
    echo "== 公网健康检查 =="
    curl -s -o /dev/null -w "https://${HOSTNAME}/api/health: %{http_code}\n" --max-time 15 "https://${HOSTNAME}/api/health" || echo "public: unreachable (tunnel 可能未启动,跑 scripts/cloudflare_tunnel.sh run; 若刚重启过 app,确认启动时已 source scripts/cloudflare_env.sh)"
    ;;
  logs)
    shift || true
    journalctl -u "$SERVICE" "$@" | tail -n 100
    ;;
  *)
    echo "用法: $0 {quick|run|status|logs}"
    exit 1
    ;;
esac
