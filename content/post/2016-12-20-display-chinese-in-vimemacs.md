---
date: 2016-12-20T00:00:00Z
description: ""
tags:
- vim
- misc
title: Display Chinese in Vim/Emacs
url: /2016/12/20/display-chinese-in-vimemacs/
---


碰到一个问题，某个 TXT 文件用 Vim/Emacs 打开均为乱码。`vim` 下修改一下
配置即可：

`set fileencodings=utf-8,cp936` 改为 `set fileencodings=utf-8,gb18030`

`cp936` 是微软的简体中文字符集标准，几乎等同于 `GB 2312`。现在中国大陆
强制要求所有软件皆要支持 `GB 18030`。

Emacs 下面可以 `M-x revert-buffer-with-coding-system` 修改当前缓冲区的
字符编码。

<!--{:.table-bordered}-->

 快捷键   | 命令
----------|------
C-x RET r | revert-buffer-with-coding-system
C-x RET f | set-buffer-file-coding-system
C-x RET c | universal-coding-system-argument
C-u C-x = | describe-char
C-h C     | describe-coding-system
