+++
title = "Xfce Again"
date = 2020-04-29T22:38:24+08:00
tags = ["xfce"]
categories = ["linux"]
draft = false
+++

分析了大半天 crash dump, 有点晕。

## VMware player

本机有个 VMware Player, 从 Kubuntu 18.04 升级到 20.04 后，内核模块编译
失败。仔细找了一下，原来代码都放到 `/usr/lib/vmware/modules/source/`
里去了，以 tar 包的形式存在。升级 vmplayer 解决之。

## Headphone problem

升级了系统后，插入耳机除了电脑的模拟输出自动 Mute 之外, 耳机没声音了。
本以为是 KDE 的问题，换成 Xfce 后问题依旧。[Regolith Linux](https://regolith-linux.org/) 倒
是对耳机检测做的挺好，但是 i3wm 没有 stack 模式，另外它的浮动窗口模式也
不能满足我的需求。

查了 PulseAudio 和 Alsa 并
没有发现什么破绽。作为临时绕过的办法：

~~~sh
$ alsactl init
$ alsamixer # 调音量，关 Speaker，开 Headphone。
$ alsactl store -f alsa.state
~~~

耳机没声音的时候，做一个：

~~~sh
$ alsactl restore -f alsa.state
~~~

绑定一个快捷键，勉强凑合。

## Xfce

明显比 KDE Plasma 快很多。
