+++
title = "Interpreting Linux OOM Logs (1/2)"
description = ""
date = "2019-04-12T10:28:42+08:00"
tags = ["mm"]
categories = ["linux"]
+++

本文描述如何分析 Linux OOM 日志。下面的日志去掉了开头的时间戳。

```text
HOST1 kernel: prometheus invoked oom-killer: gfp_mask=0x0, order=0, oom_score_adj=0
HOST1 kernel: prometheus cpuset=docker-f55e8d749684a0746aa1cb3d186df370848ba502cc19d249bf732450de5a2f30.scope mems_allowed=0-3
HOST1 kernel: CPU: 88 PID: 49521 Comm: prometheus Tainted: G           OE  ------------   3.10.0-327.36.1.el7.x86_64 #1
HOST1 kernel: Hardware name: Dell Inc. PowerEdge R930/0Y0V4F, BIOS 2.4.3 07/07/2017
HOST1 kernel: ffff88bf0612f300 00000000cbfaa699 ffff88ff0e857ce0 ffffffff81636301
HOST1 kernel: ffff88ff0e857d70 ffffffff8163129c 0000000000000297 ffff88ff0e857db0
HOST1 kernel: 0000000000000001 00000000fc107000 0000000000000001 0000000000000010
HOST1 kernel: Call Trace:
HOST1 kernel: [<ffffffff81636301>] dump_stack+0x19/0x1b
HOST1 kernel: [<ffffffff8163129c>] dump_header+0x8e/0x214
HOST1 kernel: [<ffffffff8116d21e>] oom_kill_process+0x24e/0x3b0
HOST1 kernel: [<ffffffff8116cd86>] ? find_lock_task_mm+0x56/0xc0
HOST1 kernel: [<ffffffff8116da46>] out_of_memory+0x4b6/0x4f0
HOST1 kernel: [<ffffffff8116daf1>] pagefault_out_of_memory+0x71/0x90
HOST1 kernel: [<ffffffff8162f6e5>] mm_fault_error+0x68/0x12b
HOST1 kernel: [<ffffffff81642192>] __do_page_fault+0x3e2/0x450
HOST1 kernel: [<ffffffff81642223>] do_page_fault+0x23/0x80
HOST1 kernel: [<ffffffff8163e508>] page_fault+0x28/0x30
```

第一行表明 OOM 发生在 prometheus 申请内存失败，触发了 oom-killer。后面
有三个值：*gfp_mask*, *order* 以及 *oom_score_adj*.

## *gfp_mask*, *order* and *oom_score_adj*

### *gfp_mask*

代表申请内存时候的参数。

```c
// c.f. include/linux/gfp.h
/* Plain integer GFP bitmasks. Do not use this directly. */
#define ___GFP_DMA              0x01u
#define ___GFP_HIGHMEM          0x02u
#define ___GFP_DMA32            0x04u
#define ___GFP_MOVABLE          0x08u
#define ___GFP_RECLAIMABLE      0x10u
#define ___GFP_HIGH             0x20u
...
```

### *order*

如果是 -1 的话，代表 OOM 是通过
[SysRq](https://www.kernel.org/doc/html/latest/admin-guide/sysrq.html)
触发。

这里是 0，我们得到 2 ^^ 0 = 1，也就是请求分配 1 页（或者更多）。

```c
// c.f. include/linux/oom.h
/*
 * order == -1 means the oom kill is required by sysrq, otherwise only
 * for display purposes.
 */
const int order;
```

### *oom_score_adj*

代表进程的 badness score 的调整值。

OOM killer 选择被杀进程时，会把这个调整值加到进程的 badness score 上作
为最终的分值。这个调整值的取值范围是 -1000 (*OOM_SCORE_ADJ_MIN*) 到
1000 (*OOM_SCORE_ADJ_MAX*)。进程的 badness 分值越高越容易被杀死。

```sh
$ cat /proc/$$/oom_score
0
$ cat /proc/$$/oom_score_adj
0
```

此外，我们还看到了进程对应的 CPU 编号，进程号，内核版本以及硬件描述等
信息。

## 内存信息

OOM killer 杀掉进程（如下，19434）之前，会打印出系统的进程信息。其中，
内存占用是以页（默认 4 kB）为单位的，比如：

```text
HOST1 kernel: [ 2535]     0  2535    29188 ...
```

这里的 29188 是指 29188 * 4 kB.

```text
HOST1 kernel: Mem-Info:                                                                                                                                                                     HOST1 kernel: Node 0 DMA per-cpu:
HOST1 kernel: CPU    0: hi:    0, btch:   1 usd:   0
HOST1 kernel: CPU    1: hi:    0, btch:   1 usd:   0
HOST1 kernel: CPU    2: hi:    0, btch:   1 usd:   0
HOST1 kernel: CPU    3: hi:    0, btch:   1 usd:   0
...
HOST1 kernel: active_anon:136788940 inactive_anon:627992 isolated_anon:0#012
 active_file:6127082 inactive_file:8045807 isolated_file:0#012
 unevictable:1832 dirty:187 writeback:16 unstable: 0#012
 free:104942660 slab_reclaimable:4803157 slab_unreclaimable:257603#012
 mapped:1804194 shmem:1395209 pagetables:297437 bounce:0#012
 free_cma:0
...
HOST1 kernel: 15569613 total pagecache pages
HOST1 kernel: 0 pages in swap cache
HOST1 kernel: Swap cache stats: add 0, delete 0, find 0/1
HOST1 kernel: Free swap  = 4194300kB
HOST1 kernel: Total swap = 4194300kB
HOST1 kernel: 268408898 pages RAM
HOST1 kernel: 0 pages HighMem/MovableOnly
HOST1 kernel: 4261955 pages reserved
HOST1 kernel: [ pid ]   uid  tgid total_vm      rss nr_ptes swapents oom_score_adj name
HOST1 kernel: [ 1922]     0  1922    45185    26567      90        0             0 systemd-journal
HOST1 kernel: [ 1950]     0  1950    10973      461      21        0         -1000 systemd-udevd
HOST1 kernel: [ 2579]    81  2579     6686      479      17        0          -900 dbus-daemon
HOST1 kernel: [ 2604]     0  2604     4952      458      13        0             0 irqbalance
HOST1 kernel: [ 3359]     0  3359    20641      898      42        0         -1000 sshd
HOST1 kernel: [19434]     0 19434  8729888  8434255   16732        0             0 xxxx
...
HOST1 kernel: Out of memory: Kill process 19434 (xxxx) score 31 or sacrifice child                                                                                                      HOST1 kernel: Killed process 19434 (xxxx) total-vm:34919552kB, anon-rss:33698680kB, file-rss:38340kB
```

### *pid* and *tgid*

pid 是指 process id，而 tgid 是指 thread group id。这个涉及到 Linux 的
线程模型和调度模型。下面一张
[图](https://stackoverflow.com/questions/9305992)很好的解释了两者的关
系。

```text
                      USER VIEW
 <-- PID 43 --> <----------------- PID 42 ----------------->
                     +---------+
                     | process |
                    _| pid=42  |_
                  _/ | tgid=42 | \_ (new thread) _
       _ (fork) _/   +---------+                  \
      /                                        +---------+
+---------+                                    | process |
| process |                                    | pid=44  |
| pid=43  |                                    | tgid=42 |
| tgid=43 |                                    +---------+
+---------+
 <-- PID 43 --> <--------- PID 42 --------> <--- PID 44 --->
                     KERNEL VIEW
```

### *total_vm* and *rss*

*total_vm* 即进程已经申请的虚拟内存总大小。*rss* 是驻留在内存页数。

这里我们看到进程 19434 被杀掉了。被杀掉前，它占用的虚拟内存是
8729888 * 4 kB，34 GB 多一点。占用的物理内存是 8434255 * 4 kB，差不多
33 GB。OOM 之前，系统总的页数：268408898，可用页数：104942660，占比
39.1%。

那么问题来了，为啥会发生 OOM 呢？毕竟 free 还剩下将近 40%.
