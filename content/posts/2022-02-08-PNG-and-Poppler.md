+++
title = "PNG and Poppler"
date = 2022-02-08T18:34:16+08:00
tags = ["latex"]
categories = ["linux"]
draft = false
+++

前段时间碰到一个问题：xelatex 生成出来的 pdf，用阅读器（atril）打开，
图片看不见。

编译的时候，有报警信息如：

```text
Overfull \hbox (170.25pt too wide) in paragraph at lines 2169--2170
```

图片确实偏大，但 orgmode 导出为 tex 的时候，图片会自动设置
`[width=.9\linewidth]`，而且搜索结果显示这个报警并不重要。

### Poppler or not?

进一步试验发现，基于 poppler 的 PDF 浏览器，稍大一点的那两张图片都没显
示。包括 atril, evince, qpdfview, okular 等等。

Firefox, Chrome, SumatraPDF, mupdf, foxit 都没问题。我很喜欢 mupdf，可
惜 mupdf 不能显示 PDF 文档的书签栏，且原生 X11 的复制、粘贴并不鼠标友
好。

### pdfimage

poppler-utils 里包含了一个工具 pdfimage，用来抓取 PDF 文档里的图片。试
验了一下，生成 PDF 文档时一共嵌入 6 张 PNG 图片，但却解出来 11 张
PPM 图片。而不能显示的两张大图各自对应一张同样大小但全黑的 PPM。

### jpg?

用 ImageMagick 自带的 convert 工具把两张 png 转换成 jpg，重新编译一下
PDF，这回 atril 能正确显示那两张图了。

### png again？

把 jpg 重新转换成 png，令人意外的是，这回生成出来的 PDF 也 OK. 用
pdfimage 提取图片，发现也正常的提取了 6 张图片。

### Color depth

对比了一下，原图 PNG 是 16-bit RGBA，转化成 jpg 再转回去的 PNG 是
8-bit RGB.

所以问题可能在于：

- poppler 处理 PDF 内嵌的 16 bit PNG 有问题（因为 mupdf 没问题）；
- 或者，XeTeX 处理 PNG 有问题（因为嵌入的图片比引入的多）。
