---
layout: post
title: "Xubuntu on XPS 13"
description: ""
category: linux
tags: [xfce]
---
{% include JB/setup %}

拿了一台 `Dell XPS 13 9350`，作为以后的开发机。自带的 Windows 10 Home
10240 被我我改装为 Xubuntu，省得装虚拟机，另外也方便 dogfood。

由于是新机器，也没啥需要备份。安装之前的准备工作只是 BIOS 的设置；

1. UEFI，但是关掉 Secure Boot
2. SATA 模式选项改为 AHCI

不幸的是，由于硬件比较新，Xubuntu 14.04.4 LTS 自带的内核没有无线网络的
驱动。还好事先选择的是 `Try Xubuntu without Installation`，因此还能重
新切回 Windows[^1]，看了一下无线设备是 `Dell DW1820A`，据说连 15.10 默
认也还没有驱动（4.4版本的内核才开始支持[^2]）。转而安装 16.04 LTS
 Beta1，无线、音频、蓝牙、音量键等等，全都工作。

整体感觉还行，除了键盘：

1. 没有小红点，手指需要离开键盘；
2. Fn 和 Ctrl 的位置不合理，按 Ctrl 组合键时很不方便；
3. 回车键上方的竖号键太小，影响命令行 pipeline；
4. 触摸板有点松垮。

长时间击键最好连一个外接键盘。

## 关于 Grub

第一次安装快结束的时候，报告 `grub-install /dev/nvme`[^3]，第二次重新
安装的时候可以了，可能是因为我关闭了 BIOS 里面的 Legacy Boot。

## 关于无线

我关闭了家里 Wi-Fi 的 ESSID 广播，nm-applet 中可以通过 `connect to
hidden network` 连上。但是机器重启后，不会自动重新连。重复以上步骤的时
候，可以在下拉框中勾选之前输入的 ESSID，密码不用再填，但是连不上。删掉
配置，重新来一遍却没有问题。把 ESSID 广播打开后，也不会自动重连，除非
删掉配置。

## 关于输入法

本来 Fcitx 工作的很好，重启后启动器上多了个小企鹅图标，输入中文时选词
框消失，正在输入的词下面会有下划线。禁用 `Fcitx Qt IMPanel` 即可。步骤
是：Configure Fcitx -> Adv -> Addon，取消掉 `Kimpanel`。或者粗暴一点，
直接删除 `fcitx-ui-qimpanel`。

[^1]:需要重新改回 SATA 模式，否则 Windows 启动时会蓝屏。
[^2]:[Dell XPS 13 9350 (late 2015 model) and Ubuntu](https://jultech.wordpress.com/2015/11/11/dell-xps-13-9350-late-2015-model-and-ubuntu/)
[^3]:[Unable to install GRUB in /dev/nvme](https://askubuntu.com/questions/696999/unable-to-install-grub-in-dev-nvme)
