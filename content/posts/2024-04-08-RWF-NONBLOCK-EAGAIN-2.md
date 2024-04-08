---
title: "RWF_NONBLOCK & EAGAIN (2)"
date: 2024-04-08T11:00:58+08:00
tags: [ "storage" ]
categories: [ "linux" ]
draft: false
---

先交代一下[上文]({{< ref "/content/posts/2024-04-03-RWF-NONBLOCK-EAGAIN.md" >}})的实验环境：

- kernel: 4.18.0-425.19.2 (CentOS Stream 8)
- filesystem: Ext4

测试动作：向一个 Ext4 上的文件发一个 4k 非阻塞异步写请求。

## RWF_NOWAIT

重新回顾一下 *io_submit(2)* 的手册里交代了设置 *RWF_NOWAIT* 后出现 *-EAGAIN* 的几个场景：

- file block allocation;
- dirty page flush;
- mutex locks;
- congested block device.

如果内核发现当前 I/O 还须完成上述操作，则会直接返回 *-EAGAIN*.

### file block allocation

代码中，被写文件是通过 *posix_fallocate()* 预先分配的空间。手动测试通过 *fallocate* 命令
创建文件。

### dirty page flush

对照了 *libaio* 的测试[用例](https://pagure.io/libaio/blob/master/f/harness/cases/21.t),
当前环境不存在该情景。

### mutex locks

对照内核代码中 *ext4_file_write_iter()* 的实现，该场景待排查。不过，该
文件只有一个写入线程（测试程序），等待互斥锁的可能性也不高。

### congested block device

同上，测试程序的 I/O 可控。目前就算只发一个写请求，也会有 *-EAGAIN*.

看起来，进入了死胡同。因此，比较可信、可行的方法是用 *bpftrace* 跟踪确
认上述场景。

## ext4_file_write_iter()

该函数可能返回 *-EAGAIN* 的场景有以下四个出口：

```c
if (iocb->ki_flags & IOCB_NOWAIT) {
	if (!inode_trylock(inode))
		return -EAGAIN;       /* 出口1 */
} else {
	inode_lock(inode);
}

ret = ext4_write_checks(iocb, from);  /* 出口2 */
if (ret <= 0)
	goto out;

/* 中间省略部分代码 */

/* Check whether we do a DIO overwrite or not */
if (o_direct && !unaligned_aio) {
	if (ext4_overwrite_io(inode, iocb->ki_pos, iov_iter_count(from))) {
		if (ext4_should_dioread_nolock(inode))
			overwrite = 1;
	} else if (iocb->ki_flags & IOCB_NOWAIT) {
		ret = -EAGAIN;      /* 出口3 */
		goto out;
	}
}

ret = __generic_file_write_iter(iocb, from); /* 出口4 */
```

首先，通过 kretprobe 跟踪 *ext4_write_checks()* 发现该函数返回 4096,
因此排除了出口1、出口2. 而 *kretprobe:__generic_file_write_iter* 没有
被触发，因此：必然是出口3.

### ext4_overwrite_io()

该函数比较短，不妨全文复制如下：

```c
/* Is IO overwriting allocated and initialized blocks? */
static bool ext4_overwrite_io(struct inode *inode, loff_t pos, loff_t len)
{
	struct ext4_map_blocks map;
	unsigned int blkbits = inode->i_blkbits;
	int err, blklen;

	if (pos + len > i_size_read(inode))
			return false;

	map.m_lblk = pos >> blkbits;
	map.m_len = EXT4_MAX_BLOCKS(len, pos, blkbits);
	blklen = map.m_len;

	err = ext4_map_blocks(NULL, inode, &map, 0);
	/*
	 * 'err==len' means that all of the blocks have been preallocated,
	 * regardless of whether they have been initialized or not. To exclude
	 * unwritten extents, we need to check m_flags.
	 */
	return err == blklen && (map.m_flags & EXT4_MAP_MAPPED);
}
```

通过 bpftrace 跟踪得到：

- err = 1
- blklen = 1
- map.m_flags = 0x1000

对照代码，可以得到：

- *EXT4_MAP_MAPPED* = 0x20
- *EXT4_MAP_UNWRITTEN* = 0x1000

这也印证了 *ext4_overwrite_io()* 返回了 false, 因此导致上面的代码走到
了出口3. 那么，为何 *fallocate* 出来的文件，会返回*EXT4_MAP_UNWRITTEN* 呢？

### ext4_map_blocks()

```c
/*
 * The ext4_map_blocks() function tries to look up the requested blocks,
 * and returns if the blocks are already mapped.
 *
 * /* 省略部分注释 */
 *
 * On success, it returns the number of blocks being mapped or allocated.  if
 * create==0 and the blocks are pre-allocated and unwritten, the resulting @map
 * is marked as unwritten. If the create == 1, it will mark @map as mapped.
 */
int ext4_map_blocks(handle_t *handle, struct inode *inode,
					struct ext4_map_blocks *map, int flags)
{
	/* 省略部分代码 */

	/* Lookup extent status tree firstly */
	if (ext4_es_lookup_extent(inode, map->m_lblk, &es)) {
		if (ext4_es_is_written(&es) || ext4_es_is_unwritten(&es)) {
			map->m_pblk = ext4_es_pblock(&es) +
							map->m_lblk - es.es_lblk;
			map->m_flags |= ext4_es_is_written(&es) ?
							EXT4_MAP_MAPPED : EXT4_MAP_UNWRITTEN;
		}
	}
}
```

考虑到 *m_flags* 的值为 *EXT4_MAP_UNWRITTEN*, 因此结合 bpftrace 的跟踪
结果可知： *ext4_es_is_unwritten(&es)* 返回了 true.

*ext4_es_is_unwritten(&es)* 传入的参数是 *struct extent_status es* 的指针，
其内容是通过函数 *ext4_es_lookup_extent()* 查找得来。也就是说，*fallocate* 出
来的文件在 Ext4 上的 extent 对应的状态是 *EXT4_MAP_UNWRITTEN*.

### fallocate

用 filefrag 检查一下 fallocate 创建出来的文件：

```sh
$ fallocate -l 4m file.dat
$ filefrag -v file.dat
Filesystem type is: ef53
File size of file.dat is 4194304 (1024 blocks of 4096 bytes)
 ext:  logical_offset:    physical_offset: length:  expected: flags:
   0:     0..    1023:  82944..     83967:   1024:            last,unwritten,eof
file.dat: 1 extent found
```

果然是有个 *unwritten* 标志。那么，写零处理一下，可以吗？

```sh
$ fallocate -z -l 4m file.dat
$ Filesystem type is: ef53
File size of file.dat is 4194304 (1024 blocks of 4096 bytes)
 ext:  logical_offset:    physical_offset: length:  expected: flags:
   0:     0..    1023:  82944..     83967:   1024:            last,unwritten,eof
file.dat: 1 extent found
```

没有变化。这个可以从 *fallocate(1)* 手册中得到解释：

```text
-z, --zero-range
	... 省略部分 ...
	Zeroing  is done within the filesystem preferably by converting
	the range into unwritten extents.  This approach means that the
	specified range will not be physically zeroed out on the device
	(except  for partial blocks at the either end of the range), and
	I/O is (otherwise) required only to update metadata.
```

也就是说，

- *fallocate* 的写零只是元数据层面的事情；
- *fallocate* 的分配也只是元数据层面的事情（但保证了后续实际分配物理块不会失败）。

## 总结

对于支持 *fallocate* 系统调用的文件系统（比如 XFS, Ext4），它们只是在
文件系统的元数据层面将分配的块标记为未初始化状态。既不实际进行物理块的
分配，也不会对物理块填零。它仅仅保证后续的物理块分配不会失败。

对于 *io_submit* 指定 *RWF_NOWAIT* 后的行为，所谓：

```text
Don't  wait  if the I/O will block for operations such as file block
allocations,
```

这里的 *file block allocations* 指的是实际的物理块的已分配。

## dd？

用 dd 创建一个文件测试怎么样？

```sh
$ dd if=/dev/zero of=file.dat oflag=direct bs=4M count=1
1+0 records in
1+0 records out
4194304 bytes (4.2 MB, 4.0 MiB) copied, 0.0118739 s, 353 MB/s

$ filefrag -v file.dat
Filesystem type is: ef53
File size of file.dat is 4194304 (1024 blocks of 4096 bytes)
 ext:  logical_offset:    physical_offset: length:  expected: flags:
   0:     0..    1023:  83456..     84479:   1024:            last,eof
file.dat: 1 extent found
```

果然，*flags* 里不再有 *unwritten* 标记。继续手动测试发现，*ext4_map_blocks()* 返回后，
*map.m_flags* 从 0x1000 变成了 0x20, 即 *EXT4_MAP_MAPPED*. 但最终还会得到 **-529**.
但是测试程序的 *io_getevents(2)* 的 *event.res* 字段为 0.

注意，`dd` 的 `oflag` 参数指定了 `direct`，这样不会因为 `page cache` 的存在导致 `-EAGAIN`.
否则，需要先释放 `page cache`：

```sh
$ echo 1 > /proc/sys/vm/drop_caches
```

### -529 揭秘

通过 bpftrace 跟踪得知，之前的出口4会返回 -529, 正是之前迷惑不解的地方。对照后面的代码可知，
这个 -529 正是  *-EIOCBQUEUED. 由于此时提交的是个对齐的异步 I/O, 因此后面直接 `return ret`.

```c
ret = __generic_file_write_iter(iocb, from); /* 出口4 */
/*
 * Unaligned direct AIO must be the only IO in flight. Otherwise
 * overlapping aligned IO after unaligned might result in data
 * corruption.
 */
if (ret == -EIOCBQUEUED && unaligned_aio)
    ext4_unwritten_wait(inode);
inode_unlock(inode);

if (ret > 0)
    ret = generic_write_sync(iocb, ret);

return ret;
```



## 附 - bpftrace 脚本

```c
#include <linux/fs.h>
#include <linux/uio.h>
#include <linux/rbtree_types.h>

struct ext4_map_blocks {
		unsigned long long m_pblk;
		__u32 m_lblk;
		unsigned int m_len;
		unsigned int m_flags;
};

struct extent_status {
		struct rb_node rb_node;
		__u32 es_lblk;
		__u32 es_len;
		unsigned long long es_pblk;
};

kretprobe:generic_file_direct_write,
kretprobe:__generic_file_write_iter,
kretprobe:ext4_write_checks,
kretprobe:ext4_es_lookup_extent
{
	printf("%-6d %-16s: %lld [%s]\n", pid, comm, retval, probe);
}

kprobe:ext4_es_lookup_extent
{
	@args[pid, "es"]  = (struct extent_status*) arg2;
}

kprobe:ext4_file_write_iter
{
	$iocb = (struct kiocb *)arg0;
	$n = ((struct iov_iter *) arg1)->count;
	@args[pid, "priv"] = ((struct kiocb *)arg0)->private;
	printf("%-6d %-16s: [%s]: ki_flags=0x%x, ki_pos=0x%x, #iov=%d\n",
					pid, comm, probe,
					$iocb->ki_flags, $iocb->ki_pos, $n);
}

kprobe:ext4_map_blocks
{
	$inode = (struct inode *)arg1;
	@args[pid, "emap"] =  (struct ext4_map_blocks *) arg2;
	printf("%-6d %-16s: blkbits=0x%x [%s]\n",
				   pid, comm, $inode->i_blkbits, probe);
}

kretprobe:ext4_map_blocks
{
    $map = (struct ext4_map_blocks *)@args[pid, "emap"];
    $es = (struct extent_status*)@args[pid, "es"];
    printf("%-6d %-16s: %lld, pblk=%lld,m_flags=0x%x, m_len=%d [%s]\n",
				   pid, comm, retval,
				   $es->es_pblk,
				   $map->m_flags, $map->m_len, probe);
}

END { clear(@args); }
```
