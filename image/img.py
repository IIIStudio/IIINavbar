import os
import glob
from pathlib import Path

def 生成图片标记文档():
    """
    将当前目录中的图片生成Markdown格式，写入到README.md
    支持子目录分类显示
    """
    # 定义当前目录路径
    当前目录 = "."
    输出文件 = "README.md"
    
    # 支持的图片格式
    图片扩展名列表 = ['*.jpg', '*.jpeg', '*.png', '*.gif', '*.bmp', '*.webp']
    
    # 收集所有图片文件，按目录分类
    目录图片字典 = {}
    
    # 首先处理当前目录的图片
    当前目录图片列表 = []
    for 扩展名 in 图片扩展名列表:
        匹配模式 = os.path.join(当前目录, 扩展名)
        当前目录图片列表.extend(glob.glob(匹配模式))
        # 同时查找大写扩展名
        匹配模式大写 = os.path.join(当前目录, 扩展名.upper())
        当前目录图片列表.extend(glob.glob(匹配模式大写))
    
    # 过滤掉Python文件自身和README.md文件
    过滤后图片列表 = []
    for 文件路径 in 当前目录图片列表:
        文件名 = os.path.basename(文件路径)
        if 文件名 != os.path.basename(__file__) and 文件名 != 输出文件:
            过滤后图片列表.append(文件路径)
    
    if 过滤后图片列表:
        过滤后图片列表.sort()
        目录图片字典["."] = 过滤后图片列表
    
    # 查找所有子目录（排除隐藏目录）
    for 根路径, 目录列表, 文件列表 in os.walk(当前目录):
        # 跳过当前目录（已经处理过）
        if 根路径 == 当前目录:
            continue
            
        # 跳过隐藏目录（以点开头的目录）
        目录列表[:] = [目录 for 目录 in 目录列表 if not 目录.startswith('.')]
        
        # 获取相对路径作为目录名
        相对路径 = os.path.relpath(根路径, 当前目录)
        
        # 收集该目录下的所有图片
        子目录图片列表 = []
        for 扩展名 in 图片扩展名列表:
            匹配模式 = os.path.join(根路径, 扩展名)
            子目录图片列表.extend(glob.glob(匹配模式))
            # 同时查找大写扩展名
            匹配模式大写 = os.path.join(根路径, 扩展名.upper())
            子目录图片列表.extend(glob.glob(匹配模式大写))
        
        if 子目录图片列表:
            子目录图片列表.sort()
            目录图片字典[相对路径] = 子目录图片列表
    
    if not 目录图片字典:
        print(f"在当前目录中未找到图片文件")
        return
    
    # 生成Markdown内容
    标记内容 = "# 图片库\n\n"
    
    # 统计总图片数
    总图片数 = sum(len(图片列表) for 图片列表 in 目录图片字典.values())
    标记内容 += f"总计 {总图片数} 张图片\n\n"
    
    # 按目录生成内容
    for 目录名, 图片文件列表 in 目录图片字典.items():
        if 目录名 == ".":
            # 当前目录
            标记内容 += "## 当前目录\n\n"
        else:
            # 子目录，使用目录名作为标题
            标记内容 += f"## {目录名}\n\n"
        
        # 使用HTML表格布局，图片添加超链接
        标记内容 += "<table>\n"
        
        for 索引, 图片路径 in enumerate(图片文件列表):
            图片名称 = os.path.basename(图片路径)
            相对路径 = 图片路径.replace('\\', '/')
            
            # 每行开始 - 改为每4张图片一行
            if 索引 % 4 == 0:
                标记内容 += "  <tr>\n"
            
            # 每个单元格 - 图片添加超链接
            标记内容 += f"    <td align=\"center\">\n"
            标记内容 += f"      <a href=\"{相对路径}\" target=\"_blank\">\n"
            标记内容 += f"        <img src=\"{相对路径}\" alt=\"{图片名称}\" width=\"200\"><br>\n"
            标记内容 += f"      </a>\n"
            标记内容 += f"      <sub>{图片名称}</sub>\n"
            标记内容 += f"    </td>\n"
            
            # 每行结束或最后一个图片 - 改为每4张图片一行
            if 索引 % 4 == 3 or 索引 == len(图片文件列表) - 1:
                标记内容 += "  </tr>\n"
        
        标记内容 += "</table>\n\n"
    
    # 写入README.md文件
    try:
        with open(输出文件, 'w', encoding='utf-8') as 文件对象:
            文件对象.write(标记内容)
        print(f"成功生成 {输出文件}，包含 {总图片数} 张图片")
        
        # 显示生成的目录结构
        print("\n目录结构：")
        for 目录名, 图片列表 in 目录图片字典.items():
            if 目录名 == ".":
                print(f"当前目录: {len(图片列表)} 张图片")
            else:
                print(f"{目录名}: {len(图片列表)} 张图片")
                
    except Exception as 错误信息:
        print(f"写入文件时出错: {错误信息}")

if __name__ == "__main__":
    print("开始生成图片Markdown文档...")
    生成图片标记文档()
    print("\n完成！")