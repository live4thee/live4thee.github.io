+++
title = "Syscalls by Process"
date = 2021-02-02T12:37:02+08:00
tags = ["sysadmin"]
categories = ["linux"]
draft = false
+++

自 Linux 2.6.27 开始，可以通过文件 `/proc/[pid]/syscall` 得知进程号为
`pid` 的进程正在做什么系统调用。比如：

```sh
$ sudo cat /proc/$$/syscall
61 0xffffffff 0x7ffddd4c4000 0xa 0x0 0x0 0x7 0x7ffddd4c3fe8 0x7ff09ab37dba 
```

这里，第一个字段是系统调用号。后面一次是系统调用的第一、二...个参数。

```sh
$ echo '#include <asm/unistd.h>' | gcc -dM -E - | grep -w 61
#define __NR_wait4 61
```

第一个参数 61 代表了系统调用 `wait4`，结合 `wait4`的原型：

```c
pid_t wait4(pid_t pid, int *wstatus, int options, struct rusage *rusage);
```

- 第一个参数 `0xffffffff`（-1），就是等待任意子进程；
- 第二个参数 `0x7ffddd4c4000` 是子进程的返回状态的存放地址；
- 第三个参数，`0xa` 应该是 `WUNTRACED|WCONTINUED`；
- 第四个参数，`0` 代表空指针。

需要注意的是，Linux 中 x86_32  和 x86_64 的系统调用号是不一样的。

```sh
$ echo '#include <asm/unistd.h>' | gcc -D__i386__ -dM -E - | grep __NR_wait4
#define __NR_wait4 114
```

如果想查看进程是否等待在 mutex 上，x86_64 上只需要查找系统调用号为 202
`(__NR_futex)`，且 `futex_op` 为 `FUTEX_WAIT`(0) 的记录即可。

```sh
$ sudo cat /proc/$pid/syscall | awk '$1 == 202 && $3 == "0x0"'
```
