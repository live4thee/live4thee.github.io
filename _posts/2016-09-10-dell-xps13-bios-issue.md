---
layout: post
title: "Dell XPS13 BIOS Issue"
description: ""
category: linux
tags: [misc]
---
{% include JB/setup %}

这两天偶尔出现无线鼠标不工作的情况，引起一堆折腾。

## 现象

开机后，无线鼠标不工作，`dmesg`发现如下错误：

~~~
usb 1-1: device descriptor read/64, error -71
usb 1-1: new full-speed USB device number 4 using xhci_hcd
usb 1-1: Device not responding to setup address.
~~~

怀疑是 Linux USB 驱动的问题，
且[launchpad](https://bugs.launchpad.net/ubuntu/+source/linux/+bug/1565292)
上搜到一个类似报告，但已经是半年前的了。

1. 鼠标电池刚换不久，且插在同事M的电脑可以工作；
2. 同事M的无线鼠标在我的电脑上可以工作；
3. 机房一只有线鼠标接上后，灯亮，但也不工作。

## 第一次尝试

自己手工编译了 `4.8.0-rc5`，重启后再次插入无线鼠标，第一次不行，第二次
可以了。加深了驱动可能有问题的怀疑。

{% highlight bash %}
cd 4.8.0-rc5
/bin/cp -f /boot/config-`uname -r` .config
make menuconfig

make-kpkg clean
fakeroot make-kpkg --initrd --revision=liq-9350 kernel_image -j 4
{% endhighlight %}

## 第二天

启动电脑后发现，无线鼠标还是罢工了。新老内核都不行。搜到一篇文章，
[How to fix "device not accepting address" error](https://paulphilippov.com/articles/how-to-fix-device-not-accepting-address-error)
，怀疑是硬件问题。按照文章里的建议，关机、重启，试了几次，悲剧依旧。于
是，我进BIOS里面查看USB设置，关掉了几个`看似无用`的选项。

## 更悲剧了

退出BIOS，重启发现没有 `Dell` 的 logo，启动时显示器的分辨率很低。能够
顺利引导至 GRUB （显示很差），然后进入系统。但是：

1. 触摸板中下的LED灯规则的闪烁，7次白色，2次橙色，循环往复；
2. 再也进不了 BIOS 了。

Google了一下，找到 reddit 一个
[帖子](https://www.reddit.com/r/Dell/comments/41qqs8/xps_13_9350_bios_setup_not_accessible/)
，确定这是因为在 BIOS 的 USB 设置里面取消掉 Thunderbolt 导致的。Dell
的 BIOS 很坑爹啊！

## FreeDOS

发现官网有新 BIOS，因为之前做过一个现成的 FreeDOS 启动U盘，专门用来升
级BIOS的。希望升级一下 BIOS 可以绕过该问题。但是，启动不了。往U盘写了
个 UEFI GRUB，可以进入 grub，但是加载 FreeDOS 的时候会死掉。

## 摸黑操作

翻开笔记本背面，想给BIOS放电，但是六颗眼屎大的螺丝居然都是六角梅花。吐
血。看到另一篇[文章](eggheadstock.com/dell-xps-13-unable-access-bios/)，
说先F12改变启动设置后再F2，可以看见BIOS部分设置，但是需要摸黑操作。折
腾了几把，运气不错，顺利恢复。再次试了下，FreeDOS也可以启动了。

## 结案

大家都是用的 DELL XPS 13，但是：

1. DELL 的 BIOS 很坑；
2. 鼠标不工作确实是硬件问题，不是电脑的USB口，而是我的鼠标坏了；
3. 我的鼠标在同事G的笔记本也不能工作，在M的笔记本却一直能工作；
4. 之前那个有线鼠标在G的笔记本确实也不能工作；
5. BIOS操作界面对键盘不友好（比如：不带热键，幸好还有TAB）是耍流氓。
