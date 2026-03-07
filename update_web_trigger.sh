#!/bin/bash

# 读取 icon.json 获取所有图标名称
ICON_FILE="/workspace/json/icon.json"
COLLECT_FILE="/workspace/json/collect.json"
WEB_TRIGGER_FILE="/workspace/.cnb/web_trigger.yml"

# 检查 jq 是否安装，如果没有则自动安装
if ! command -v jq &> /dev/null; then
    echo "jq 未安装，正在安装..."
    apt update && apt install -y jq
    if [ $? -ne 0 ]; then
        echo "错误: 无法安装 jq，请手动安装"
        exit 1
    fi
fi

# 获取所有图标名称
ICON_KEYS=$(jq -r 'keys[]' "$ICON_FILE")

# 删除现有的 .params_options 和 .params_options_label 部分
TEMP_FILE=$(mktemp)
# 先删除 .params_options 部分
sed '/^\.params_options:/,/^$/d' "$WEB_TRIGGER_FILE" | sed '/^\.params_options:/,/^[a-zA-Z_]/d' > "$TEMP_FILE"
# 再删除 .params_options_label 部分
TEMP_FILE2=$(mktemp)
sed '/^\.params_options_label:/,/^$/d' "$TEMP_FILE" | sed '/^\.params_options_label:/,/^[a-zA-Z_]/d' > "$TEMP_FILE2"

# 构建新的 .params_options 部分
NEW_PARAMS=".params_options: &params_options"

# 添加每个图标
for icon in $ICON_KEYS; do
    NEW_PARAMS="${NEW_PARAMS}
  - name: ${icon}
    value: ${icon}"
done

# 从 collect.json 读取类别键名（HTML、Watch等）
COLLECT_KEYS=$(jq -r 'keys[]' "$COLLECT_FILE")

# 构建 .params_options_label 部分
NEW_PARAMS="${NEW_PARAMS}

.params_options_label: &params_options_label"

# 添加每个类别
for category in $COLLECT_KEYS; do
    NEW_PARAMS="${NEW_PARAMS}
  - name: ${category}
    value: ${category}"
done

# 将新内容插入到文件开头
{
    echo "$NEW_PARAMS"
    echo ""
    cat "$TEMP_FILE2"
} > "$WEB_TRIGGER_FILE"

# 清理临时文件
rm -f "$TEMP_FILE" "$TEMP_FILE2"

echo "更新完成！"
