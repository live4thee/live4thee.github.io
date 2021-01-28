+++
categories = ["linux"]
date = "2018-02-12T16:42:33+08:00"
description = ""
tags = ["KDE"]
title = "Linux Desktop (2)"
url = "/2018/02/12/linux-desktop-2/"
+++

## 输入法

之前一直用 `ibus-pinyin` 以及后来的 `ibus-libpinyin`，无法摆脱的苦恼是
词库。选了自带的词库后感觉输入还是不接地气。看热闹不嫌事大的同事说，
“用中州韵吧！”[^f1] 呵呵，完全不上当。

装了一个 [fcitx](https://fcitx-im.org/wiki/Fcitx)，当年我的 nc4200 小
本本上跑 [wmii](https://wiki.debian.org/Wmii/) 的时候，一直用它。

```sh
sudo apt-get install fcitx-googlepinyin
im-config
fcitx-configtool

sudo apt-get remove --purge ibus
sudo apt-get autoremove --purge
```

## 音频

之前发现一个问题，笔记本插着耳机的时候，重启后耳机没有声音。重新插拔一
下耳机就好。这个
[bug](https://bugs.launchpad.net/ubuntu/+source/alsa-driver/+bug/1583801)
放着快两年了，一直没有修复。执行 `alsactl restore` (不用sudo)可以恢复
声音，不过重置后的默认音量略大。


[^f1]: 鼠须管（Squirrel）是一个 Mac 平台的输入法，它基于 RIME／中州韵输入法引擎。RIME 是一个跨平台的输入法框架，在 Linux 下，名为 中州韵，Windows 则为小狼毫。
