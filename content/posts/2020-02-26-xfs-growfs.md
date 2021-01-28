+++
title = "xfs_growfs"
date = 2020-02-26T22:45:36+08:00
tags = ["sysadmin"]
categories = ["linux"]
draft = false
+++

跑在公司内网的开发机系统盘只有 6GB，因此前段时间碰到了 *surefire* 插件
在 */tmp* 目录下写入大量 report 数据把磁盘写满的问题。后来建了一块数据
盘专门挂载到 */tmp*, 没想到数据盘分配在了 NFS 上，然后前段时间 NFS 又
挂了。趁着上午 NFS 刚恢复，把数据盘卸掉，扩容系统盘。

下面是个操作记录。Xfs 在线扩容，不要求挂 ISO 也不要求盘是由 LVM 管理。

首先，可以看到，vda 确实扩到了 40GB，但是分区表没变，系统盘还是 6GB。

```sh
# lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0  400G  0 disk
└─sda1   8:1    0  400G  0 part /mnt/nfs-data
vda    253:0    0   40G  0 disk
├─vda1 253:1    0    2G  0 part [SWAP]
└─vda2 253:2    0    6G  0 part /
```

安装工具 growpart，扩展 vda 的第二个分区（系统盘所在的分区）。

```sh
# yum --disablerepo=* --enablerepo=ali* install -y cloud-utils-growpart
# growpart /dev/vda 2
CHANGED: partition=2 start=4196352 old: size=12580864 end=16777216 new: size=79689695 end=83886047
# lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0  400G  0 disk
└─sda1   8:1    0  400G  0 part /mnt/nfs-data
vda    253:0    0   40G  0 disk
├─vda1 253:1    0    2G  0 part [SWAP]
└─vda2 253:2    0   38G  0 part /
```

再次 lsblk 可以看到系统盘已经检测为 38 GB 了。`xfs_growfs` 打完收功。

```sh
# xfs_growfs /
meta-data=/dev/vda2              isize=256    agcount=26, agsize=393152 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=0        finobt=0 spinodes=0
data     =                       bsize=4096   blocks=9961211, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=0
log      =internal               bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
data blocks changed from 1572608 to 9961211
# df -h /
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda2        38G  3.3G   35G   9% /
```

参考：[Extending a Linux File System After Resizing a Volume](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/recognize-expanded-volume-linux.html)
