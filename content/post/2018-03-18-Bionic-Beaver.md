+++
title = "Bionic Beaver"
description = ""
date = "2018-03-18T00:01:08+08:00"
tags = ["KDE"]
categories = ["linux"]
+++

把用了两年的 `Kubuntu 16.04` 升级到了 `18.04 Bionic Beaver`. 基本上所
有的东西都工作得很好，除了 `Chromium`（依赖GTK）, `LibreOffice`（依赖
Java） 以及 `darktable`（依赖GTK）的主题看着像是回到了上个世纪。

对于前两者，解决办法很简单，就是安装相应的 KDE 主题：

```
sudo apt-get install breeze-gtk-theme
sudo apt-get install libreoffice-kde4
```

即使有了 `breeze-gtk-theme`，`darktable` 还是莫名出现了很粗的红边框。
解决办法是把
[这里](https://www.mail-archive.com/darktable-user@lists.darktable.org/msg03021.html)
贴出来的一个 `CSS` 文件存成 `darktable.css`，放到目录
`~/.config/darktable/` 下即可。
