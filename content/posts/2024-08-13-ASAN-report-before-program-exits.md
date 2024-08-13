---
title: "ASAN Report Before Program Exits"
date: 2024-08-13T10:40:48+08:00
tags: [ "c++" ]
categories: [ "programming" ]
draft: false
---

[Address Sanitizer](https://github.com/google/sanitizers/wiki/AddressSanitizer)
(ASAN) 是个非常好用的工具，其子集 Leak Sanitizer (LSAN) 也非常好用。用
GCC 编译的时候：[^fn1]

```sh
 -fsanitize=address  # 启用 ASAN
 -fsanitize=leak     # 启用 LSAN
```

现实应用中，很多业务都以守护进程 daemon 的形式运行，因此进程退出才输出
报告就显得不太合适。如果能按需触发式生成报告就会比较方便，解决办法也比
较简单：比如注册一个信号处理函数，调用 LSAN 接口生成报告。[^fn2]

```c
#include <signal.h>
#include <sanitizer/lsan_interface.h>  // from libgcc-devel

static void signalHandlerSigCont(int signo) {
    __lsan_do_recoverable_leak_check();
}

// setup up the signal handler somewhere
// signal(SIGCONT, signalHandlerSigCont);
```

通过环境变量指定日志文件的位置，然后运行即可。

```sh
$ LSAN_OPTIONS=log_path=/path/to/my/lsan-report.log /path/to/my/app ...
```

更多实用的控制参数：[^fn3]

```sh
# 如果编译时用了 -fomit-frame-pointer 导致 unwind 报错，
# 可以使用稍慢但是更鲁棒的 DWARF unwinder:
# Or LSAN_OPTIONS, if you use standalone LSAN
export ASAN_OPTIONS=fast_unwind_on_malloc=0

# 遇错不退出应用
# Or LSAN_OPTIONS, if you use standalone LSAN
export ASAN_OPTIONS=exitcode=0:...
```

[^fn1]: 更多 sanitize 选项，见[GCC 手册](https://gcc.gnu.org/onlinedocs/gcc/Instrumentation-Options.html)。
[^fn2]: 该方案来自：https://github.com/google/sanitizers/issues/1386
[^fn3]: 参考：https://stackoverflow.com/questions/46575977
