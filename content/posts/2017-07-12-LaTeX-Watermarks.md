+++
categories = ["programming"]
date = "2017-07-12T17:26:55+08:00"
description = ""
tags = ["latex"]
title = "LaTeX Watermarks"
url = "/2017/07/12/LaTeX-Watermarks/"
+++

前几天，同事问我中文省略号怎么输入。我说我用 org-mode 都是直接插入
LaTeX 标记 `\ldots`。其实中文输入状态下，按 `shift-6` 即可。想起来，如
果是在中文环境下输入笑脸 `^_^` ，会得到`……——……`。这里，`shift-_` 得到
一个破折号。

引申出类似的问题，如何输入：

1. 度数符号：`°`
2. 中间点号：`·`

试试在中文输入法下，按一下 `ESC` 下方的按键。

## 水印

就在我沉醉于 `\ldots` 时，收到一则推送：通过 LaTeX 在生成的 pdf 文档中
加入水印。很简单：

```tex
\usepackage{draftwatermark}
\SetWatermarkText{Confidential}
\SetWatermarkScale{5}
```

## 文字和字体

如果没有设置水印显示的文字（如上：Confidential），默认是 "DRAFT"，而且
水印的字体是可以设置的：

```tex
\SetWatermarkText{\textsc{Confidential}}
```

## 颜色和灰度

```tex
\SetWatermarkColor[rgb]{1,0,0}
\SetWatermarkColor[gray]{0.5}
```

## 字体大小

```tex
\SetWatermarkFontSize{2cm}
```

## 拉伸

默认是 1.2

```tex
\SetWatermarkScale{5}
```

## 字体旋转

默认 45°

```tex
\SetWatermarkAngle{30}
```

## 其它选项

### 仅首页显示水印

```tex
\usepackage[firstpage]{draftwatermark}
```

### 取消水印

```
\usepackage[nostamp]{draftwatermark}
```

## 资料来源

以上资料来自 [texblog.org](http://texblog.org/2012/02/17/watermarks-draft-review-approved-confidential/)
