---
categories:
- linux
date: 2016-04-12T00:00:00Z
description: ""
tags:
- tmux
title: Fun with Tmux
url: /2016/04/12/fun-with-tmux/
---


Linux 环境下最喜爱的程序之一是 `tmux`，基本上它就是我的窗口管理器。
Tmux 有三个概念：`session`, `window` 和 `pane`。对比桌面环境：

1. `session` 就是一个会话，比如 GNOME session, KDE session 之类。区别
是，同时可以有多个 Tmux session，但我从来只用一个。
2. `window` 类似一个虚拟桌面。
3. `pane` 类似一个平铺的窗口，但可以水平、垂直分割。

`session` 里面有一个或多个 `window`，而 `window` 里面有一个或多个
`pane`。我有一个脚本，内容大致如下：

~~~
#!/bin/sh

tmux new-session -d -n doc -c path/to/doc
tmux new-window  -n github -c path/to/git
tmux new-window  -n dev    -c path/to/dev

tmux new-window   -n random
tmux split-window -h ssocks
tmux split-window -v tsocks

tmux select-window -t 2
tmux -2 attach-session -d -c ~
~~~

运行这个脚本就会创建一个 Tmux session，其中有四个窗口：

1. doc - 文档编辑
2. github - 参考项目代码之类
3. dev - 本地项目代码
4. random - 杂项工作

其中前三个 Window 会自动切到对应的工作目录，第四个窗口的工作目录是用户
主目录，然后里面有三个 pane，呈 `|-` 形，左边是杂项工作，右上、右下都
是为了功夫网。
