#!/bin/bash

ICON_FILE="/workspace/json/icon.json"
WEB_TRIGGER_SCRIPT="/workspace/update_web_trigger.sh"

# 检查 jq 是否安装，如果没有则自动安装
if ! command -v jq &> /dev/null; then
    echo "jq 未安装，正在安装..."
    apt update && apt install -y jq
    if [ $? -ne 0 ]; then
        echo "错误: 无法安装 jq，请手动安装"
        exit 1
    fi
fi

# 检查参数
if [ $# -eq 0 ]; then
    echo "用法:"
    echo "  update_icon.sh -add <key> <url> <height>"
    echo "  update_icon.sh -delete <key>"
    exit 1
fi

COMMAND="$1"

case "$COMMAND" in
    -add)
        # 检查参数数量
        if [ $# -lt 4 ]; then
            echo "用法: update_icon.sh -add <key> <url> <height>"
            exit 1
        fi

        KEY="$2"
        URL="$3"
        HEIGHT="$4"

        # 添加新图标
        jq --arg key "$KEY" \
           --arg url "$URL" \
           --argjson height "$HEIGHT" \
           '.[$key] = {"class": ($key + "-icon"), "url": $url, "height": $height}' \
           "$ICON_FILE" > "${ICON_FILE}.tmp" && mv "${ICON_FILE}.tmp" "$ICON_FILE"

        echo "已添加图标: $KEY"

        # 自动运行 update_web_trigger.sh
        echo "正在更新 web_trigger.yml..."
        bash "$WEB_TRIGGER_SCRIPT"
        ;;

    -delete)
        # 检查参数数量
        if [ $# -lt 2 ]; then
            echo "用法: update_icon.sh -delete <key>"
            exit 1
        fi

        INPUT_KEY="$2"

        # 查找匹配的键名（不区分大小写）
        ACTUAL_KEY=$(jq -r 'keys[]' "$ICON_FILE" | grep -i "^${INPUT_KEY}$" | head -1)

        if [ -z "$ACTUAL_KEY" ]; then
            echo "图标不存在: $INPUT_KEY"
            exit 1
        fi

        # 删除图标
        jq --arg key "$ACTUAL_KEY" 'del(.[$key])' "$ICON_FILE" > "${ICON_FILE}.tmp" && mv "${ICON_FILE}.tmp" "$ICON_FILE"

        echo "已删除图标: $ACTUAL_KEY"

        # 自动运行 update_web_trigger.sh
        echo "正在更新 web_trigger.yml..."
        bash "$WEB_TRIGGER_SCRIPT"
        ;;

    *)
        echo "用法:"
        echo "  update_icon.sh -add <key> <url> <height>"
        echo "  update_icon.sh -delete <key>"
        exit 1
        ;;
esac
