+++
categories = ["life"]
date = "2017-04-13T20:56:03+08:00"
description = ""
tags = ["jekyll"]
title = "Jekyll to Hugo"
url = "/2017/04/13/Jekyll-to-Hugo/"
+++

花了点时间从 [Jekyll](http://jekyllbootstrap.com/) 切换到了
[Hugo](https://gohugo.io/)，好处是：不用维护一个 `Ruby` 环境，这样可以
方便的写笔记，而不用太关心平台问题。

又写了一个简单的脚本自动创建新帖子：

```
#!/usr/bin/env bash

set -e

: ${BLOGDIR:=$HOME/Documents/git-repos/live4thee.github.com}
: ${HUGOCMD:=$HOME/bin/hugo}

test -d $BLOGDIR || ( echo "$BLOGDIR not accessible"; exit 1 )
test -x $HUGOCMD || ( echo "$HUGOCMD not accessible"; exit 1 )
test $# -eq 1 || ( echo usage: $(basename "$1") post-name; exit 1 )

pname=$(echo "$1" | sed 's/[^a-zA-Z0-9]/-/g')
pname=$(printf "%s-%s.md" $(date +"%Y-%m-%d") "$pname")

cd "$BLOGDIR"; $HUGOCMD new "post/$pname"
```
