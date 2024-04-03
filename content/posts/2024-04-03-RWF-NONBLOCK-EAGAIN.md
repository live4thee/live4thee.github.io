---
title: "RWF_NONBLOCK & EAGAIN"
date: 2024-04-03T17:56:12+08:00
tags: [ "storage" ]
categories: [ "linux" ]
draft: false
---

通过 Linux AIO 做 non_blocking IO, 碰到一个奇怪的问题，记录一下。
I/O 面向的是 Ext4 文件系统，而不是块。

## RWF_NOWAIT

**RWF_NOWAIT** 的语义在 *io_submit(2)* 里有描述，libaio 的测试用例中也
包含了相关描述。大意相同，也就是 *io_getevents(2)* 的 *event.res* 字段
为 *EAGAIN* 的若干可能如下：

```c
  * RWF_NOWAIT will cause -EAGAIN to be returned in the io_event for
  * any I/O that cannot be serviced without blocking the submission
  * thread.  Instances covered by the kernel at the time this test was
  * written include:
  * - O_DIRECT I/O to a file offset that has populated page cache pages
  * - the submission context cannot obtain the inode lock
  * - space allocation is necessary
  * - we need to wait for other I/O (e.g. in the misaligned I/O case)
  * - ...
```

## 神奇的 EAGAIN

加了日志，基本上排除了对应上面若干条目的场景，但是还是得到了 EAGAIN.

- 测试应用放在 Debian 12 容器跑在 CentOS 8 上，得到 EAGAIN. 宿主机的
  bpftrace 得到 -529;
- 测试应用跑在 CentOS 8 虚拟机，不会 EAGAIN. 此时，bpftrace 也得到 -529.
- 测试应用跑在 Debian 12 物理机，得到 EAGAIN. 此时，bpftrace 得到 -11.

## 神奇的 -529

-11 代表 -EAGAIN. 但是 -529 是怎么来的呢？

```sh
$ bpftrace -e 'kretprobe:generic_file_direct_write,\
    kretprobe:ext4_file_write_iter\
    {printf("%-6d %-16s: %d [%s]\n", pid, comm, retval, probe);}'
685053 aio-test        : -529 [kretprobe:generic_file_direct_write]
685053 aio-test        : -529 [kretprobe:ext4_file_write_iter]
```

## trace-cmd

在 F 老师的帮助下，用 trace-cmd 生成了内核执行路径。待分析。
