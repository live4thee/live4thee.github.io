---
layout: post
title: "Debugging Go Programs"
description: ""
category: programming
tags: [golang]
---
{% include JB/setup %}

调试 golang 程序的体验不是很好，虽然很多时候加一些打印语句也能解决问题。

## gdb

- 设置 gdb 的启动脚本，以正确解析符号（以前开发 SGX SDK 的时候也干过）。

~~~
add-auto-load-safe-path /usr/share/go-1.6/src/runtime/runtime-gdb.py
~~~

- 在需要断点的地方加上 `runtime.Breakpoint()` 触发断点。
- 编译的时候关闭內联等 `go build -gcflags "-N -l"`。

## godebug

这个不依赖 gdb，是个可移植的方案。但是比较若，没有 `stepin` 之类。

- 安装之 `go get github.com/mailgun/godebug`
- 在需要断电的地方加上 `_ = "breakpoint"`
- `godebug run file` 启动之，如果断点不在 `main` 包里面，则很恶心：
- `godebug run -instrument=pkg1,pkg2,... file` 其中 `pkg1` 等等是断点
  所在的包的全名。

都需要改源代码，略矬。
