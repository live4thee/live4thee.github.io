---
categories:
- linux
date: 2017-03-15T00:00:00Z
description: ""
tags:
- sysadmin
title: Command-line limits
url: /2017/03/15/command-line-limits/
---


可能大多数人都没有意识到，命令行字符串的最大长度是有限制的。

```
$ echo | xargs --show-limits
Your environment variables take up 2766 bytes
POSIX upper limit on argument length (this system): 2092338
POSIX smallest allowable upper limit on argument length (all systems): 4096
Maximum length of command we could actually use: 2089572
Size of command buffer we are actually using: 131072
Maximum parallelism (--max-procs must be no greater): 2147483647
```

可以用 `perl` 快速验证一下：

```
$ /usr/bin/echo perl -e 'print "A"x131072, "\n"'
-bash: /usr/bin/echo: Argument list too long
$ /usr/bin/echo perl -e 'print "A"x131071, "\n"'
AAAAAAAAAAAAAAAA...
```

这里需要用 `/usr/bin/echo` 而不是默认的内置(built-in)命令 `echo`。
