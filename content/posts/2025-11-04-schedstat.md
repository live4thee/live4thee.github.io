---
title: "schedstat"
date: 2025-11-04T14:21:23+08:00
tags: [ "sysadmin" ]
categories: [ "linux" ]
draft: false
---

偶尔在一篇[博客](https://tanelpoder.com/posts/schedlat-low-tech-script-for-measuring-cpu-scheduling-latency-on-linux/)看到，Linux 内核针对每个进程做了调度统计。内核文档如下：

```txt
/proc/<pid>/schedstat
----------------
schedstats also adds a new /proc/<pid>/schedstat file to include some of
the same information on a per-process level.  There are three fields in
this file correlating for that process to:
     1) time spent on the cpu
     2) time spent waiting on a runqueue
     3) # of timeslices run on this cpu
```

[博客](https://tanelpoder.com/posts/schedlat-low-tech-script-for-measuring-cpu-scheduling-latency-on-linux/)作者利用以上 *schedstat* 文件设计了一个工具：[schedlat](https://github.com/tanelpoder/0xtools/blob/master/bin/schedlat) - 统计给定进程的调度延迟。示例如下：

```sh
# fio --ioengine=pvsync2 ... schedlat 采样 worker 进程
TIMESTAMP              %CPU   %LAT   %SLP
2025-11-04 13:56:58    41.8    1.7   56.4
2025-11-04 13:56:59    40.8    1.7   57.5
2025-11-04 13:57:00    41.9    1.7   56.4
2025-11-04 13:57:01    41.9    1.6   56.5
2025-11-04 13:57:02    40.5    1.5   58.0
2025-11-04 13:57:03    39.0    1.7   59.3
...

# fio --ioengine=libaio ... schedlat 采样 worker 进程
TIMESTAMP              %CPU   %LAT   %SLP
2025-11-04 13:57:34    87.0    4.5    8.5
2025-11-04 13:57:35    87.0    4.8    8.2
2025-11-04 13:57:36    86.7    5.1    8.1
2025-11-04 13:57:37    86.8    4.8    8.4
2025-11-04 13:57:38    86.8    4.6    8.5
2025-11-04 13:57:39    86.7    5.2    8.2
...
```

挺方便。
