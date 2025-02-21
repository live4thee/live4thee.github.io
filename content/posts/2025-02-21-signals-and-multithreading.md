---
title: "Signals & Multithreading"
date: 2025-02-21T09:59:45+08:00
tags: [ "mm" ]
categories: [ "linux" ]
draft: false
---

最近研究进程的退出，进而弄清楚了一些信号方面的疑问。首先开宗明义：“多
线程进程中，信号由主线程处理” 这句话是不准确的。

## 进程为何退出？

想要跟踪进程的退出时间，光跟踪 `exit_group()` 系统调用是不够的。进程调
用标准 C 的 `exit()` 退出进程时：

```sh
$ perf trace uname 2>&1 | grep exit
     0.658 (         ): uname/1278786 exit_group()
```

然而，进程也许是因为接收到 SIGTERM、SIGKILL 而退出。此时，不用查看内核
代码，光用 `trace-cmd` 查看内核路径就知道，最终都会调用到的函数是
`do_group_exit()`.

```sh
$ bpftrace -lv kfunc:do_group_exit
kfunc:do_group_exit
    int exit_code
```

因此，只要简单地跟踪 `do_group_exit()` 即可。

```sh
$ cat trace-exit.bt
kfunc:do_group_exit
{
    time("%H:%M:%S.");
	printf("%-3u pid=%-7d %s do_group_exit(%d)\n",
           (elapsed / 1e6) % 1000, pid, comm, args->exit_code);
}

$ bpftrace trace-exit.bt
Attaching 1 probe...
21:25:40.343 pid=1279378 ls do_group_exit(0)
21:25:40.344 pid=1279381 bash do_group_exit(0)
21:25:40.345 pid=1279382 bash do_group_exit(0)
...
```

### 被信号杀死

运行一个 `cat` 命令，然后用上面的 `trace-exit.bt` 进行跟踪，在执行了
`pkill -TERM cat` 后可以看到：

```sh
09:42:29.368 pid=1280229 cat do_group_exit(9)
```

如果想知道 `do_group_exit()` 是如何被调用到的，可以在 `trace-exit.bt`
脚本中打印 `kstack`:

```sh
09:46:26.710 pid=1280275 cat do_group_exit(9)
        cleanup_module+25064
        bpf_get_stackid_raw_tp+82
        cleanup_module+25064
        cleanup_module+32374
        do_group_exit+5
        get_signal+321
        do_signal+54
        exit_to_usermode_loop+137
        do_syscall_64+405
        entry_SYSCALL_64_after_hwframe+102
```

根据 `kstack` 输出找到[内核代码](https://github.com/torvalds/linux/blob/v5.2/kernel/signal.c#L2485),
可以看到 `cat` 没有 `SIGTERM` 的处理函数，最终 `do_group_exit()` 中的参
数 `SIGKILL`. 这也是上面的 `bpftrace` 输出中出现 `do_group_exit(9)` 的
原因。

```c
	/* Has this task already been marked for death? */
	if (signal_group_exit(signal)) {
		ksig->info.si_signo = signr = SIGKILL;
		sigdelset(&current->pending.signal, SIGKILL);
		trace_signal_deliver(SIGKILL, SEND_SIG_NOINFO,
				&sighand->action[SIGKILL - 1]);
		recalc_sigpending();
		goto fatal;
	}

	/* ... omitted ... */

    for (;;) {

	/* ... omitted ... */

fatal:

	/* ... omitted ... */:

		/*
		 * Death signals, no core dump.
		 */
		do_group_exit(ksig->info.si_signo);
		/* NOTREACHED */
    }
```

## 跟踪信号处理

查看 `get_signal()` 代码的过程中，可以看到内核在进程收到信号后，会有个
`tracepoint`:

```c
    trace_signal_deliver(signr, &ksig->info, ka);
```

查看一下该 `tracepoint` 的信息：

```sh
$ bpftrace -lv tracepoint:signal:signal_deliver
tracepoint:signal:signal_deliver
    int sig
    int errno
    int code
    unsigned long sa_handler
    unsigned long sa_flags
```

## 再看信号处理

修改以下 `trace-exit.bt` 脚本，增加信号的跟踪：

```sh
$ cat trace-exit.bt
kfunc:do_group_exit
{
    time("%H:%M:%S.");
	printf("%-3u pid=%-7d %s do_group_exit(%d)\n",
           (elapsed / 1e6) % 1000, pid, comm, args->exit_code);
}

tracepoint:signal:signal_deliver
{
    time("%H:%M:%S.");
    printf("%-3u pid=%-7d %s sig_deliver(sig:%d, errno:%d, code:%d, sa_hndr:0x%lx, sa_flags:0x%lx)\n",
           (elapsed / 1e6) % 1000, pid, comm,
            args->sig, args->errno, args->code, args->sa_handler, args->sa_flags);
}
```

跟踪 `pkill -TERM cat` 得到：

```sh
18:39:35.983 pid=81154 cat sig_deliver(sig:9, errno:0, code:0, sa_hndr:0x0, sa_flags:0x0)
18:39:35.983 pid=81154 cat do_group_exit(9)
```

这里可以明显看到 `sa_hndr` 为 0, 也就是没有注册信号处理函数。

## 如果注册了信号处理

简单写个代码，为 SIGTERM 注册一个信号处理（啥都不做）。
先 `pkill -TERM a.out`, 再 `ctrl-c`:

```sh
18:46:12.232 pid=81353 a.out sig_deliver(sig:15, errno:0, code:0, sa_hndr:0x400626, sa_flags:0x14000000)
18:46:13.105 pid=81353 a.out sig_deliver(sig:9, errno:0, code:0, sa_hndr:0x0, sa_flags:0x0)
18:46:13.105 pid=81353 a.out do_group_exit(9)
```

此时可以看到，信号值为 15, 而且处理函数的地址非零，也能看到 `sa_flags`.

修改 SIGTERM 的处理逻辑为 `exit(signo)`:

```sh
18:52:05.879 pid=81451 a.out sig_deliver(sig:15, errno:0, code:0, sa_hndr:0x400666, sa_flags:0x14000000)
18:52:05.879 pid=81451 a.out do_group_exit(3840)
```

此时出现了一个有意思的 `3840`，转为 16 进制：0xf00, 很规整的样子。查看
内核代码，这里对应：

```c
/* kernel/exit.c */
do_group_exit((error_code & 0xff) << 8);
```

`(15 & 0xff) << 8` 刚好就是 3840.

### 多线程的情况

设置好信号处理（保持为 `exit(signo)` ）后，创建一个线程，然后再 `pkill`，得到：

```sh
09:28:57.237 pid=82434 a.out sig_deliver(sig:15, errno:0, code:0, sa_hndr:0x400736, sa_flags:0x14000000)
09:28:57.237 pid=82434 a.out do_group_exit(3840)
09:28:57.237 pid=82434 a.out sig_deliver(sig:9, errno:0, code:0, sa_hndr:0x0, sa_flags:0x0)
09:28:57.237 pid=82434 a.out do_group_exit(9)
```

可以看到一些差异，但是分不清线程 - 可以为 bpftrace 脚本增加一个 `tid` 输出来解决：

```sh
09:33:51.271 pid=1282515 tid=82515 a.out sig_deliver(sig:15, errno:0, code:0, sa_hndr:0x400736, sa_flags:0x14000000)
09:33:51.271 pid=1282515 tid=82515 a.out do_group_exit(3840)
09:33:51.271 pid=1282515 tid=82516 a.out sig_deliver(sig:9, errno:0, code:0, sa_hndr:0x0, sa_flags:0x0)
09:33:51.271 pid=1282515 tid=82516 a.out do_group_exit(9)
```

现在知道，是主线程执行了注册的信号处理。如果创建线程后再注册信号处理呢？

```sh
09:40:20.706 pid=82588 tid=82588 a.out sig_deliver(sig:15, errno:0, code:0, sa_hndr:0x400736, sa_flags:0x14000000)
09:40:20.706 pid=82588 tid=82588 a.out do_group_exit(3840)
09:40:20.706 pid=82588 tid=82589 a.out sig_deliver(sig:9, errno:0, code:0, sa_hndr:0x0, sa_flags:0x0)
09:40:20.706 pid=82588 tid=82589 a.out do_group_exit(9)
```

看起来没啥区别。但其实归纳法得出的结论并不一定可靠。工作中就碰到过例外
情况，内核代码 `kernel/signal.c` 中有：

```c
static void complete_signal(int sig, struct task_struct *p, enum pid_type type)
{
        struct signal_struct *signal = p->signal;
        struct task_struct *t;

        /*
         * Now find a thread we can wake up to take the signal off the queue.
         *
         * If the main thread wants the signal, it gets first crack.
         * Probably the least surprising to the average bear.
         */
        if (wants_signal(sig, p))
                t = p;
        else if ((type == PIDTYPE_PID) || thread_group_empty(p))
                /*
                 * There is just one thread and it does not need to be woken.
                 * It will dequeue unblocked signals before it runs again.
                 */
                return;
        else {
                /*
                 * Otherwise try to find a suitable thread.
                 */
                t = signal->curr_target;
                while (!wants_signal(sig, t)) {
                        t = next_thread(t);
                        if (t == signal->curr_target)
                                /*
                                 * No thread needs to be woken.
                                 * Any eligible threads will see
                                 * the signal in the queue soon.
                                 */
                                return;
                }
                signal->curr_target = t;
        }
```

## 控制处理信号的线程

如果应用想控制由某个线程来处理信号，有如下途径：

1. 主线程先把信号处理设置为 `SIG_IGN`, 并 `sigemptyset()` 后交由
   `sigaction()` 注册；
2. 如此，则所有子线程也会忽略指定的信号；
3. 对于需要处理信号的线程，比如主线程中，不断通过 `sigtimedwait()` 获
   取信号。

## 参考

1. [A process murder mystery](https://blog.viraptor.info/post/a-process-murder-mystery-a-debugging-story)
2. [Signal handling with multiple threads in Linux](https://stackoverflow.com/questions/11679568/signal-handling-with-multiple-threads-in-linux)
3. [Signal Handling for async multithreaded application](https://medium.com/@zakharchenkoirr/signal-handling-for-async-multithreaded-application-f3b723dd9022)
4. [Returning from Interrupts and Exceptions](https://www.oreilly.com/library/view/understanding-the-linux/0596005652/ch04s09.html)
5. [Reset sigaction to default](https://stackoverflow.com/questions/24803368/reset-sigaction-to-default)
