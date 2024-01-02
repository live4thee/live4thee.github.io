+++
title = "Interpreting Kernel Call Trace"
date = 2024-01-02T16:54:12+08:00
tags = ["mm"]
categories = ["linux"]
draft = false
+++

假设有 `Call Trace` 如下：

```text
[89580.077835] task:kworker/u195:0  state:D stack:  0 pid:9848 ppid:  2   flags:0x80004080
[89580.077840] Workqueue: events_unbound async_run_entry_fn
[89580.077845] Call Trace:
[89580.077847]  __schedule+0x2d1/0x860
[89580.077852]  ? scan_shadow_nodes+0x30/0x30
[89580.077856]  schedule+0x35/0xa0
[89580.077857]  io_schedule+0x12/0x40
[89580.077859]  do_read_cache_page+0x4eb/0x740
```

上面这段日志是由 `kernel/sched/core.c` 中的 `sched_show_task()` 函数打印的。

## 任务信息

```text
task:kworker/u195:0  state:D stack:    0 pid:9848 ppid:     2 flags:0x80004080
```

- task: 任务（进程）名
- state: 进程状态
- stack: 剩余栈容量
- pid: 进程号
- ppid: 父进程号
- flags: Thread Info Flags

剩余的栈容量需要打开 `CONFIG_DEBUG_STACK_USAGE`，否则就是 0. #2 进程是 `kthreadd`.

### 任务名

这里的 `kworker/u195:0` 是任务名。`kworker` 其实有两种任务名，分别是：
`kworker/%u:%d%s (cpu, id, priority)` 以及 `kworker/u%u:%d (pool_id, id)`.

```c
/* file: kernel/workqueue.c */
static struct worker *create_worker(struct worker_pool *pool)
{
	/* ... code snippet below */
    if (pool->cpu >= 0)
        snprintf(id_buf, sizeof(id_buf), "%d:%d%s", pool->cpu, id,
                 pool->attrs->nice < 0  ? "H" : "");
        else
            snprintf(id_buf, sizeof(id_buf), "u%d:%d", pool->id, id);
}
```

这里 `u195` 有前缀 `u` 说明该 `worker` 没有绑定 CPU.

### 任务状态

任务状态和 TOP(1) 是一样的。

```text
D = uninterruptible sleep
I = idle
R = running
S = sleeping
T = stopped by job control signal
t = stopped by debugger during trace
Z = zombie
```

### 任务线程标志

`TIF (Thread Info Flags)` 获取自 `task_thread_info(task)->flags`, 是个
平台相关的字段。`0x80004080` 对应置位的是 bit7, bit14, bit31.[^tif] 对比该字
段在 x86 上的定义：

```c
/* file: arch/x86/include/asm/thread_info.h */
#define TIF_SYSCALL_TRACE       0       /* syscall trace active */
#define TIF_NOTIFY_RESUME       1       /* callback before returning to user */
#define TIF_SIGPENDING          2       /* signal pending */
#define TIF_NEED_RESCHED        3       /* rescheduling necessary */
#define TIF_SINGLESTEP          4       /* reenable singlestep on user return*/
#
/* ... */
```

## Worker 信息

该行并不总是出现在 Call Trace 记录里。从内核代码 `print_worker_info()` 可以看到：

```c
/* file: kernel/workqueue.c */
void print_worker_info(const char* log_lvl, struct task_struct *task)
{
    /* ... */
    if (!task->flags & PF_WQ_WORKER))
        return;
}
```

因此，如果进程的任务状态没有标记 `PF_WQ_WORKER` 就直接返回了。可惜
`Call Trace` 记录中没有 `task->flags`，只能从 crash dump 里获取。

```sh
crash> struct -x task_struct.flags ff450cf347274000
  flags = 0x4208060,
```

### 任务标志

可以看到这里 `task->flags` 为 `0x404100`，而 TIF 是 0x80004080. 前者是
平台无关的，后者是平台相关的。任务标志定义如下：

```c
/* file: include/linux/sched.h */
#define PF_IDLE                 0x00000002      /* I am an IDLE thread */
#define PF_EXITING              0x00000004      /* Getting shut down */
#define PF_VCPU                 0x00000010      /* I'm a virtual CPU */
#define PF_WQ_WORKER            0x00000020      /* I'm a workqueue worker */
#define PF_FORKNOEXEC           0x00000040      /* Forked but didn't exec */
#define PF_MCE_PROCESS          0x00000080      /* Process policy on mce errors */
#define PF_SUPERPRIV            0x00000100      /* Used super-user privileges */
#define PF_DUMPCORE             0x00000200      /* Dumped core */
/* ... */
```

这里 `0x4208060 & PF_WQ_WORKER` 为真，因此会打印 worker 信息。

```text
Workqueue: events_unbound async_run_entry_fn
```

- `events_unbound` 是 Workqueue（不是 Worker）的名字；
- `async_run_entry_fn` 是对应 Worker 当前正在跑的函数。[^async]

[^tif]: TIF (task_thread_info(task)->flags) 和 task->flags 是两个字段。
[^async]: 来自 kernel/async.c
