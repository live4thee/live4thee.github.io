+++
title = "org-link-set-parameters"
date = 2022-06-17T17:05:31+08:00
tags = ["orgmode"]
categories = ["linux"]
draft = false
+++

## back to fcitx

最近做了很多文字工作，发现 ibus 虽然视觉好看一点，但中文输入的时候偶尔
会切换输入法卡住，接着就只能输入英文了（虽然切换动画还是继续挺好看）。
因此，还是删了 ibus 重回 fcitx - 虽然略朴素一点。

## 22.04 LTS with 20.04 kernel

22.04 默认启用了 wayland, 除了 mpv 会报个 warning（容易解决）之外，截
图工具 flameshot (11.0) 也只能像系统默认截图工具一样，只能截图没法编辑。
回到 Xorg 保平安。无论是 wayland 还是 xorg, 我的 XPS13 使用 22.04 的内
核屏幕会偶尔抖动，尤其是用 xfreerdp 的时候。幸好长了心眼留着了 20.04
的内核，没有屏幕抖动问题。

网上搜到的绝大部分设置默认内核启动项的教程都已过时。下面是
`grub-set-default` 设置默认启动项成功后，再次 `list` 的结果：

```sh
$ grub-editenv list
saved_entry=gnulinux-advanced-b9e3bb1e-c04c-4695-927d-13682cfab29c>gnulinux-5.13.0-41-generic-advanced-b9e3bb1e-c04c-4695-927d-13682cfab29c
```
## orgmode with text color

用 orgmode 写文档的时候，经常希望能给文字加个颜色。因此找了一下解决方
案，找到一个[帖子](https://stackoverflow.com/questions/45580169)，虽然
示例代码是老一点的 orgmode, 思路是对的。对照新 API 文档写了一个：

```lisp
;; neat trick to color text. For example: 
;;   this is [[color:red][red]]
;; c.f. https://stackoverflow.com/questions/45580169
(org-link-set-parameters
 "color"
 :follow (lambda (path) (message "You clicked me."))
 :export (lambda (color desc backend) 
           (cond
		    ((eq backend 'html)
			 (format "<span style=\"color:%s;\">%s</span>" color desc))
		    ((eq backend 'latex)
			 (format "{\\color{%s}%s}" color desc))
		    (t desc))))
```

## libfuse2

平时用 draw.io 画图，图方便用了个 AppImage 版本。升级了系统后发现 AppImage
起不来了，因为依赖 libfuse2，而系统默认升级到了 libfuse3.

```sh
$ sudo apt-get install libfuse2
$ deborphan
libfuse2:amd64
$ sudo apt-mark hold libfuse2
libfuse2 set on hold.
$ deborphan
```
