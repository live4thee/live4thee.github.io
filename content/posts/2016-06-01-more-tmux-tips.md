---
categories:
- linux
date: 2016-06-01T00:00:00Z
description: ""
tags:
- tmux
title: More Tmux Tips
url: /2016/06/01/more-tmux-tips/
---


## Zoom State

`C-b z` 使得当前窗口最大化，其它窗口被隐藏。再按一次 `C-b z` 恢复原样。

## Detach Pane

`C-b !` (detach-pane) 使当前窗口脱离所在 pane，移动到新创建的 pane 中。
反之，`join-pane` 可以把当前窗口合并到指定 pane 中。
