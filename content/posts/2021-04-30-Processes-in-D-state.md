+++
title = "Processes in D State"
date = 2021-04-30T16:00:55+08:00
tags = ["storage"]
categories = ["linux"]
draft = false
+++

当进程陷入不可中断睡眠的时候，用户没有办法杀掉它。如果该进程进入了僵尸
状态、且有很多子进程的话那就更是“屋漏偏逢连夜雨”了。绝大部分情况下，这
种情况都是因为 I/O 出了问题，因此除非 I/O 被唤醒，只能重启物理机了。

这里记录两个小技巧。

### wchan

~~~sh
$ ps -eo ppid,pid,user,stat,pcpu,comm,wchan:32
~~~

这里，'wchan' 会打印进程睡眠在哪个内核函数。

### sysrq-trigger

~~~sh
# echo w > /proc/sysrq-trigger
~~~

然后，就能在内核日志中看到陷入 'D' 状态的进程列表，以及它们的完整内核堆栈。

来源：[suse.com](https://www.suse.com/support/kb/doc/?id=000016919)
