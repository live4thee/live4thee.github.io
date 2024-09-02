---
title: "MSG_ZEROCOPY"
date: 2024-08-30T16:56:38+08:00
tags: [ "networking" ]
categories: [ "linux" ]
draft: false
---

之前听F老师说，手动修改代码后，本机 Qemu 热升级打开零拷贝支持后效果非
常好。因此拿内核代码树里的[测试代码](https://github.com/torvalds/linux/blob/master/tools/testing/selftests/net/msg_zerocopy.c)试了试，
却发现几乎没啥区别：并且每次都报 `zc=n`, 也就是并没有成功做零拷贝。

在F老师的帮助下，`perf` 粗粗地看了看，相关内核路径确实也跑到了。奇怪。
前几天看 SNIA SDC EMEA 2022 [视频](https://b23.tv/hXtV52J)的时候，里面
提到打开零拷贝效果明显，忍不住又探究了一番。

## MSG_ZEROCOPY

### 语义

[MSG_ZEROCOPY](https://docs.kernel.org/networking/msg_zerocopy.html)只是一个提示(hint)，内核会避免做拷贝并入队一个通知，但并
不能保证一定会消除拷贝开销。重要的是，该参数实际上也改变了`send()`系统调用的语义：

1. 内核会锁定相关页面，通过共享内存的方式，把待发送的数据共享给网络栈；
2. 因此发送过程中用户不能修改 `buf` -- 虽然此时 `send(fd, buf, ...)` 可能已返回；
3. `buf` 完成使用后，内核通过发送 zc completion notification 通知用户。

### BUG

测试代码曾经有 BUG, 会导致代码其实没有去读取 completion 通知。
字节的同学提交了一个[补丁](https://lore.kernel.org/netdev/4de9f008-ccb1-4077-b415-d7373caeb3cc@bytedance.com/T/)。

> Typically, it will start the receiving process after around 30+
> sendmsgs. However, as the introduction of commit dfa2f0483360 ("tcp:
> get rid of sysctl_tcp_adv_win_scale"), the sender is always writable
> and does not get any chance to run recv notifications.  The selftest
> always exits with OUT_OF_MEMORY because the memory used by opt_skb
> exceeds the net.core.optmem_max.

我用的测试代码已经包含了及时读取 notification 的修复，但仍然报 `zc=n`.

## 再探

### 没有免费午餐

再次仔细阅读[文档](https://docs.kernel.org/networking/msg_zerocopy.html)，
得到如下信息：

1. 网络设备需要支持 scatter-gather I/O;
2. 收到 zc completion 不代表发送完成；
3. 内核通过在 `ee_code` 中设置 `SO_EE_CODE_ZEROCOPY_COPIED` 告知用户
   当前设备无法使用零拷贝，后续不必设置 `MSG_ZEROCOPY`.

无法使用零拷贝却又做了相关工作，还得回退到拷贝模式，反而会有性能损耗。

```sh
$ ethtool -k bond1 | grep scat
scatter-gather: on
        tx-scatter-gather: on
		tx-scatter-gather-fraglist: off [requested on]
```

### `zc=n` 的原因

还是在 StackOverflow 找到了[答案](https://stackoverflow.com/questions/61203647)：

> After tracing kernel stack, i found that skb_copy_ubufs lead to the
> result, which was called by dev_queue_xmit_nit. It means that
> MSG_ZEROCOPY notification will return SO_EE_CODE_ZEROCOPY_COPIED if
> there are network taps in use. For my case, they are dhclient and
> lldpd.service. After killing them, the code disappeared.

默认使用最大 payload 进行测试，在一个相对空闲的环境进行测试，成功使用
零拷贝时得出的数据比较有波动，并且不具有性能优势。

```sh
# 不使用零拷贝
$ time ./msg_zerocopy -C 39 -4 tcp -D 10.10.3.4  
tx=129909 (8106 MB) txc=0 zc=n

real    0m4.201s
user    0m0.049s
sys     0m1.988s

# 设置使用零拷贝，实际未能成功零拷贝
$ time ./msg_zerocopy -C 39 -4 tcp -D 10.10.3.4 -z
tx=90078 (5621 MB) txc=90078 zc=n

real    0m4.242s
user    0m0.022s
sys     0m2.211s

# 关掉 lldpd 设置使用零拷贝，实际成功进行了零拷贝
$ time ./msg_zerocopy -C 39 -4 tcp -D 10.10.3.4 -z
tx=108938 (6798 MB) txc=108938 zc=y

real    0m4.201s
user    0m0.023s
sys     0m1.108s

$ time ./msg_zerocopy -C 39 -4 tcp -D 10.10.3.4 -z
tx=70444 (4395 MB) txc=70444 zc=y

real    0m4.202s
user    0m0.018s
sys     0m0.841s
```

用 `bpftrace` 跟踪了一下，打开零拷贝，由于 lldpd 服务而未能进行零拷贝
时，内核代码会走 `skb_copy_ubufs()`. 成功进行零拷贝不会进入该函数。

```sh
$ bpftrace -e 'kretfunc:skb_copy_ubufs{printf("%s\n", kstack); exit()}'
Attaching 1 probe...

        exit_misc_binfmt+53365
        bpf_get_stackid_raw_tp+82
        exit_misc_binfmt+53365
        exit_misc_binfmt+60989
        skb_copy_ubufs+5
        dev_queue_xmit_nit+451
        dev_hard_start_xmit+106
        __dev_queue_xmit+2060
        ip_finish_output2+621
        ip_output+112
        __ip_queue_xmit+365
        __tcp_transmit_skb+2561
        tcp_write_xmit+1085
        tcp_sendmsg_locked+677
        tcp_sendmsg+39
        sock_sendmsg+66
        ____sys_sendmsg+495
        ___sys_sendmsg+124
        __sys_sendmsg+87
        do_syscall_64+91
        entry_SYSCALL_64_after_hwframe+97
```

测试环境：kernel-4.18.0.  Stack Overflow 的回答中用的 5.4.0
