+++
categories = ["work"]
date = "2017-10-14T22:00:18+08:00"
description = ""
tags = ["sysadmin"]
title = "Pain of OSS"
url = "/2017/10/14/pain-of-oss"
+++

## 题记

老同志说：“你要回到`Windows`的正道上来。” 年轻人说，“用`Mac`，省心。”

## 我要吐槽

吐槽一下 `Linux` 下各种不爽的坑。

### 关于投影

之前投影在公司一间会议室正常工作，另外一间死活不行。以至于，有时候我会
带着`Surface Pro`救急。但不知道啥时候开始，突然都工作了（可能是升级了
`KDE`），惊喜。

### 关于 IntelliJ

不知道什么时候开始，双击 `SHIFT` 鼠标大部分时候不会自动聚焦在搜索框，
而且搜索框跳出来有点慢。

### 关于 Firefox

作为火狐的死忠，在十五年前，它还叫 `firebird` 的时候，就一直使用。貌似
从 55.0.2 开始，几个旧接口实现的插件开始工作不大正常，比如：LastPass。
重新打开浏览器自动登录出错。VideoHunter 也没法用了。

### 关于 Chromium

Chromium （包括 Google Chrome）在 KDE 下没法调出文件选择框。因此微信网
页版，想要传文件的话，呵呵，洗洗睡。Bug已经报了半年多了，仍然没解决。
KDE/Chromium  这个问题上都有 bug，但是 KDE 的修复了，后者的还没修。后
来我又装了 `xfce`，文件选择框可以弹出。然后重新登录回 KDE，居然也能工
作了。惊喜。[传送门](https://www.reddit.com/r/kde/comments/5t7bjm/chromium_kdialog_keep_crashing/)

## 为啥不用 Windows?

喜欢命令行。`Cmd` 能力不够，`PowerShell` 没时间好好学。

## 为啥不用 Mac?

### Mac 的好处

`Pages`、`KeyNotes` 等生产力工具都免费，和水果手机搭配的很完美。各种优秀的
字体，`MacTeX` 也很好用。

### 不够好的

曾经用过一段时间。但是 `Brew`/`MacPorts` 没有 `apt`/`yun`/`dnf` 等等好用。
其 `readlink` 的行为和 `GNU/Linux` 下的不一样，以至于我以前在 `Mac` 下写了
个 `Python` 脚本 `realpath` 来代替。没有 `KVM`，嗯。

## 彩蛋

关于 `CherryPy` - 最近被一个八阿哥折腾得半死。以目前所有的蛛丝马迹来看，
基本确定是个 `CherryPy` 的坑，等我明天再来剖析之。
