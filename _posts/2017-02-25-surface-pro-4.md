---
layout: post
title: "Surface Pro 4"
description: ""
category: life
tags: [Windows]
---
{% include JB/setup %}

为了比较方便高效地看文档（主要是PDF）、记笔记，平衡了诸般选择后，买了
一台 `Surface Pro 4`。最低配的版本，但是手写笔套装。用了两三个礼拜后，
还是忍不住又买了官方键盘。总共耗资 5k 多，至少要看几百本书才能回本。刚
拆箱上电的时候，有两次触摸屏没有反应。刚好老婆微信问效果怎么样（因为老
婆身边同事偏差评的多），一身冷汗。还好，更新了系统后没出一点幺蛾子。

脑子一抽筋，想尝试用 `Markdown` 来写格式化文档，因为 `Windows` 下我没
有 `Office` 软件。在 `Linux` 下，我是用 `Emacs orgmode`，可以输出各种
格式，尤其是表格、公式的输入体验，要甩开主流 `Markdown` 编辑器几条街。

## 字体

在同事的建议下，配置了一个苹果上面比较流行的苹芳字体。中文显示效果不错，
但是英文不是等宽，作为码农，很不习惯。还有一个 `Windows` 下的 `YaHei
Consolas Hybrid`，第一个中文字符的显示总是有点奇怪，有点下沉的感觉。

## 编辑器

对比了 `Atom` 和 `vscode` 后，选择了后者。选择了如下插件：

1. Markdown PDF - 自动导出 PDF，支持中文
2. Markdown TOC - 为 `Markdown` 生成目录
3. vscode-pandoc - pandoc 接口

最终只保留了 `vscode-pandoc`。

### Markdown PDF

依赖 `phantomjs` 且 Windows 下需要自己下一个并配置好。输出的格式比较糟
糕（或许可以通过调整样式配置来解决）。

### Markdown TOC

最终输出的目录没有页码，而且输出为PDF格式后的样式也很糟糕。

### vscode-pandoc

需要装一个 `pandoc`，而 `pandoc` 输出 PDF 依赖 `LaTeX`，于是我又装了一
个 `MikTeX`。但是输出的 PDF 效果很赞。因为 `LaTeX` 的中文支持不给力，
于是给 `vscode-pandoc` 配置了如下参数:

> --latex-engine=xelatex -V mainfont="PingFang SC" --toc -s -S -N

生成出来的 PDF 自动带有目录，章节有序号，正合我意思。如果是想写幻灯片，
用 `-t beamer` 就好。而且因为装了 `MikTeX`，其中自带的 `TeXworks` 里面
有很多模板可选，实在不行可以直接写 `LaTeX` 文稿。用`TeX`类系统还有一个
好处，就是中文换行的在最终 `PDF` 文件里面会被处理掉，`Markdown` 本身的
文字可以换行，而不用担心输出内容中间会被插入空格之类。基于 `phantomjs`
类的解决方案应该都会有这个问题。

## So Why?

那么当初为啥买苏菲婆？基本上，码字、或者用Lisp/ML家族的语言，我喜欢用
`Emacs`，码C语言家族的代码我喜欢用`Vim`。中英文混杂的时候频繁切换输入
法用 `Vim` 很不方便，而且`orgmode` 实在是太方便了。但是 Windows 下用
`Vim` 或者 `Emacs` 天生就像瘸了半条腿，因为缺少各种 Shell命令的辅助。
Windows 比较方便的地方在于 `OneNote` 笔记，`OneDrive`同步。在手写笔支
持方面，有三个免费应用程序比较酷：

1. OneNote - 无需多言
2. Xodo - PDF Reader and Editor
3. Nebo - the best way to take notes

网上推荐最多的是 `Drawboard PDF`，不过 `Xodo` 似乎也够用了。`Nebo` 之
前收费，现在免费了。设计有很多 `Pen Gesture`，很有意思。
