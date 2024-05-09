---
title: "Learning by Tracing"
date: 2024-05-09T18:41:54+08:00
tags: [ "storage" ]
categories: [ "linux" ]
draft: false
---

用 `bpftrace` 跟踪一个 Direct I/O 在 polling 和非 polling 模式下的处理
逻辑。为了减少无关的 I/O 干扰，限定了 `comm == "a.out"` -- 这个 `a.out`
是我的测试程序。

内核是 4.18, 关键代码相对比较好找，在 `fs/block_dev.c`:

```c
static void blkdev_bio_end_io_simple(struct bio *bio)
{
    struct task_struct *waiter = bio->bi_private;

    WRITE_ONCE(bio->bi_private, NULL);
    blk_wake_io_task(waiter);
}

static ssize_t
__blkdev_direct_IO_simple(struct kiocb *iocb, struct iov_iter *iter,
                         int nr_pages)
{
    bio.bi_private = current;
    bio.bi_end_io = blkdev_bio_end_io_simple;

    // 省略无关部分
    qc = submit_bio(&bio);
    for (;;) {
            set_current_state(TASK_UNINTERRUPTIBLE);
            if (!READ_ONCE(bio.bi_private))
                    break;
            if (!(iocb->ki_flags & IOCB_HIPRI) ||
                !blk_poll(bdev_get_queue(bdev), qc, true))
                    blk_io_schedule();
    }
    __set_current_state(TASK_RUNNING);
}
```

上面的 for 循环中，如果没有设置 `IOCB_HIPRI` （非 polling 模式）, 则直
接进入 `blk_io_schedule()`，等待被 `blkdev_bio_end_io_simple()` 唤醒。
否则，进入 `blk_poll()` 逻辑，进行忙等或者 hybrid 等待。

跟踪 `bio_endio()` 得到的 `kstack` 和代码非常一致，如下：

```text
kprobe:bio_endio: opf=0x800000, hipri requires: 0x800000, comm='a.out', kstack:
        bio_endio+1
        blk_update_request+544
        blk_mq_end_request+26
        nvme_poll+482
        blk_poll+282
        __blkdev_direct_IO_simple+520
        kretprobe_trampoline+0
```

去掉 `RWF_HIPRI` 后发现，`bio_endio()` 怎么也触发不到，像是泥牛入海。

冷静一下。

问题出在 `/comm == "a.out"/` 这个过滤器。中断模式下，执行
`bio_endio()` 时的 `comm` 是 `swapper/N`，甚至也有可能是 `sshd`! 因为
处于中断上下文（严格来说，是下文 - `bottom-half`）。

```text
kprobe:bio_endio: opf=0x0, hipri requires: 0x800000, comm='swapper/0', kstack:
        bio_endio+1
        blk_update_request+544
        blk_mq_end_request+26
        nvme_irq+295
        __handle_irq_event_percpu+64
        handle_irq_event_percpu+48
        handle_irq_event+54
        handle_edge_irq+130
        handle_irq+28
        do_IRQ+73
        ret_from_intr+0
        native_safe_halt+14
        __cpuidle_text_start+10
        default_idle_call+64
        do_idle+500
        cpu_startup_entry+111
        start_kernel+1309
        secondary_startup_64_no_verify+194
```

```c
static irqreturn_t nvme_irq(int irq, void *data)
{
    struct nvme_queue *nvmeq = data;

    if (nvme_process_cq(nvmeq))
        return IRQ_HANDLED;
    return IRQ_NONE;
}
```

Certified by [AI](https://pi.ai/talk). ;-)
![disk-bh](/media/disk-bh.png)
