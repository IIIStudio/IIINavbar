# Project Schema Reference

## update_add_collect.sh Usage

```
./update_add_collect.sh -add 类别 href img name jianjie top [附加URL ...]
```

| 参数 | 类型 | 说明 |
|------|------|------|
| 类别 | string | JSON 分类名，如 HTML, Watch, PC, Android, AI, URL |
| href | string | 主网站 URL |
| img | string | favicon/图标 URL（https:// 开头则脚本自动下载到 ./image/） |
| name | string | 网站名称 |
| jianjie | string | 中文简介（≤18中文字符） |
| top | number | 1=插入到第一位，0=追加到末尾 |
| 附加URL | ... | 可选，多个空格分隔，脚本自动识别类型 |

## 脚本自动识别的 URL 类型

| URL 模式 | 映射 key |
|----------|----------|
| `github.com` | GitHub |
| `vercel.com` / `vercel.app` | vercel |
| `play.google.com` | GooglePlay |
| `t.me` | tg |
| `qm.qq.com` | QQ |
| `.sharepoint.com` / `1drv.ms` | OneDrive |
| `pypi.org` / `python` | Python |
| `tui` | tui |
| `gw` | gw |
| `wenzhang` | wenzhang |

也支持手动指定：`tg=https://t.me/xxx`、`gi=https://github.com/xxx` 等简写。

## collect.json 结构

Path: `json/collect.json`

```json
{
  "CategoryName": [
    {
      "href": "https://main-url/",
      "img": "./image/favicon-name.png",
      "nome": "Site Name",
      "jianjie": "中文简介不超过18字。",
      "GitHub": "https://github.com/...",
      "vercel": "https://...vercel.app/"
    }
  ]
}
```

### 已支持的附加 key（需在 icon.json 中存在）
GitHub, vercel, tui, tg, GooglePlay, QQ, Python, OneDrive, gw, wenzhang

## icon.json 结构

Path: `json/icon.json`

定义可选 key 的图标渲染配置。每个 key 包含：class, url, height, ratio（可选）。

## 图片存储

图标由脚本自动下载到 `./image/` 目录，文件名格式为 `{name}.png`。
