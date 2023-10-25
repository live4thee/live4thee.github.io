+++
title = "DeLL OptiPlex Micro 7010"
date = 2023-10-25T18:39:50+08:00
tags = ["misc"]
categories = ["linux"]
draft = false
+++

手头的 DeLL XPS13 已经用了超过七年半，虽然内存只有 8 GiB ，但是跑
Linux 一直还是挺快。去年九月电池鼓包换了个第三方电池，最近也开始鼓了
-- 不但撑得弹开一颗螺丝，甚至连常用的 CTRL, ESC 等按键也不灵了。

周末在家拿夫人闲置的 MacBook 练了练，还是不大喜欢。下单买了一台采用迷
你机箱的 OptiPlex 7010, 恰好同事有个 Debian 12 安装盘，整盘格了预装的
Win11, 直接 EFI boot, 也不用关 Secure Boot, 只需要设置从 U 盘启动，算
是非常方便了。

## fwupdmgr

安装好后，先用 fwupdmgr 更新了 BIOS 固件、NVMe 固件。

## 输入法

折腾了一会。

干掉默认的 ibus, 用 fcitx. 注意点是，用英文安装后，“Input Method" 里面
只有一个 "Keyboard - English (US)"，需要添加 "Google Pinyin" 而不是照
猫画虎添加 "Keyboard - Chinese".

## 任务栏

fcitx 的输入法状态看不见（没有 ubuntu 做的细致）。

```sh
$ apt-get install gnome-shell-extension-top-icons-plus
```

然后，Extensions 里面打开 TopIcons Plus 即可。

## 高度极不合理的窗口 Title Bar

另一个被诟病已久的 GTK3 设计，网上抄一个
[gtk.css](https://askubuntu.com/questions/1358632/how-to-reduce-the-height-of-headerbar-titlebar-of-gtk3-apps-using-csd)
放到 ~/.config/gtk-3.0/ 即可。

## 奇怪的 Emacs Warning

启动 Emacs 后报警（虽然不影响使用）：

```text
Cannot look up eln file as no source file was found for ~/.emacs.elc
```

看起来是个 [bug](https://debbugs.gnu.org/db/59/59424.html), 解决办法是
删掉 .emacs.elc 或者把 .emacs.el 挪到 .emacs.d/init.el, 这样
byte-compile init.el 后不会报警。

## 待解决问题

### Indexing

tracker-miner-fs CPU 100% - GNOME 的默认索引服务，不是挖矿。可能是一下
转了太多数据到本机，修改了一下需要索引的目录列表，放几天看看。

### Login

偶现 logout 后再 login 失败，只能切到终端重启 GDM. 之前在 ubuntu 22.04
LTS 也碰到过。
