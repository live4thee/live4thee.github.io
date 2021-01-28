---
categories:
- emacs
date: 2017-03-10T00:00:00Z
description: ""
tags:
- orgmode
title: org export to latex
url: /2017/03/10/org-export-to-latex/
---


最近写 `orgmode` 笔记的时候碰到几个问题：

1. code block 没有语法高亮；
2. 输出的 pdf 文件中，python 代码对齐出错；
3. 输出的 pdf 文件中，源代码没有高亮。

解决办法如下：

```
;; fontify the code block in orgmode
(setq org-src-fontify-natively t)

;; for space sensitive languages like Python
(setq org-src-preserve-indentation t)

;; highlight source blocks with LaTeX listings
(require 'ox-latex)
(setq org-latex-listings t)
(add-to-list 'org-latex-packages-alist '("" "listings"))
(add-to-list 'org-latex-packages-alist '("" "color"))
```

添加如下 `LaTeX header` 设置 `listings` 风格：

```
#+LATEX_HEADER: \lstset{
#+LATEX_HEADER:     keywordstyle=\color{blue},
#+LATEX_HEADER:     commentstyle=\color{red},
#+LATEX_HEADER:     stringstyle=\color{green},
#+LATEX_HEADER:     basicstyle=\ttfamily\small,
#+LATEX_HEADER:     columns=fullflexible,
#+LATEX_HEADER:     basewidth={0.5em,0.4em}
#+LATEX_HEADER: }
```

最后，文档里有中文的时候：

```
#+LATEX_HEADER: \usepackage{xltxtra}
```

因为 `xltxtra` 会自动引用 `fontspec`，没有它输出的 pdf 里面中文会被过
滤掉。`xltxtra` 还定义了两个 logo: `\XeTeX` 和 `\XeLaTeX`。
