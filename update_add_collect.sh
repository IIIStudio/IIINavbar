#!/usr/bin/env bash

COLLECT_JSON_FILE="json/collect.json"
ICON_JSON_FILE="json/icon.json"

# 显示帮助信息
show_help() {
    echo "用法: $0 -add 类别 href img name jianjie top [图标URL ...]"
    echo ""
    echo "参数说明（前6个固定）:"
    echo "  类别      - JSON中的分类名，如 HTML, Watch, PC, URL 等"
    echo "  href      - 主URL地址"
    echo "  img       - 图片地址"
    echo "  name      - 项目名称"
    echo "  jianjie   - 项目简介"
    echo "  top       - 插入位置（数字），1表示第一个，0或留空表示追加到最后"
    echo ""
    echo "后面的参数（可选，可多个）:"
    echo "  图标URL - 例如 https://github.com/xxx 或 tg=https://t.me/xxx"
    echo ""
    echo "支持的图标类型: GitHub, GooglePlay, OneDrive, QQ, Python, tg, tui, vercel, gw, wenzhang"
    echo ""
    echo "格式支持:"
    echo "  1. 自动识别: https://github.com/xxx -> GitHub"
    echo "  2. 手动指定: tg=https://t.me/xxx"
    echo "  3. 简写支持: gi=https://github.com/xxx"
    echo ""
    echo "示例:"
    echo "  $0 -add URL \"https://app.alice.ws/compute\" \"https://pic2.ziyuan.wang/.../alice.png\" \"alice\" \"免费服务器。\" 1 tg=https://t.me/xxx https://github.com/xxx"
}

# 检查图标是否存在于 json/icon.json 中
check_icon_exists() {
    local icon_name="$1"
    
    if [ -f "$ICON_JSON_FILE" ]; then
        if grep -q "\"$icon_name\"" "$ICON_JSON_FILE"; then
            return 0  # 存在
        fi
    fi
    return 1  # 不存在
}

# 根据参数识别图标类型
detect_icon_type() {
    local input="$1"
    local icon_type=""
    
    # 检查是否为 "type=url" 格式（type=后不能是 http）
    if [[ "$input" == *"="* ]]; then
        # 检查 = 前面是否不包含 http（说明是 type=url 格式，而不是 URL 中的参数）
        local before_eq=$(echo "$input" | cut -d'=' -f1)
        if [[ ! "$before_eq" == http* ]] && [[ ! "$before_eq" == *"."* ]]; then
            icon_type=$(echo "$before_eq" | tr '[:upper:]' '[:lower:]')
            
            # 只处理简写列表，其他情况返回空字符串
            case "$icon_type" in
                gi|gp|go|qq|py|od|tg|tu|ve|gw|we|tui)
                    # 处理简写
                    case "$icon_type" in
                        gi) icon_type="github" ;;
                        gp|go) icon_type="googleplay" ;;
                        qq) icon_type="qq" ;;
                        py) icon_type="python" ;;
                        od) icon_type="onedrive" ;;
                        tg) icon_type="tg" ;;
                        tu|tui) icon_type="tui" ;;
                        ve) icon_type="vercel" ;;
                        gw) icon_type="gw" ;;
                        we) icon_type="wenzhang" ;;
                    esac
                    echo "$icon_type"
                    return
                    ;;
                *)
                    # 完整名称（如 github=）返回空，让前面的 URL 自动识别处理
                    echo ""
                    return
                    ;;
            esac
        fi
    fi
    
    # 检查是否是纯关键词（不包含 http 或 =）
    if [[ ! "$input" == http* ]]; then
        icon_type=$(echo "$input" | tr '[:upper:]' '[:lower:]')
        echo "$icon_type"
        return
    fi
    
    # 根据 URL 自动识别
    local url="$input"
    
    case "$url" in
        *github.com*)
            icon_type="github"
            ;;
        *play.google.com*)
            icon_type="googleplay"
            ;;
        *.sharepoint.com*)
            icon_type="onedrive"
            ;;
        *python*)
            icon_type="python"
            ;;
        *qm.qq.com*)
            icon_type="qq"
            ;;
        *t.me*)
            icon_type="tg"
            ;;
        *tui*)
            icon_type="tui"
            ;;
        *vercel.com*)
            icon_type="vercel"
            ;;
        *gw*)
            icon_type="gw"
            ;;
        *wenzhang*)
            icon_type="wenzhang"
            ;;
        *)
            icon_type=""
            ;;
    esac
    
    echo "$icon_type"
}

# 从参数中提取 URL
extract_url() {
    local input="$1"
    
    if [[ "$input" == *"="* ]] && [[ ! "$input" == http* ]]; then
        echo "$input" | cut -d'=' -f2-
    else
        echo "$input"
    fi
}

# 格式化图标名称
format_icon_name() {
    local icon_type="$1"
    
    case "$icon_type" in
        github) echo "GitHub" ;;
        googleplay) echo "GooglePlay" ;;
        qq) echo "QQ" ;;
        python) echo "Python" ;;
        onedrive) echo "OneDrive" ;;
        tg) echo "tg" ;;
        tui) echo "tui" ;;
        vercel) echo "vercel" ;;
        gw) echo "gw" ;;
        wenzhang) echo "wenzhang" ;;
        *) 
            # 转换为首字母大写
            echo "$icon_type" | sed 's/\b\(.\)/\u\1/g'
            ;;
    esac
}

# 主函数
main() {
    if [ $# -eq 0 ]; then
        show_help
        exit 1
    fi
    
    if [ "$1" = "-add" ]; then
        shift  # 移除 -add 参数
        
        # 检查最少参数数量（6个固定参数）
        if [ $# -lt 6 ]; then
            echo "错误: 参数数量不正确"
            echo "最少需要 6 个参数: 类别 href img name jianjie top"
            echo "当前参数数量: $#"
            show_help
            exit 1
        fi
        
        # 提取固定参数
        local category="$1"
        local href="$2"
        local img="$3"
        local name="$4"
        local jianjie="$5"
        local top="$6"
        
        # 移动到可选参数
        shift 6
        
        # 如果 img 是 https URL，下载到 image 目录
        if [[ "$img" == https://* ]]; then
            # 确保 image 目录存在
            mkdir -p image
            
            # 从 URL 中提取文件名
            local filename=$(basename "$img")
            
            # 检查 URL 中是否有扩展名，如果没有则根据内容类型判断
            if [[ "$filename" != *"."* ]]; then
                # 尝试从 URL 中提取扩展名（去掉查询参数）
                filename=$(echo "$img" | grep -oP '[^/?]*\.[^/?]+' | head -1)
                if [ -z "$filename" ]; then
                    filename="${name}.png"
                fi
            fi
            
            local local_path="./image/$filename"
            
            # 下载文件
            echo "正在下载图片: $img"
            if curl -s -o "$local_path" "$img"; then
                echo "✓ 图片下载成功: $local_path"
                img="$local_path"
            else
                echo "⚠ 图片下载失败，使用原始 URL: $img"
            fi
        fi
        
        # 检查是否安装 jq
        if ! command -v jq >/dev/null 2>&1; then
            echo "错误: 未安装 jq"
            echo "请安装 jq: apt-get install jq 或 brew install jq"
            exit 1
        fi
        
        # 构建基本的 JSON 对象
        local base_json="{\"href\": \"$href\", \"img\": \"$img\", \"nome\": \"$name\", \"jianjie\": \"$jianjie\"}"
        
        # 处理可选的图标参数
        local icon_count=0
        for extra_param in "$@"; do
            echo "处理参数: $extra_param"
            local icon_type=$(detect_icon_type "$extra_param")
            echo "  识别类型: $icon_type"
            local url=$(extract_url "$extra_param")
            echo "  提取URL: $url"
            
            if [ -n "$icon_type" ]; then
                local formatted_icon=$(format_icon_name "$icon_type")
                echo "  格式化图标: $formatted_icon"
                
                # 如果 URL 不以 http 开头，则设置为 "#"
                if [[ "$url" != http* ]]; then
                    url="#"
                fi
                
                # 检查图标是否存在
                if check_icon_exists "$formatted_icon"; then
                    # 添加到 JSON
                    base_json=$(echo "$base_json" | jq --arg icon "$formatted_icon" --arg url "$url" '. + {($icon): $url}')
                    echo "✓ 添加图标: $formatted_icon -> $url"
                    ((icon_count++))
                else
                    echo "⚠ 跳过图标: $formatted_icon (不存在于 $ICON_JSON_FILE)"
                fi
            else
                echo "  未识别到图标类型"
            fi
        done
        
        echo ""
        echo "添加项目: $name"
        echo "  - 类别: $category"
        echo "  - 主URL: $href"
        echo "  - 位置: $top"
        echo ""
        
        # 更新 collect.json
        local update_result
        if [ "$top" -gt 0 ] 2>/dev/null; then
            # 在指定位置插入（jq 中数组索引从0开始，所以用 top-1）
            update_result=$(jq --arg category "$category" --argjson item "$base_json" --argjson pos "$((top - 1))" '
                if .[$category] == null then
                    .[$category] = [$item]
                else
                    .[$category] |= .[:$pos] + [$item] + .[$pos:]
                end
            ' "$COLLECT_JSON_FILE")
        else
            # 追加到最后
            update_result=$(jq --arg category "$category" --argjson item "$base_json" '
                if .[$category] == null then
                    .[$category] = [$item]
                else
                    .[$category] += [$item]
                end
            ' "$COLLECT_JSON_FILE")
        fi
        
        echo "$update_result" > "$COLLECT_JSON_FILE"
        echo "✓ 成功更新 $COLLECT_JSON_FILE"
        
    else
        show_help
        exit 1
    fi
}

main "$@"
