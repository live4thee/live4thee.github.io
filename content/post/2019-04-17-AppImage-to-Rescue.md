+++
title = "AppImage to Rescue!"
description = ""
date = "2019-04-17T22:37:48+08:00"
tags = ["KDE"]
categories = ["linux"]
+++

最近开始用[钉钉](https://www.dingtalk.com)写周报。因为没有 Linux 客户
端，之前一直用的网页版。无奈之下，在某个 Windows 虚拟机里面装了一个，
通过远程桌面访问。体验不是太好。

想起之前看热闹不嫌事大的同事推荐的 Electron 版的[客户端]
(https://github.com/nashaofu/dingtalk)，有现成的 deb 包，不过安装了之
后跑不起来。因此就去下载了一个 AppImage 包，体验还不错。至少是能写周
报了 - 而且还有一个截屏工具。

顺藤摸瓜，又下载了一个 AppImage 封装的微信（当然，也是非官方）客户端，
叫做 [wewechat](https://github.com/trazyn/weweChat)，用着还行。

真是非常感谢这些开发者。

用了半天后，还是转用了网页版。微信本来就用的少；至于那个钉钉客户端，关
闭 notification 不起作用，太闹腾了。

需要注意的是，这些 Electron App 共享 Chromium 的网络设置。我不想让它们
也走我配置的代理，可以通过 `--no-proxy-server` 来解决。[资料来源](https://github.com/electron/electron/blob/master/docs/api/chrome-command-line-switches.md)
