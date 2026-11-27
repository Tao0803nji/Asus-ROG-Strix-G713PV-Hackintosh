#!/bin/bash
# 安装 BOE NE173QHM-NZ2 的 Display Override（提供 1920×1080 / 1600×900 / 1440×810 等缩放档位）
# 用法：sudo bash install-display-override.sh
set -e

SRC="$(cd "$(dirname "$0")" && pwd)/display-override/DisplayProductID-b69"
DST_DIR="/Library/Displays/Contents/Resources/Overrides/DisplayVendorID-9e5"
DST="$DST_DIR/DisplayProductID-b69"

[ "$(id -u)" = "0" ] || { echo "请用 sudo 运行"; exit 1; }
[ -f "$SRC" ] || { echo "找不到 $SRC"; exit 1; }

mkdir -p "$DST_DIR"
[ -f "$DST" ] && cp -p "$DST" "$DST.bak-$(date +%Y%m%d-%H%M%S)"
cp "$SRC" "$DST"
chown root:wheel "$DST"
chmod 644 "$DST"
plutil -lint "$DST" >/dev/null

echo "已安装到 $DST"
echo "重启后生效；可用 /tmp/cgsmodes list 查看缩放档位。"
