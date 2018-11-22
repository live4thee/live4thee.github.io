+++
title = "Random Bits (3)"
description = ""
date = "2018-11-22T19:36:41+08:00"
tags = ["sysadmin"]
categories = ["work"]
+++

今天是小雪。魔都阳光明媚。

最近手上处理了几个诡异的问题，这里简单记录一下。

## "Too many open files"

售前同事说，某客户的环境里，出现了 "Too many open files". 一般来说，这
种问题都比较简单。用 `lsof` 查看一下，基本上就水落石出了。不过，这个不
一样。

首先，`lsof -p pid` 的输出中，有大量类型为 `sock`，名字显示为
`prococol: TCP` 的记录。类似：

```text
...
python 49720 appuser *665u  sock 0,6  0t0  1104529642 protocol: TCP
python 49720 appuser *666u  sock 0,6  0t0  1104529643 protocol: TCP
...
```

其中，`/proc/497200/fd/666` 指向 `socket:[1104529642]`，但进一步搜索
`grep 19164451 /proc/net/tcp` 则又一无所获。

`ss -a` 只有区区数百条记录。`netstat -tunap` 和 `lsof -i -a -p pid`也
类似。

查看了 `lsof` 的手册，获得如下信息：

```text
TYPE       is the type of the node associated with the file
...
or ``IPv4'' for an IPv4 socket;
or ``sock'' for a socket of unknown domain;
or ``unix'' for a UNIX domain socket;
...
```

邮件列表搜到一个类似的
[贴子](https://mailman.uni-konstanz.de/pipermail/basex-talk/2012-May/003151.html)
，另外 AskUbuntu 上有个
[解释](https://askubuntu.com/questions/527650/what-exactly-is-a-connection-through-socket-or-what-does-the-output-of-lsof-tell):

    The can't identify protocol is probably a connection that hasn't
    been fully set up yet. ... 399u indicates that the fd is numbered
    339 and has both read and write access (u).

看起来，是有 socket 没有关闭。因为代码里没有直接操作 socket，因此找了
一下相关的库。果然有个“疑犯”，尴尬的是本地不能重现。也从未有别的客户碰
到过。成了孤例。

## Too many open files ... again

这回不是来自我们的 agent，而是数据库。

最初的现象是管控程序所有的线程都等在了数据库操作。负载很低。`systemctl
status mariadb` 看数据库的状态，很健康。看数据库的日志，妈呀，`Too
many open files`.

同事很早就把 `max_connections` 设置为了 1024，然而，数据库运行时并没有
给到 1024，而是 214。但是管控的配置是 250，因此就悲剧了。

从某个日本网友的
[博文](https://tmtms.hatenablog.com/entry/2017/10/12/mysql-max-connections)
那里学习了 `max_connections`, `open_files_limit` 以及
`table_open_cache` 之间的关系。

### open_files_limit

该值受一下数值影响：

1. 10 + max_connections + table_open_cache * 2
2. max_connections * 5
3. my.cnf 里指定的 open_files_limit
4. limits 决定的 RLIMIT_NOFILE

MySQL 5.6/5.7 据说是取上面的最大值，MariaDB 5.5 实测下来是 limits 决定
的值。

### max_connections

如果 `max_connections` 大于`open_files_limit - 810`，则为
`open_files_limit - 810` 的值。

因此，默认环境下，`open_files_limit = 1024`，此时，`max_connections = 214`.

### table_open_cache

取值为 `max (400, (open_files_limit - 10 - max_connections)/2)`

最后，发现一个贴心的[网站](http://www.mysqlcalculator.com/)可以用来
计算 MySQL/MariaDB 的内存消耗。


## 流水账

今天傍晚跑了6公里，黄色的月亮在地平线上方20度左右，很漂亮。
