---
categories:
- linux
date: 2016-03-20T00:00:00Z
description: 虚拟机的好处
tags:
- vm
- xfce
title: Benifits of VMs (2)
url: /2016/03/20/benifits-of-vms-2/
---


由于我的 vmdk 文件是分割过的，把虚拟机从 vmdk 迁移到 KVM 下稍微有点麻烦。

1. 从 VMware 官方下载 `vmware-vdiskmanager`[^1]，解开后拷贝到VMware
   Player 的安装目录，否则会提示 DLL 找不到。

2. 把分割的虚拟机镜像合并起来：
   `vmware-vdiskmanager -r "Fedora 64bit.vmdk" -t 0 fc64.vmdk`

3. 把合并后的虚拟机文件拷贝到 Linux 里面，再转换成 qcow2 格式：
   `qemu-img convert -f vmdk -O qcow2 fc64.vmdk fc64.qcow2`

启动虚拟机的脚本如下：

~~~
#!/bin/sh

QEMU=/usr/bin/qemu-system-$(uname -m)

$QEMU -enable-kvm -m 1024 -smp cpus=2 \
  -net nic -net user,net=1.0.2.0/24,hostfwd=tcp::2222-:22 \
  fc64.qcow2
~~~

顺便记录一下，如何自动关闭蓝牙（默认是登录后自动打开着）。

1. 在 /etc/rc.local 里面加上 `rfkill block bluetooth` [^2]

2. 运行 `gsettings set org.blueman.plugins.powermanager auto-power-on
   false` [^3]

以上两步缺一不可，
[参考1](https://wiki.archlinux.org/index.php/Blueman#Disable_auto_power-on)
，[参考2](http://atomato.me/blog/2014/08/gsettings-in-a-nutshell/)。

[^1]: VMware workstation 自带了该工具，而 Player 没有。
[^2]: 开机的时候自动关闭蓝牙设备。
[^3]: 让 `blueman` 不要自动打开蓝牙。
