+++
title = "Buffering"
description = ""
date = "2018-05-18T20:47:37+08:00"
tags = ["golang"]
categories = ["programming"]
+++

最近碰到一个行缓冲(line buffering)方面的问题，有点意思。

## 背景

某段 `golang` 代码中，需要解析 `virsh event --loop` 的输出，大概就是用
`bufio` 里的 `Scanner` 来按行读取外部命令的输出。然而郁闷的是，代码里
啥都读不到，除非 `virsh` 进程终止（间接地关闭了输出）。

明显这是缓存的原因，而印象中，输出字符中包含 `\n` 时，会自动 flush 缓存。

## 重现未果

先写了个简单的 `golang` 程序，用来模拟输出行为：

```go
package main

import (
	"fmt"
	"time"
)

func main() {
	for i := 0; i < 5; i++ {
		fmt.Printf("hello\n")
	}

	time.Sleep(2 * time.Second)
}
```

运行 `go run test.go | cat`，发现五个 `hello` 一下子全打印了出来。

## 再次重现

想着 `virsh` 是用 C 写的，查到 `libvirt` 的源代码里面，这里用的是
`fputs`，因此又写了一段 C 代码试验：

```c
#include <stdio.h>
#include <unistd.h>

int main(void) {
	for (int i = 0; i < 5; ++i) {
		fputs("hello\n", stdout);
	}

	sleep(2);
	return 0;
}
```

运行 `gcc test.c -o t2; ./t2 | cat`，五个 `hello` 在两秒之后才打印出来。

## 对比

用 `strace` 对比一下两者的区别：

```sh
$ go build test.go
$ strace -ewrite -o x.txt ./test | cat
hello
hello
hello
hello
hello
$ cat x.txt
write(1, "hello\n", 6)                  = 6
write(1, "hello\n", 6)                  = 6
write(1, "hello\n", 6)                  = 6
write(1, "hello\n", 6)                  = 6
write(1, "hello\n", 6)                  = 6
+++ exited with 0 +++

$ strace -ewrite -o x.txt ./t2 | cat
hello
hello
hello
hello
hello
$ cat x.txt
write(1, "hello\nhello\nhello\nhello\nhello\n", 30) = 30
+++ exited with 0 +++
```

原来 `golang` 版本里面的输出没有缓冲，而 C 版本的有缓冲。

## 换行缓冲

`man 3 setbuf` 查到如下信息：

    when it is line buffered characters are saved up until a newline
	is output or input is read from any stream attached to a terminal
	device (typically stdin).

原来换行时自动缓冲是对输出是终端设备的时候才生效。
[这里](https://stackoverflow.com/questions/1716296)把这个问题解释得很
清楚。

## 解决办法

`GNU coreutils` 提供了一个命令 `stdbuf` 来设置被运行程序的行缓冲。

```sh
$ stdbuf -o 0 command
```

这样，`command` 运行时的标准输出就会取消行缓冲。
