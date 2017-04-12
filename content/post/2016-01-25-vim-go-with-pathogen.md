---
categories:
- vim
date: 2016-01-25T00:00:00Z
description: ""
tags:
- vim
- golang
title: vim-go with pathogen
url: /2016/01/25/vim-go-with-pathogen/
---


本地的 Fedora 虚拟机里面设置了用`pathogen`加载`vim-go`，一直工作得很好。
而我远程一台 Ubuntu 14.04 LTS 则不工作，虽然`.vimrc`的内容一模一样，且
`pathogen`和`vim-go`的版本也一样。命令模式下`gd`没有调用到`:GoDef`。

解决的办法[^1]是在 `call pathogen#infect()` 之后加上如下：

~~~
filetype off
syntax on
filetype plugin indent on
~~~

貌似是因为调用 `pathogen` 之前执行了 `filetype on`，但 Stackoverflow
上的一则问答[^2]说，`pathogen#infect()`应该解决了这个问题。

[^1]: [A Brief Note On Pathogen For Vim](http://blog.darevay.com/2010/10/a-brief-note-on-pathogen-for-vim/)
[^2]: [Pathogen does not load plugins](https://stackoverflow.com/questions/3383502/pathogen-does-not-load-plugins)
