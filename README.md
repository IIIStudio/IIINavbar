# IIINavbar 收藏或展示页
一个简单的收藏或展示页

## 使用方法
修改icon.json文件，添加或删除icon

修改collect.json文件，添加或删除收藏地址 

参数说明
```json
{
    "HTML": [
        {
            "href": "https://iii.ohao.net/",
            "img": "./image/IIIStudio.png",
            "nome": "IIINavbar",
            "jianjie": "收藏导航。",
            "GitHub": "https://github.com/IIIStudio/IIINavbar",
            "vercel": "https://vercel.com/import/project?template=https://github.com/IIIStudio/IIINavbar/tree/main",
            "tui": "https://iii.ohao.net/"
        },

```
### 主要参数：
`HTML`为的类别，
`href`为的地址，
`img`为的图标，
`nome`为的名称，
`jianjie`为的简介，
### icon参数：
这些是在icon.json中添加 例如：
```
    "vercel": {
        "class": "vercel-btn",
        "url": "./image/vercel.png",
        "height": 16
    },
```
`vercel`为的为变量，
`url`为的vercel图片地址，
`height`为图片大小，如果是长图，添加"ratio": 3.111

## 搭建

复刻 然后修改参数，然后添加 GitHub Pages 网站

Vercel一键部署:

<a href="https://vercel.com/import/project?template=https://github.com/IIIStudio/IIINavbar/tree/main"><img src="https://vercel.com/button" height="24"></a>

## 图片

![](./image/1.jpg)