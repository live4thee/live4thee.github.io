+++
categories = ["linux"]
date = "2017-07-15T23:42:37+08:00"
description = ""
tags = ["sysadmin"]
title = "Combine Pics to PDF"
url = "/2017/07/15/combine-pics-to-pdf/"
+++

简记一则技巧：网上看见一在线PPT，但是每一页都被转换成了PNG图片，怎么把
它们制成一个PDF文件？

## 批量下载

假设有30页，每一页的图片都遵循相同的命名模式：`name%d.png`

```sh
for i in `seq 30`; do wget http://some-domain/path/to/name$i.png; done
```

## 转换

不加处理直接转换时，边框留白的间距可能比较糟糕，建议处理一下。

```sh
convert -scale 3508x2479 -border 64x64 -bordercolor white \
  name1.png name2.png ... name30.png \
  combined.pdf
```

其中 `name1.png ... name30.png` 序列可以通过 `seq` 配合 `xargs` 生成。
如果每一页还需要顺时针旋转90度，则加上 `-rotate "90>"`。`3508x2479`也
就是：`A4@300dpi`。


## 更精细的控制

如果每一页都需要特殊处理，则可以每一页单独通过 `convert` 处理后，再用
`pdftk` 合成一个 pdf 文件。

```sh
pdftk name1.pdf name2.pdf ... name30.pdf cat output combined.pdf
```
