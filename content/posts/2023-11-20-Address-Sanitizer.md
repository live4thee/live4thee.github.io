+++
title = "Address Sanitizer"
date = 2023-11-20T15:14:30+08:00
tags = ["c++"]
categories = ["address"]
draft = false
+++

N 年前，调试 C/C++ 内存问题一般会选择用
[valgrind](https://valgrind.org/) 或者
[efence](https://github.com/CheggEng/electric-fence). 目前 [Address
Sanitizer (ASan)](https://code.google.com/p/address-sanitizer/) 居多，
它已经被集成进了 LLVM 以及 GCC, 用来比较方便。

---

## 访问越界

比如，下面的代码：

```c
int main() {
    int a[2] = {1, 0};
    return a[2];
}
```

编译运行之：[^static]

```sh
$ gcc -fsanitize=address -ggdb -o t1 t1.c
$ ./t1
==1057331==ERROR: AddressSanitizer: stack-buffer-overflow on address 0x7ffd3ddaa1d8 at pc 0x00000040091d bp 0x7ffd3ddaa1a0 sp 0x7ffd3ddaa190
READ of size 4 at 0x7ffd3ddaa1d8 thread T0
	#0 0x40091c in main /data/t1.c:3
	#1 0x7f24e38bed84 in __libc_start_main (/lib64/libc.so.6+0x3ad84)
	#2 0x40073d in _start (/data/t1+0x40073d)

Address 0x7ffd3ddaa1d8 is located in stack of thread T0 at offset 40 in frame
	#0 0x400805 in main /data/t1.c:1

  This frame has 1 object(s):
	[32, 40) 'a' <== Memory access at offset 40 overflows this variable
HINT: this may be a false positive if your program uses some custom stack unwind mechanism or swapcontext
	  (longjmp and C++ exceptions *are* supported)
SUMMARY: AddressSanitizer: stack-buffer-overflow /data/t1.c:3 in main
```

还会额外打印堆栈的详细信息，就不贴了。[^fn1]

## Use after free()

比如，下面的代码：

```c
#include <stdlib.h>

int main() {
    int* p = malloc(16);
    free(p);
    return *p;
}
```

编译运行之：

```sh
$ gcc -fsanitize=address -ggdb -o t2 t2.c
==1057418==ERROR: AddressSanitizer: heap-use-after-free on address 0x602000000010 at pc 0x0000004007df bp 0x7ffc2c7dfb70 sp 0x7ffc2c7dfb60
READ of size 4 at 0x602000000010 thread T0
	#0 0x4007de in main /data/t2.c:6
	#1 0x7ff86c881d84 in __libc_start_main (/lib64/libc.so.6+0x3ad84)
	#2 0x4006cd in _start (/data/t2+0x4006cd)

0x602000000010 is located 0 bytes inside of 16-byte region [0x602000000010,0x602000000020)
freed by thread T0 here:
	#0 0x7ff86ccfb7f0 in __interceptor_free (/lib64/libasan.so.5+0xef7f0)
	#1 0x4007a7 in main /data/t2.c:5
	#2 0x7ff86c881d84 in __libc_start_main (/lib64/libc.so.6+0x3ad84)

previously allocated by thread T0 here:
	#0 0x7ff86ccfbbb8 in __interceptor_malloc (/lib64/libasan.so.5+0xefbb8)
	#1 0x400797 in main /data/t2.c:4
	#2 0x7ff86c881d84 in __libc_start_main (/lib64/libc.so.6+0x3ad84)

SUMMARY: AddressSanitizer: heap-use-after-free /data/t2.c:6 in main
```

## Memory Leak

也就是光分配、不释放。这里就不贴示例了。[^fn2]

## 标记某个函数不进行分析

```c
__attribute__((no_sanitize_address)
```

## ASAN_OPTIONS

发现问题时，立刻终止进程：

```sh
$ export ASAN_OPTIONS='abort_on_error=1'
```

更多编译时、运行时控制选项，参考[文档](https://github.com/google/sanitizers/wiki/AddressSanitizerFlags)。

[^static]: 默认动态链接 libasan, 可以加 '-static-libasan' 指定静态链接 asan.
[^fn1]: 参考 https://fuzzing-project.org/tutorial2.html
[^fn2]: 参考 https://www.osc.edu/resources/getting_started/howto/howto_use_address_sanitizer
