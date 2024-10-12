---
title: "fio Trickery"
date: 2024-10-12T13:51:58+08:00
tags: [ "storage" ]
categories: [ "linux" ]
draft: false
---

遇到一个需要测试大量创建文件的场景。毫无疑问，一定能通过 `fio` 解决。
查看了一下 `man` 手册，有个 `filecreate` 引擎，折腾了几分钟也只能创建
一个文件。`Deepseek-Coder-128k` 给的答案同样是使用 `filecreate`:

```ini
[global]
ioengine=filecreate
filesize=1M
create_on_open=1
create_only=1
create_fsync=1
create_trim=1
create_zero=1
directory=/path/to/your/directory

[job1]
filename=file{1..1000}
```

但是，我的环境中并不工作。`fio-3.19` 报错：

```txt
Bad option <create_trim=1>
Did you mean create_only?
Bad option <create_zero=1>
Did you mean create_only?
fio: job global dropped.
```

去掉 `create_trim` 和 `create_zero` 后：

```txt
munmap_chunk(): invalid pointer
fio: pid=6464, got signal=6
```

最后通过搜索引擎得到的可工作的结果：

```ini
[global]
filesize=4k
create_only=1
#create_fsync=1   # default=1

[job1]
#size=4k
#rw=write
nrfiles=100
directory=/data/foo

[job2]
nrfiles=100
directory=/data/bar
```

直接用命令行，就是类似：

```sh
$ fio --name=test --directory=/data/foo --filesize=4k \
	--create_only=1 --nrfiles=100
```

通过指定 `--create_only=1` 可以让 `fio` 预先创建好所有文件，然后就退出
（并不做 I/O 测试）。因此，测试过程中会输出类似以下信息：

```txt
test: Laying out IO files (100 files / total 0MiB)
```

如果还需要对创建的文件进行 I/O 测试，则设置：

```ini
create_only=0
size=
rw=
```

参考：[Re: How to create multiple files with FIO?](https://www.spinics.net/lists/fio/msg01522.html)
