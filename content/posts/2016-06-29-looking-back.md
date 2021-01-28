---
categories:
- life
date: 2016-06-29T00:00:00Z
description: ""
tags:
- startup
title: Looking Back
url: /2016/06/29/looking-back/
---


## Number of Code Commits

今天是加入创业整整三个月。除去清明、五一以及端午加上自己请假，一共休息
了两个礼拜，实际为两个半月。其间 `Java` 代码相关的改动提交了 `46` 个，
`Python`相关 `16` 个，`Golang` 最多，为 `162` 次。统计方法也很简单：

```
$ for r in $repos; do
    cd $r
    git log --since '3 months ago' --author live4thee | grep -c ^commit
    cd - > /dev/null
done
```

## Number of Notes

笔记一共记了两千多行 - 但因为是用 `Emacs` + `orgmode`，且打开了
`auto-fill` 做自动换行，所以每行字数很少。英文本身也会比汉字用字多一点。

```
$ wc -l *.org | tail -1
2209
```

## The Good and The Bad

为小伙伴们做了一次 tech-talk，一次 demo -- 然而工作进度却`拖延了两次`。
这在过去将近 9 年的职业生涯内，应该是从未有之。知耻而后勇。

## Misc.

一个月前关闭了微信朋友圈 - 自己可以发更新，却不会收到朋友的状态更新。
(这种行为有点像曹操的某个名言 -_-） 嗯，偶尔也会打开刷一刷。
