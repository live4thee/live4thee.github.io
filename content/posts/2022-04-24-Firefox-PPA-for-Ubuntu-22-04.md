+++
title = "Firefox PPA for Ubuntu 22.04"
date = 2022-04-24T20:55:26+08:00
tags = ["xfce"]
categories = ["linux"]
draft = false
+++

内容来自 [https://balintreczey.hu/](https://balintreczey.hu/blog/firefox-on-ubuntu-22-04-from-deb-not-from-snap/)

22.04 里搭载的 firefox 是用 snap 打包的，不过还是有用回 deb 的方法：使
用 Mozilla 团队维护的 PPA (Personal Package Archive) 仓库。

```sh
$ cat /etc/apt/preferences.d/firefox-no-snap 
Package: firefox*
Pin: release o=Ubuntu*
Pin-Priority: -1
```

然后，删掉已有的 firefox，安装 PPA 里的：

```sh
$ sudo apt purge firefox
$ sudo snap remove firefox
$ sudo add-apt-repository ppa:mozillateam/ppa
$ sudo apt update
$ sudo apt install firefox
```

PPA 里的包不会自动无人值守升级（nattended-upgrade），解决办法：

```sh
echo 'Unattended-Upgrade::Allowed-Origins:: "LP-PPA-mozillateam:${distro_codename}";' \
    | sudo tee /etc/apt/apt.conf.d/51unattended-upgrades-firefox
```

需要注意的是，这个 PPA 也包含了 thunderbird - 比 22.04 里的新。
