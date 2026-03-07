#!/bin/bash

# 检查是否提供了 URL 参数
if [ $# -eq 0 ]; then
    echo "用法: $0 <URL>"
    echo "示例: $0 https://cnb.cool/"
    exit 1
fi

TARGET_URL="$1"
JSON_FILE="/workspace/json/collect.json"

# 检查 JSON 文件是否存在
if [ ! -f "$JSON_FILE" ]; then
    echo "错误: JSON 文件不存在: $JSON_FILE"
    exit 1
fi

# 检查 jq 是否安装，如果没有则自动安装
if ! command -v jq &> /dev/null; then
    echo "jq 未安装，正在安装..."
    apt update && apt install -y jq
    if [ $? -ne 0 ]; then
        echo "错误: 无法安装 jq，请手动安装"
        exit 1
    fi
fi

# 生成带/和不带/的两种形式
URLS_TO_MATCH=("$TARGET_URL")
if [[ "$TARGET_URL" == */ ]]; then
    URLS_TO_MATCH+=("${TARGET_URL%/}")
else
    URLS_TO_MATCH+=("${TARGET_URL}/")
fi

echo "正在删除匹配的条目: ${URLS_TO_MATCH[*]}"

# 创建临时文件
TEMP_FILE=$(mktemp)
trap 'rm -f "$TEMP_FILE"' EXIT

# 获取所有分类
CATEGORIES=$(jq -r 'keys[]' "$JSON_FILE")

DELETED_COUNT=0

# 对每个分类进行处理
while IFS= read -r category; do
    # 获取该分类的原始长度
    ORIGINAL_LENGTH=$(jq --arg cat "$category" '.[$cat] | length' "$JSON_FILE")
    
    # 构建 jq 过滤条件
    FILTER=".[\"$category\"] = [.[\"$category\"][] | select(.href != \"${URLS_TO_MATCH[0]}\""
    
    # 添加第二个 URL 的过滤条件
    if [[ "${URLS_TO_MATCH[1]}" != "${URLS_TO_MATCH[0]}" ]]; then
        FILTER="$FILTER and .href != \"${URLS_TO_MATCH[1]}\""
    fi
    
    FILTER="$FILTER)]"
    
    # 应用过滤
    jq "$FILTER" "$JSON_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$JSON_FILE"
    
    # 获取新长度
    NEW_LENGTH=$(jq --arg cat "$category" '.[$cat] | length' "$JSON_FILE")
    
    DELETED=$((ORIGINAL_LENGTH - NEW_LENGTH))
    if [ $DELETED -gt 0 ]; then
        echo "从分类 '$category' 中删除了 $DELETED 个条目"
        DELETED_COUNT=$((DELETED_COUNT + DELETED))
    fi
done <<< "$CATEGORIES"

if [ $DELETED_COUNT -gt 0 ]; then
    echo "成功删除了 $DELETED_COUNT 个条目 (匹配: ${URLS_TO_MATCH[*]})"
else
    echo "未找到匹配的条目 (匹配: ${URLS_TO_MATCH[*]})"
fi

echo "操作完成"