---
title: "trace-cmd et al"
date: 2025-02-19T18:24:25+08:00
tags: [ "mm" ]
categories: [ "linux" ]
draft: false
---

`bpftrace` 固然好用，但有时候环境中没法装。此时，使用 `ftrace` 是个很
好的选择。具体做法：

- 使用 `trace-cmd`, 跟踪内核耗时是个不错的选择；
- 直接使用 `tracefs` 接口，最好对照[内核文档](https://www.kernel.org/doc/html/v4.18/trace/ftrace.html)；
- 使用 `perf ftrace`, 控制参数比 `trace-cmd` 少一点。

本文假设需要跟踪`pwritev2` 的耗时。

## perf trace

直接 `perf trace -e pwritev2` 可以看见系统调用的总耗时，但不知道耗时分布。

```sh
$ perf trace -e pwritev2
     0.000 ( 2.998 ms): demo/28317 pwritev2(fd: 3, vec: 0x7f508a374fb0, vlen: 1, pos_l: 307200, flags: 3) = 4096
     3.001 ( 0.380 ms): demo/28317 pwritev2(fd: 3, vec: 0x7f508a374fa0, vlen: 1, pos_l: 303104, flags: 3) = 4096
  1086.186 ( 0.174 ms): demo/28317 pwritev2(fd: 3, vec: 0x7f508c697fa0, vlen: 1, pos_l: 245760, flags: 3) = 4096
```

## trace-cmd

用 `trace-cmd` 可以看到内核路径的细节，包括：执行路径，路径耗时等等。

### function_graph

`trace-cmd` 的 `function_graph` 插件会打印每个子函数的耗时。

```sh
$ trace-cmd start -e sched:sched_switch \
	-p function_graph -g __x64_sys_pwritev2 \
	--max-graph-depth 4 -O funcgraph-proc
  plugin 'function_graph'
$ trace-cmd stop
$ trace-cmd show
# tracer: function_graph
#
# CPU    TASK/PID  DURATION                  FUNCTION CALLS
# |       |    |       |       |              |   |   |   |
 40) demo-5439 |               |  __x64_sys_pwritev2() {
 40) demo-5439 |               |    do_pwritev() {
 40) demo-5439 |               |      __fdget() {
 40) demo-5439 |   0.550 us    |        __fget_light();
 40) demo-5439 |   1.081 us    |      }
 40) demo-5439 |               |      vfs_writev() {
 40) demo-5439 |   0.266 us    |        rw_copy_check_uvector();
 40) demo-5439 |   0.721 us    |        __sb_start_write();
 40) demo-5439 | ! 546.045 us  |        do_iter_write();
 40) demo-5439 |   0.054 us    |        __sb_end_write();
 40) demo-5439 |   0.046 us    |        kfree();
 40) demo-5439 | ! 549.245 us  |      }
 40) demo-5439 |               |      fput() {
 40) demo-5439 |   0.049 us    |        fput_many();
 40) demo-5439 |   0.362 us    |      }
...
$ trace-cmd clear
```

也可以把跟踪的结果记录下来：

```sh
$ trace-cmd record -e sched:sched_switch \
	-p function_graph -g __x64_sys_pwritev2 \
	--max-graph-depth 4 -O funcgraph-proc
Hit Ctrl^C to stop recording
$ trace-cmd report
```

实测用 `start` 方式更可靠一点。

### osnoise

参考 [System Interrupts: How to Hunt Them
Down](https://www.jabperf.com/ima-let-you-finish-but-hunting-down-system-interrupts/).
写得非常生动活泼，只看开头会以为是娱乐贴。

```sh
$ trace-cmd start -p osnoise
  plugin 'osnoise'
$ trace-cmd stop
```

`trace-cmd` 暴露的 `ftrace` 接口不够丰富，可以直接通过 `tracefs` 的接
口操作。

```sh
$ mount -t tracefs
tracefs on /sys/kernel/debug/tracing type tracefs (rw,relatime)
$ cd /sys/kernel/debug/tracing
$ echo osnoise > current_tracer
$ echo osnoise > set_event
$ echo 1000 > osnoise/stop_tracing_us
$ echo 1 > tracing_on
$ less trace | grep fio
fio-5581 [033] 312570.340068:  thread_noise:   fio:5581 start 312570.340031168 duration 35951 ns
fio-5585 [033] 312570.340072:  thread_noise:   fio:5585 start 312570.340068089 duration 3572 ns
```

## perf ftrace

`perf ftrace` 也做了简单的集成，默认就是使用 `function_graph` 插件，输
出默认似乎会 pipe 到 `less`, 因此直接按 `q` 退出。

```sh
$ perf ftrace -G __x64_sys_pwritev2 --graph-opts depth=4
# tracer: function_graph
#
# CPU  DURATION                  FUNCTION CALLS
# |     |   |                     |   |   |   |
 41)               |  finish_task_switch() {
 41)   ==========> |
 41)               |    smp_irq_work_interrupt() {
 41)               |      irq_enter() {
 41)   0.112 us    |        irq_enter_rcu();
 41)   0.549 us    |      }
 41)               |      __wake_up() {
 41)   0.200 us    |        __wake_up_common_lock();
 41)   0.420 us    |      }
 41)               |      irq_exit() {
:
```

`smp_irq_work_interrupt()` 用来处理处理器间中断（IPI）请求。需要某个
CPU 需要处理 IRQ 工作队列中的任务时，内核会通过 IPI 向目标 CPU 发送一
个中断。目标 CPU 收到中断后，会调用 `smp_irq_work_interrupt()` 来处理
IRQ 工作队列中的任务。
