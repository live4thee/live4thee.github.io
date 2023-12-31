+++
title = "SATA Hotplug"
date = 2023-12-31T13:25:00+08:00
tags = ["storage"]
categories = ["linux"]
draft = false
+++

SATA/SAS 规范中要求支持热插拔，因此 SATA/SAS 平台在热插拔上应该问题较少 -- 当然也还是有一些坑。
[kernel.org](https://kernel.org)有篇[Wiki](https://raid.wiki.kernel.org/index.php/Hardware_issues)讲述了 SATA Hotplug 的硬件要求。有点意思。


## 主板/磁盘控制器

芯片组是否兼容 AHCI? 内核模块是否支持热插拔和电源管理？比如，Linux >= 2.6.19


## 硬盘本身

当前 15-pin SATA/SAS 电源连接口都是可热插拔的。

![SATA Pins](/media/sata-15pins.jpg)

针脚有长短，其中长一点的叫 `Staggered Pins`. 在磁盘侧，第 3、7、13 针是突出针。

## 连接线

连接线侧的第 4、14 针是突出针，用于接地，但看实物没看出来。Wiki 里有个
**Important warning** 是这么写的：

> Normal 15-pin SATA power cable receptacle, found in ordinary power
> supplies or computer cases, does not have pins 4 and 12 staggered!
> In fact, it is quite hard to find a hotplug-compatible SATA power
> receptacle.

## 插拔顺序

是的，有顺序。

- 插 - 先插电源线，后插数据线。
- 拔 - 先拔数据线，后拔电源线。

[^connector]: https://en.wikipedia.org/wiki/SCSI_connector
