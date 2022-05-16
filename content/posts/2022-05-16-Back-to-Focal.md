+++
title = "Back to Focal"
date = 2022-05-16T16:14:08+08:00
tags = ["xfce"]
categories = ["linux"]
draft = false
+++

20.04 升级到 22.04 后用了一个月出头，突然某次重启后发现无线网络死活连
不上了。

# Wi-Fi issue

现象：NetworkManager 没有任何可用的设备，不但没有 Wi-Fi，有线也识别不了。

- 内核重启前没升级过，因此不应该是驱动问题；
- `ip link set wlp58s0 up` 后，无线网卡还是保持 DOWN 状态；
- 因此，停止 nm 后手动用 wpa_supplicant 和 iwconfig 仍然无法连接；
- 但是，`iw scan` 工作正常；
- 重启前升级过 systemd，回滚后仍然有问题。

做了个 USB 启动盘试了一下，无线没有问题。因此，可能还是某个未知的软件
更新导致的 -- 虽然，检查了 `/var/log/apt/history.log` 后，除了 `systemd`
没有任何其它发现。

# Back to Focal

## NeoVim

选择了最小安装，后来装 vim 的时候就选了 NeoVim，少占一点空间。导回备份
后发现 vim-fugitive 没有加载。原来 Neo 有自己的配置路经：

```sh
$ ln -s ~/.vim ~/.config/nvim 
$ ln -s ~/.vimrc ~/.config/nvim/init.vim 
```

## Xubuntu to Ubuntu

升级之前 Xfce 一直用的很顺。对 GNOME3 的交互是在无感，也实在不想再折腾
了，就用 ubuntu 罢。网上找了个 `gtk.css`, 调小窗口标题栏的高度。

默认是 ibus, 皮肤稍微现代一点，能输入 Emoji 😀 暂别 fcitx

- 关掉 Ubuntu Dock；
- 忍住了换图标主题的冲动；
- 隐藏桌面图标、回收站、home目录；
- 重设一些快捷键；
- 装上 texlive-xetex, emacs-nox, thunderbird, libreoffice.

用了两三天发现鼠标反应很慢。原来是电池没电⚡了。

So far so good.
