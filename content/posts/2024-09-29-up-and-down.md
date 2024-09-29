---
title: "Up & Down"
date: 2024-09-29T16:41:11+08:00
tags: [ "storage" ]
categories: [ "linux" ]
draft: false
---

上周四晚上，刚到家还没停车，发现自己被拉到了一个群里。

> “这个问题比较严重，麻烦帮忙看一下。”

环境是 Kylin v10, 内核版本：4.19.90-52.15.v2207. 内核崩掉的时候，Call
trace 长下面这样：

```txt
[ 2427.320099] Unable to handle kernel paging request at virtual address ffffbe149903ea60
[ 2427.332573] Mem abort info:
[ 2427.337881]   ESR = 0x96000005
[ 2427.343441]   Exception class = DABT (current EL), IL = 32 bits
[ 2427.351943]   SET = 0, FnV = 0
[ 2427.357550]   EA = 0, S1PTW = 0
[ 2427.363232] Data abort info:
[ 2427.368649]   ISV = 0, ISS = 0x00000005
[ 2427.375029]   CM = 0, WnR = 0
...
[ 2427.744568]  bio_associate_blkcg+0x40/0x98
[ 2427.744570]  bio_clone_blkcg_association+0x2c/0x58
[ 2427.744572]  __bio_clone_fast+0x90/0xb0
[ 2427.744573]  bio_clone_fast+0x44/0x90
```

崩掉之前，有一堆 WARNING, 堆栈和崩掉的时候类似：

```txt
[ 2403.153657]  bio_clone_blkcg_association+0x4c/0x58
[ 2403.153661]  __bio_clone_fast+0x90/0xb0
```

对照 OpenEuler 的[代码](https://gitee.com/openeuler/kernel):

```c
void bio_clone_blkcg_association(struct bio *dst, struct bio *src)
{
    if (src->bi_css)
        WARN_ON(bio_associate_blkcg(dst, src->bi_css)); // Call trace 来源
}

int bio_associate_blkcg(struct bio *bio, struct cgroup_subsys_state *blkcg_css)
{
    if (unlikely(bio->bi_css))
        return -EBUSY;
    css_get(blkcg_css);      // Crash 的来源
    bio->bi_css = blkcg_css;
    return 0;
}
```

看起来像是 `bio->bi_css` 字段跑飞了，然而我们的模块并不直接操纵该字段。
稍微了解了一下，该字段用来实现 `blkcg`, 我们似乎也没有用到这个功能。

- 第一个尝试：在 crash 的地方先把`bi_css` 字段置为 NULL. 内核还是挂了。
- 文明一点：不强制设 NULL, 而是先 `umount /sys/fs/cgroup/blkio`, 挂在同样的地方。

同样的代码，在 CentOS/Rocky 4.18.0 上没有问题（我们知道这个 4.18 内核
远比 Kylin 的 4.19.90 代码要新）。 因此较大可能是两个内核版本之间 BIO
相关接口的行为有变化。从 Call trace 的函数找起，并对比了模块在 CentOS
和 Kylin 分支的代码变迁，果然发现 `__bio_clone_fast` 的行为变了。

```c
// CentOS 4.18.0
int __bio_clone_fast(struct bio *bio, struct bio *bio_src, gfp_t gfp)
{
    int ret;

	bio_init(bio, bio_src->bi_io_vec, 0);
	bio->bi_opf = bio_src->bi_opf;
	bio->bi_partno = bio_src->bi_partno;
	bio->bi_disk = bio_src->bi_disk;

	ret = __bio_clone(bio, bio_src, gfp);
	if (ret)
	    bio_uninit(bio);
	return ret;
}

// openEuler-1.0-LTS （没有 Kylin 源代码，用 openEuler 做参考）
void __bio_clone_fast(struct bio *bio, struct bio *bio_src)
{
    BUG_ON(bio->bi_pool && BVEC_POOL_IDX(bio));

    /*
     * most users will be overriding ->bi_disk with a new target,
     * so we don't set nor calculate new physical/hw segment counts here
     */
    bio->bi_disk = bio_src->bi_disk;
    bio->bi_partno = bio_src->bi_partno;
    bio_set_flag(bio, BIO_CLONED);
    if (bio_flagged(bio_src, BIO_THROTTLED))
            bio_set_flag(bio, BIO_THROTTLED);
    bio->bi_opf = bio_src->bi_opf;
    bio->bi_ioprio = bio_src->bi_ioprio;
    bio->bi_write_hint = bio_src->bi_write_hint;
    bio->bi_iter = bio_src->bi_iter;
    bio->bi_io_vec = bio_src->bi_io_vec;

    bio_clone_blkcg_association(bio, bio_src);
}
```

两者在初始化语义上有重要区别。CentOS 4.18.0 该函数会调用 `bio_init()`,
而 Kylin 4.19.90 上没有初始化逻辑。在 `__bio_clone_fast()` 前加上
`bio_init(bio, NULL, 0)`, 问题解决之。

心情如同过山车，上上下下。🎢

这个（必现的）问题藏了一年，都没被发现。等问题报过来的时候：

> “这个问题您在跟吗？客户节后要做业务试运行，这个问题需要尽快处理掉~”

WTF.
