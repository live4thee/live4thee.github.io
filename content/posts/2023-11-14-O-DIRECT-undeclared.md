+++
title = "`O_DIRECT' undeclared"
date = 2023-11-14T15:08:58+08:00
tags = ["c++"]
categories = ["work"]
draft = false
+++

用 gcc 编译代码时报错：`'O_DIRECT' undeclared`. 看操作历史，之前一直用
的 g++ 没报错。感觉有点奇怪。加上参数 `-E` 导出预处理过程对比了一下：
处理的文件都一样，但预处理的结果不一样。那就是 gcc 和 g++ 默认预定义的
宏有区别了。

看了一下头文件：

```c
/* file: /usr/include/bits/fcntl-linux.h */
#ifdef __USE_GNU
# define O_DIRECT   __O_DIRECT   /* Direct disk access.  */
# define O_NOATIME  __O_NOATIME  /* Do not set atime.  */
# define O_PATH     __O_PATH     /* Resolve pathname but do not open file.  */
# define O_TMPFILE  __O_TMPFILE  /* Atomically create nameless file.  */
#endif
```

原来 `O_DIRECT` 这些宏不是标准宏。看看 gcc 和 g++ 各自的预定义宏：

```sh
$ gcc -E -xc -dM /dev/null | grep GNU
#define __GNUC_PATCHLEVEL__ 0
#define __GNUC__ 8
#define __GNUC_RH_RELEASE__ 21
#define __GNUC_STDC_INLINE__ 1
#define __GNUC_MINOR__ 5

$ g++ -E -xc++ -dM /dev/null | grep GNU
#define __GNUC_PATCHLEVEL__ 0
#define __GNUC__ 8
#define __GNUG__ 8
#define __GNUC_RH_RELEASE__ 21
#define __GNUC_STDC_INLINE__ 1
#define __GNUC_MINOR__ 5
#define _GNU_SOURCE 1
```

虽然没有 `__USE_GNU` 但是明显 g++ 预定义了 `_GNU_SOURCE` 而 gcc 没有。
在 `man (2) open` 中反查 `_GNU_SOURCE`，看到 `STANDARDS` 一节写到：

```text
STANDARDS
  open(), creat() SVr4, 4.3BSD, POSIX.1-2001, POSIX.1-2008.
  
  openat(): POSIX.1-2008.
  
  The O_DIRECT, O_NOATIME, O_PATH, and O_TMPFILE flags are Linux-specific.  One must define
  _GNU_SOURCE to obtain their definitions.
```

也就是说，`O_DIRECT`, `O_NOATIME`, `O_PATH` 以及 `O_TMPFILE` 是特定于
Linux 的宏定义。要想使用这些宏，需要先定义 `_GNU_SOURCE`.

再 `grep -r '#if.*_GNU_SOURCE' /usr/include/` 可以看到一个头文件
`/usr/include/features.h`.  查看其内容，果然有：

```c
#ifdef  _GNU_SOURCE
# define __USE_GNU    1
#endif
```
