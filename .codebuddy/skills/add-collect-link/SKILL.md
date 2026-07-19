---
name: add-collect-link
description: "将用户提供的链接自动添加到 IIINavbar 收藏夹的 collect.json 中。触发方式：用户输入'添加网站'后跟 URL 和可选分类名，如'添加网站 https://xxx.com AI'。支持自动获取网站标题、图标、生成中文简介，并识别 GitHub/vercel/官网等附加链接。"
---

# 添加收藏链接

## 概述

此 skill 为 IIINavbar 收藏夹准备新条目数据，然后调用内嵌的 `scripts/update_add_collect.sh` 脚本写入 `json/collect.json`。脚本内部处理图片下载和 JSON 操作。

**脚本位置**：此 skill 目录下的 `scripts/update_add_collect.sh`。安装位置可能为 `.codebuddy/skills/add-collect-link/` 或 `~/.codebuddy/skills/add-collect-link/`，执行前先确认实际路径。
**必须在工作区根目录运行**（`/workspace`），因为脚本引用相对路径 `json/collect.json`、`json/icon.json`。

脚本调用格式：
```
{SKILL_DIR}/scripts/update_add_collect.sh -add 类别 href img name jianjie top [附加URL ...]
```

- **类别**：分类名称（HTML, Watch, PC, Android, AI, URL 等）
- **href**：主网站 URL
- **img**：favicon URL（以 `https://` 开头则脚本自动下载到 `./image/`）
- **name**：网站标题
- **jianjie**：中文简介（最多 18 个中文字符）
- **top**：1 = 插入到第一位，0 = 追加到末尾
- **附加URL**：额外的链接（脚本自动识别 GitHub, vercel, tg, GooglePlay 等）

## 工作流程

### 第一步：解析用户输入

触发格式：`添加网站 URL1 URL2 ... 分类名`

从用户消息中提取：

1. **所有 URL** - 按空格/换行分割
2. **分类名称** - 非 URL 的单词（如 "AI"、"HTML"、"Watch"、"PC"、"Android"、"URL"）
3. **位置提示** - 如果用户说"第N个"、"第一个"、"最后一个"，确定 `top` 值

解析规则：
- **第一个 URL** 作为 `href` 参数
- **其余 URL** 作为附加链接参数传入
- 如果非 URL 单词与 `collect.json` 中已有分类匹配，则作为目标分类
- 如果未指定分类，使用 `collect.json` 中的**最后一个分类**
- 如果分类不存在，脚本会自动创建
- 默认 `top=0`（追加到末尾），除非用户指定了位置

### 第二步：获取网站元数据

使用 `web_fetch` 获取**第一个 URL** 的页面，提取：

1. **Title** - 页面 title 标签内容 → 作为 `name` 参数
2. **Favicon URL** - 检查 link rel="icon"、link rel="shortcut icon"，或回退到 `{域名}/favicon.ico` → 作为 `img` 参数
3. **Description** - 检查 meta name="description" → 用于生成 `jianjie`

### 第三步：生成中文简介（jianjie）

要求：
- **最多 18 个中文字符**（按实际字形计数，非字节数）
- 原文为**英文**则翻译为中文
- **过长**则精简，保留核心含义/主体信息
- 关注网站的**主要功能**
- 适当以中文句号 `。` 结尾

示例：
- "Minimal web UI for GeminiPro." → "GeminiPro 轻量界面。"
- "A fast, open-source note-taking app with cloud sync" → "开源云端笔记应用。"
- "Quick clipboard and note sharing tool" → "快捷剪贴板与笔记。"

### 第四步：准备附加 URL

收集第一个之后的所有 URL。脚本会自动识别类型：
- `github.com` → GitHub
- `vercel.com` / `vercel.app` → vercel
- `play.google.com` → GooglePlay
- `t.me` → tg
- `qm.qq.com` → QQ
- `.sharepoint.com` / `1drv.ms` → OneDrive
- `pypi.org` / `python` → Python
- `tui` → tui
- `gw` → gw
- `wenzhang` → wenzhang

这些直接作为额外参数传入 —— 脚本负责映射。

如果用户需要指定非 URL 的 key（如没有实际链接的 `tg=xxx`），使用 `key=value` 格式。

### 第五步：执行脚本

脚本必须从工作区根目录（`/workspace`）运行。先找到 skill 目录的实际路径（检查 `.codebuddy/skills/add-collect-link` 和 `~/.codebuddy/skills/add-collect-link`），然后构造命令：

```bash
cd /workspace && {SKILL_DIR}/scripts/update_add_collect.sh -add "{类别}" "{href}" "{img_url}" "{name}" "{jianjie}" {top} {url2} {url3} ...
```

**参数注意事项：**
- 所有字符串参数（类别、href、img、name、jianjie）必须**双引号包裹**，以处理特殊字符
- `top` 是数字（不引号）：`0` 表示追加，`1` 表示第一位
- 附加 URL 原样传入（不引号，空格分隔）
- 只传入存在的附加 URL —— 没有则完全省略
- 命令必须包含 `cd /workspace &&`，因为脚本使用相对路径（`json/collect.json`、`json/icon.json`、`image/`）

**示例命令：**
```bash
cd /workspace && .codebuddy/skills/add-collect-link/scripts/update_add_collect.sh -add "AI" "https://example.com" "https://example.com/favicon.ico" "示例网站" "这是一个示例。" 0 https://github.com/user/repo
```

### 第六步：报告结果

脚本执行后，总结：
- 使用的分类和位置
- 网站名称和简介
- 已下载的图标 URL
- 检测并添加的附加链接

## 关键规则

1. **始终将远程 favicon URL 作为 `img` 传入** —— 让脚本下载，不要手动下载图片。
2. **始终双引号包裹** 类别、href、img、name、jianjie 参数。
3. **始终 `top=0`**，除非用户明确说"第一个"或"第N个"。
4. **始终从 `/workspace` 运行** —— 先定位 skill 目录，再执行 `cd /workspace && {SKILL_DIR}/scripts/update_add_collect.sh ...`
5. 先读取 `json/collect.json` 确认目标分类存在并确定默认分类。
6. 如果 `web_fetch` 获取元数据失败，使用域名作为回退标题。
7. 参考 `references/project_schema.md` 获取完整 JSON 结构和支持的图标类型。
