+++
title = "What Is a PDU"
date = 2024-01-05T18:23:33+08:00
tags = ["storage"]
categories = ["linux"]
draft = false
+++

以前在 Ceph 上跑虚拟机的时候，偶尔看到 libvirt 报错：

```text
qemu unexpectedly closed the monitor: sending req data... pdu length 134, total length 142
the received hdr shows the err 0, the pdu length 198
...
```

当时不知道这个 `pdu` 是啥意思。搜了一圈 libvirt, Qemu, Ceph，kernel 的
源代码，也没找到类似上面报错的地方。最近看 linux SCSI 层代码的时候，碰
到一个 `blk_mq_rq_to_pdu()` ... 眼睛一亮。

StackOverflow 上找到了 `What is a PDU` 的[答案](https://stackoverflow.com/questions/68785800/in-the-linux-function-blk-mq-rq-to-pdu-what-is-a-pdu)：

> PDU is not Linux-specific. It's a Protocol Data Unit. From [Wikipedia](https://en.wikipedia.org/wiki/Protocol_data_unit)
>
>> In telecommunications, a protocol data unit (PDU) is a single unit
>> of information transmitted among peer entities of a computer
>> network. A PDU is composed of protocol-specific control information
>> and user data. In the layered architectures of communication protocol
>> stacks, each layer implements protocols tailored to the specific type
>> or mode of data exchange.
>
> So in device drivers, this is a generic term for whatever units of
> data are managed by the specific device or protocol.
