+++
title = "Fcitx Icon Issue"
date = 2022-04-18T19:39:33+08:00
tags = ["xfce"]
categories = ["linux"]
draft = false
+++

最近把 20.04 升级到 22.04 后发现切换输入法的时候，图标比例有点怪，像是
大图标原样（非按比例）显示在了 panel 上。

查了一下，xfce 的 panel references 里面设置了：

- ‘icons’ 的 ‘Adjust size automatically’ 为打开；
- ‘Row size (pixels)’ 是 24 像素。

临时解决方法参考的
[xfce-panel 的 issue tracker](https://gitlab.xfce.org/xfce/xfce4-panel/-/issues/404#note_22822)（问题来源于 dbusmenu-gtk 库）：

```sh
$ dpkg -L fcitx-googlepinyin | grep icon.*pinyin | xargs file
/usr/share/fcitx/imicon/googlepinyin.png:                   PNG image data, 48 x 48, 8-bit colormap, non-interlaced
/usr/share/icons/hicolor/16x16/apps/fcitx-googlepinyin.png: PNG image data, 16 x 16, 8-bit colormap, non-interlaced
/usr/share/icons/hicolor/48x48/apps/fcitx-googlepinyin.png: PNG image data, 48 x 48, 8-bit colormap, non-interlaced
```

可以看到 `fcitx-googlepinyin` 里面只有 16x16, 48x48 两种尺寸的图标。制
作并安装一个 24x24 的图标就可以了：

```sh
$ convert -resize 24x24 /usr/share/fcitx/imicon/googlepinyin.png /tmp/fcitx-googlepinyin.png
$ xdg-icon-resource install --size 24 /tmp/fcitx-googlepinyin.png
```
