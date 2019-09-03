+++
title = "Chroot to Rescue!"
description = ""
date = "2019-09-03T10:56:08+08:00"
tags = ["sysadmin"]
categories = ["linux"]
+++

很久之前，为了合规，公司换用了合法的 VPN 提供商。然而自此之后，我的
VPN 接入就成了问题。

1. 对方号称有 Linux 客户端，但是官网不能下载；
2. 对方的设备提供 L2TP 服务，然而跑一段时间就会挂掉。

前几天 IT 部门的小伙终于从供应商要到了 Linux 客户端，抓到本地一看，脚
本和文档都写的贼矬。64-bit 系统上还是得跑 32-bit 的预编译好的程序。抱
着怀疑的态度，我在本地设置了一个 chroot 环境：

```sh
$ sudo apt-get install debootstrap schroot

# the VPN client is for Ubuntu 16.04
$ sudo debootstrap --variant=minbase --arch i386 xenial \
	/var/chroot/ http://mirrors.163.com/ubuntu/

$ sudo cat<<EOF >>/etc/schroot/schroot.conf
> [xenial]
> description=Ubuntu Xenial
> directory=/var/chroot
> users=guest
> groups=adm
> root-groups=root
> personality=linux32
> EOF

$ sudo cp -r vpn-client /var/chroot/home/guest/
$ sudo schroot -l
chroot:xenial
$ sudo schroot -c chroot:xenial -u root
```

进到 chroot 环境后，按照手册顺利拨号成功。根据提供的命令查看连接状态，
也一直显示成功。然而还是连不上公司的网络。无奈换用 Windows 机器，得到
登录报告：“用户已经登录，是否踢掉？”

Systemd v239 开始支持
[Portable Services](http://0pointer.net/blog/walkthrough-for-portable-services.html),
 系统有 239 更新后可以试试。

