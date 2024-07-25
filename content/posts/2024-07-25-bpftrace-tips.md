---
title: "bpftrace Tips"
date: 2024-07-25T18:39:04+08:00
tags: [ "mm" ]
categories: [ "linux" ]
draft: false
---

## bpftrace 的一些陷阱

### "char[]" 的问题

举个例子，`xfs_lookup` 对应 `tracepoint` 中的第四个参数 `name` 被声明
为 `char[]` 而不是 `char*`. 这在 C 里面没有区别，而在 `bpftrace` 里面
却有明显的区别。

```sh
$ bpftrace -lv tracepoint:xfs:xfs_lookup
tracepoint:xfs:xfs_lookup
    dev_t dev
    xfs_ino_t dp_ino
    int namelen
    __data_loc char[] name
```

如果 `name` 并不是 ASCII 字符串，里面其实存放的是字符对应的 16进制值（比如，
`A` 对应的值存放了 `0x10`  而不是 `0x41`），则用 `%s` 输出就会碰到“意外”。
这在输出 `uuid` 的时候特别容易碰到。

> bpftrace treats `char *` and `char []` differently, and the type of
> former is `Type::integer` and the latter is `Type::string`.

对于 `Type::string`, 无法用 `[]` 的形式访问其中的单个字符。

```sh
$ bpftrace -e 'BEGIN{ $s = "hello"; printf("%s\n", $s[0]);}'
...
stdin:1:22-43: ERROR: printf: %s specifier expects a value of type string (none supplied)
```

同时，对于一个 `Type::string`，也不能用 `str()` 函数做转换（因为本来就
是 `string`）。

```sh
$ bpftrace -e 'BEGIN{ $s = "hello"; printf("%s\n", str($s));}'
stdin:1:37-44: ERROR: str() expects an integer or a pointer type as first argument (string[6] provided)
```

以上问题可以参考 [GitHub issue #1010](https://github.com/bpftrace/bpftrace/issues/1010)

### '%r' raw 输出

如果 `char[]` 确实包含非 ASCII 编码，又实在想查看里面的内容，可以试试：

```sh
$ bpftrace -e ... '{printf("%r\n", buf(args->uuid, 16));}'
\xa7\xdc\xf3\x1e\xe1\x14\x11\xee\xb0H\xb4\x05]\xad\x1f\
```

里面除了正常的 `\xa7` 等等，还会出来 `H` & `]`. 这也是个现有问题，高版
本的 `bpftrace` 可以通过 `%rx` 来解决，见 [GitHub issue #2009](https://github.com/bpftrace/bpftrace/issues/2009).

### 字符串查找

高版本的 bpftrace 有新 built-in 函数 `strcontains`，老版本只能 `strncmp`.

### ustack() 打印的堆栈只有地址没有符号

那是因为被跟踪的进程先退出了。bpftrace 跟踪结束的时候，保证待跟踪进程
还在就行。
