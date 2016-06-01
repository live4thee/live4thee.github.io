---
layout: post
title: "More Tmux Tips"
description: ""
category: linux
tags: [tmux]
---
{% include JB/setup %}

## Zoom State

`C-b z` 使得当前窗口最大化，其它窗口被隐藏。再按一次 `C-b z` 恢复原样。

## Detach Pane

`C-b !` (detach-pane) 使得当前窗口脱离所在，移动到新创建的 pane 中。
`join-pane` 可以把当前窗口并到指定 pane 中。
