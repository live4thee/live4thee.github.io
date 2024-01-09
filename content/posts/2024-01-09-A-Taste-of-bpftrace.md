+++
title = "A Taste of bpftrace"
date = 2024-01-09T13:03:35+08:00
tags = ["mm"]
categories = ["linux"]
draft = false
+++

[bpftrace](https://bpftrace.org/)真的挺好用。[^onelns]

## 跟踪进程的执行

通过跟踪 `execve`，可以得到系统中进程执行的情况。

```sh
$ bpftrace -e 'tracepoint:syscalls:sys_enter_execve { time("%H:%M:%S "); join(args->argv) }'
Attaching 1 probe...
13:10:04 /usr/lib64/sa/sa1 1 1
13:10:04 /usr/lib64/sa/sadc -F -L -S DISK 1 1 /var/log/sa
13:10:29 awk /^(MemFree|Buffers|Cached):/ {free += $2}; END {print free} /proc/meminfo
13:10:29 pgrep -d   -- ^qemu(-(kvm|system-.+)|:.{1,11})$
13:10:29 awk { sum += $1 }; END { print 0+sum }
13:10:29 sleep 60
```

好奇 `awk` 和 `pgrep` 怎么来的？一开始以为可能是某同时写的监控脚本，后
来查看了进程树和 `crontab` 后，基本排除。再次祭上 `bpftrace` :

```perl
tracepoint:syscalls:sys_enter_exec*
{
    $task = (struct task_struct *)curtask;
    time("%H:%M:%S ");
    printf("%5d/%-16s %-5d ", $task->real_parent->pid, $task->real_parent->comm, pid);
    join(args->argv);
}
```

可以得到：

```sh
13:16:29 96907/ksmtuned  96908 awk /^(MemFree|Buffers|Cached):/ {free += $2}; END {print free} /proc/meminfo
13:16:29 96910/ksmtuned  96911 pgrep -d   -- ^qemu(-(kvm|system-.+)|:.{1,11})$
13:16:29 96909/ksmtuned  96913 awk { sum += $1 }; END { print 0+sum }
13:16:29  1320/ksmtuned  96914 sleep 60
```

好嘛！原来是 `ksmtuned`. 有道是 `bpftrace` 一探，真相立现！

另外，其实也能看到，`bash` 交互式 shell 里每执行一条命令，会多出一个
`who am i`, 一个 `awk`, 一个 `whoami`. 有兴趣可以再探。

```text
13:18:08 96945/bash     96998 ls --color=auto
13:18:08 97003/bash     97004 who am i
13:18:08 97003/bash     97005 awk {print $(NF-2),$(NF-1),$NF}
13:18:08 97006/bash     97007 whoami
```

## 跟踪内核调用栈

看内核代码的时候，一堆函数指针，找到调用流程往往比较痛苦。用
`bpftrace` 打印调用栈就能避免走弯路。比如，我想知道
`blk_mq_complete_request` 是怎么被调用到的？

```perl
$ bpftrace -e 'kprobe:blk_mq_complete_request { printf("%s\n", kstack); exit() }'
Attaching 1 probe...

        blk_mq_complete_request+1
        _scsih_io_done+891
        _base_process_reply_queue+147
        _base_interrupt+43
        __handle_irq_event_percpu+76
        handle_irq_event_percpu+15
        handle_irq_event+52
        handle_edge_irq+130
        __common_interrupt+58
        common_interrupt+125
        asm_common_interrupt+34
        cpuidle_enter_state+198
        cpuidle_enter+41
        do_idle+489
        cpu_startup_entry+38
        start_secondary+282
        secondary_startup_64_no_verify+381
```

[^onelns]: 比如，一堆实用的 [one liners](https://github.com/iovisor/bpftrace/blob/master/docs/tutorial_one_liners.md)
