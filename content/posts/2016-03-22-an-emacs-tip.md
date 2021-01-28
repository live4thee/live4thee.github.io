---
categories:
- emacs
date: 2016-03-22T00:00:00Z
description: ""
tags:
- orgmode
title: An Emacs Tip
url: /2016/03/22/an-emacs-tip/
---


用 orgmode 写完文档后，`C-x C-c` 提示退出失败，出错信息为：
`eshell-save-some-history: Text is read-only`. 切换到 `eshell buffer`
后输入 `exit`，果然又提示了同样的错误。保存并关闭编辑好的文件后，还是
不能成功退出。输入并执行 `(setq eshell-save-history-on-exit nil)`，然
后一切都好了。
