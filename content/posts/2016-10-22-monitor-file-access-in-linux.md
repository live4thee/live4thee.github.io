---
categories:
- linux
date: 2016-10-22T00:00:00Z
description: ""
tags:
- sysadmin
title: Monitor File Access in Linux
url: /2016/10/22/monitor-file-access-in-linux/
---


最近调试某个程序的过程中，需要监控文件系统中，某个目录下的文件删除操作。
下意识反应是用 *inotify*，但是又不想自己处理递归添加被监控目录或者文件。
第二个反应是用 *ftrace* 或者 *system-tap* 这样的工具，为内核中的删除系
统调用 (*rmdir*, *unlink*, *unlinkat*) 添加监测点。

后来找到了一个现成的工具 - *inotify-tools*，里面包含了 *inotifywait*，
可以处理递归，因此非常适合在 Shell 中使用：

```
inotifywait -dmrq --event delete,create \
    --timefmt '%y/%m/%d %H:%M' --format '%T %w%f %e' \
    --exclude '(tags|uploads)' \
    -o /httpd/monitor.log \
    $DIR_TO_MONITOR
```

上面的命令可监控 *$DIR_TO_MONITOR* 目录（不监控路径中带有 *tags* 或者
*uploads* 的文件或者目录）。我把输出文件直接放在了一个用 HTTP 可以访问
的目录。其中，*"-d"* 参数使得监控进程后台执行，比较方便。缺点是，从记
录中无法得知文件操作的进程信息。

后来，经同事提醒可以用 *auditd* 来监控，只要添加一条规则：

```
auditctl -a exit,always -F arch=b64 -F path=$DIR_TO_MONITOR \
    -S unlink -S unlinkat -k deletion
```

*auditd* 中还提供了查找工具，比如：

```
ausearch --start today -k deletion
```

唯一的一个瑕疵是，*auditd* 貌似不能用正则表达式做 *exclude* 规则。
