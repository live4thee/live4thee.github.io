+++
title = "BLKTRACESETUP(2)"
date = 2024-01-09T20:36:35+08:00
tags = ["storage"]
categories = ["linux"]
draft = false
+++

嗯，解决了一个 `blktrace` 只能跟踪一次分区的问题。

## 缘起

前几天在一个 4.18 内核环境里做 `blkparse` 跟踪的时候发现：每个分区只能跟踪一次，第二次就会报错：[^bx]

```text
BLKTRACESETUP(2) /dev/sda failed: 2/No such file or directory
```

此时相应的有内核日志：

```text
kernel: blktrace: debugfs_dir not present for sdb1 so skipping
```

然而跟踪整盘没问题。印象中之前用 3.10 内核没有碰到过，而 6.x 内核好像也没碰到过。网上搜了一下，LQ 里面有个
很古老的[帖子](https://www.linuxquestions.org/questions/ubuntu-63/problem-while-running-blktrace-929695/)，
看起来也没啥有用的信息。不如就自己分析一下。

## 分析

首先根据报错信息和内核日志找代码，在 `do_blk_trace_setup()` 可以看到：

```c
/* file: kernel/trace/blktrace.c */
/*
 * When tracing the whole disk reuse the existing debugfs directory
 * created by the block layer on init. For partitions block devices,
 * and scsi-generic block devices we create a temporary new debugfs
 * directory that will be removed once the trace ends.
 */
if (bdev && !bdev_is_partition(bdev))
        dir = q->debugfs_dir;
else
        bt->dir = dir = debugfs_create_dir(buts->name, blk_debugfs_root);

/*
 * As blktrace relies on debugfs for its interface the debugfs directory
 * is required, contrary to the usual mantra of not checking for debugfs
 * files or directories.
 */
if (IS_ERR_OR_NULL(dir)) {
        pr_warn("debugfs_dir not present for %s so skipping\n",
                buts->name);
        ret = -ENOENT;
        goto err;
}
```

假设这里跟踪的是 `/dev/sdb1`. 显然，一个块设备是否是分区，会有不同的处理：
- 如果是整盘，debugfs 的目录会重用；
- 如果是分区，则临时创建一个目录。并且根据注释可知，`blktrace` 完成后，会删掉。

结合报错信息可知，`debugfs_create_dir()` 返回的 `dir` 有问题，`IS_ERR_OR_NULL(dir)` 为真。
查看现场可知：`blktrace` 跟踪完成后，`/sys/kernel/debug/block/sdb1/` 目录仍然存在，
里面有两个子文件：`dropped` 和 `msg` -- 不满足注释里的期待，难怪进入了报错分支。

心里一阵小激动：刷内核 commit 的机会来了！

## 测试

写个内核模块删掉残留的 `debugfs` 目录试一下。

```c
#include <linux/debugfs.h>
#include <linux/module.h>
#include <linux/string.h>
#include <linux/ctype.h>

static char* partname = NULL;

static int __init rm_init(void)
{
        struct dentry *parent = NULL;
        struct dentry *blk_dbgfs_root = NULL;
        size_t len;

        if (partname == NULL)
                return -1;

        pr_info("trying cleanup debugfs for '%s'\n", partname);

        len = strlen(partname);
        if (len == 0 || !isdigit(partname[len -1])) {
                pr_warn("unexpected block partname: '%s'\n", partname);
                return -1;
        }

        blk_dbgfs_root = debugfs_lookup("block", NULL);
        if (IS_ERR_OR_NULL(blk_dbgfs_root)) {
                pr_warn("debugfs_dir for block trace not found\n");
                goto out;
        }

        parent = debugfs_lookup(partname, blk_dbgfs_root);
        if (IS_ERR_OR_NULL(parent)) {
                pr_warn("debugfs_dir '%s' not found\n", partname);
                goto out;
        }

        debugfs_lookup_and_remove("dropped", parent);
        debugfs_lookup_and_remove("msg", parent);
        debugfs_remove(parent);
out:
        if (parent) dput(parent);
        if (blk_dbgfs_root) dput(blk_dbgfs_root);
        return -1;
}

module_init(rm_init);

module_param(partname, charp, 0);
MODULE_PARM_DESC(partname, "partition name, e.g. sda1");

MODULE_DESCRIPTION("remove blktrace debugfs left-overs for a partition");
MODULE_AUTHOR("David Lee <live4thee@gmail.com>");
MODULE_LICENSE("GPL");
```

编译后，测试一下：

```sh
$ insmod ./blktrace-remover.ko pathname=sdb1
insmod: ERROR: could not insert module ./blktrace-remover.ko: Operation not permitted
```

报错不用管，因为 `rm_init()` 故意返回的 -1. 查看一下，`/sys/kernel/debug/block/sdb1/` 目录果然删掉了，
`btrace /dev/sdb1` 又能正确工作了。

## 历史

写内核模块的过程中，发现 `debugfs_lookup()` 返回的 `struct dentry*` 是有引用计数的，需要 `dput()` 释放引用。
2022 年的一个 bugfix 做自动删除时漏掉了 `dput()` 导致临时目录未能正确删除。

- 2020/6, commit [b431ef837e337](https://github.com/torvalds/linux/commit/b431ef837e3374da0db8ff6683170359aaa0859c) 增加了之前看到的出错检查；
- 2022/2, commit [30939293262eb](https://github.com/torvalds/linux/commit/30939293262eb433c960c4532a0d59c4073b2b84) 引入了该问题；
- 2023/2, commit [83e8864fee26f](https://github.com/torvalds/linux/commit/83e8864fee26f63a7435e941b7c36a20fd6fe93e) 修复了该问题。[^bp]

[^bx]: 比较好的一点是，这个问题是必现的，排查起来较为方便。
[^bp]: 移交给 F 老师 backport 到 4.18 内核。可惜了这两行刷 commit 的小补丁。