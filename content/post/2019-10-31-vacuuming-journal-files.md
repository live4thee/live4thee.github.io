+++
title = "Vacuuming Systemd Journals"
description = ""
date = "2019-10-31T09:20:19+08:00"
tags = ["sysadmin"]
categories = ["linux"]
+++

之前发现，执行 *journalctl --vacuum-time=2d* 并不一定会释放日志空间。

根本原因是：*vacuum* 操作只针对已经归档的日志。所以，正确的操作：

```sh
journalctl --rotate
journalctl --vacuum-time=2d
```

需要注意的是：上面两个命令不能合并成一个执行。

另外，*journald.conf* 的 man 手册里提到一个配置项：*MaxRetentionSec*

```text
$ man 5 journald.conf
...
MaxRetentionSec=
    The maximum time to store journal entries.
```

资料来源：[How to clear journalctl](https://unix.stackexchange.com/questions/139513/how-to-clear-journalctl)
