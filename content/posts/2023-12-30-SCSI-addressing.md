+++
title = "SCSI Addressing"
date = 2023-12-30T17:06:39+08:00
tags = ["storage"]
categories = ["linux"]
draft = false
+++

HBTL 经常容易和 LaTeX 图片位置 `htbp` 记岔，好记性不如烂笔头。记录一下。
内容主要翻译自[RedHat](https://access.redhat.com/articles/17628)文档。

## HBTL

HBTL - Host:Bus:Target:LUN 也被称为 HCIL 寻址。[^hcil] SCSI 设备热插拔
前后对应的块设备名可能会发生变化，比如 `/dev/sda` 变成 `/dev/sdb`，但
是设备的 HBTL 地址不换槽位就不会变。[^addr]

名称 | 含义
--|--------
H | SCSI Host ID 是 SCSI Host Bus Adapter (HBA) 卡的 ID. 该 ID 是内核发现 HBA 卡后分配的。
B | B 对应 HBA 卡内的 Bus(也叫 Channel) ID，也是内核分配的。大部分 SCSI 控制器只有一个 bus/channel，因此对应的 ID 大都为 0;
T | Target 是 Bus 内的设备 ID，和 H 以及 B 一样也是内核分配的。
L | Logical Unit Number (LUN) SCSI target 内的一块逻辑磁盘，一个磁带设备等等。和 H、B、T不一样，这个数字是存储设备自己分配的。

命令示例：

```sh
$ cat /proc/scsi/scsi
Attached devices:
Host: scsi0 Channel: 00 Id: 00 Lun: 00
  Vendor: ATA      Model: SSDSC2KG019T8R   Rev: DL63
  Type:   Direct-Access                    ANSI  SCSI revision: 05
Host: scsi1 Channel: 00 Id: 00 Lun: 00
  Vendor: ATA      Model: ST2000NM000A-2J2 Rev: TN01
  Type:   Direct-Access                    ANSI  SCSI revision: 05

$ lsscsi -N
[0:0:0:0]    disk    ATA      SSDSC2KG019T8R   DL63  /dev/sda
[1:0:0:0]    disk    ATA      ST2000NM000A-2J2 TN01  /dev/sdb

$ sg_map -x
/dev/sg0  0 0 0 0  0  /dev/sda
/dev/sg1  1 0 0 0  0  /dev/sdb
      ^   H:B:T:L  ^        ^
	  |            |        |
	  |            |        `---- SCSI upper layer device
	  |            `-- type
	  |
	  `-- SCSI generic device
```
其中，`SCSI device type` 在头文件中定义如下：

```c
/* file: /usr/include/scsi/scsi.h */
#define TYPE_DISK           0x00
#define TYPE_TAPE           0x01
#define TYPE_PROCESSOR      0x03    /* HP scanners use this */
#define TYPE_WORM           0x04    /* Treated as ROM by our system */
#define TYPE_ROM            0x05
#define TYPE_SCANNER        0x06
#define TYPE_MOD            0x07    /* Magneto-optical disk -
                                     * - treated as TYPE_DISK */
#define TYPE_MEDIUM_CHANGER 0x08
#define TYPE_ENCLOSURE      0x0d    /* Enclosure Services Device */
#define TYPE_NO_LUN         0x7f
```

常见的 SCSI upper layer 设备类型、设备名以及内核模块对应关系：

类型    |  设备名    |  内核模块
--------|------------|---------------
disk    | /dev/sda   | sd_mod.ko
cd/dvd  | /dev/sr0   | sr_mod.ko
tape    | /dev/st0   | st_mod.ko

## SCSI 地址图例

HBTL 寻址其实是一种 routing 方法。

```text
   HBA (Host Bus Adapter)                                                     SCSI
 e.g. PCI storage controller                                                  address
+---------------------------+              +----------------------------+     h:b:t:l
| SCSI      | Bus/Channel(0)+------------->+ SCSI Target (0) |  LUN 0   |  << 0:0:0:0
| Host (0)  +---------------+              |                 +----------+
|           | Bus/Channel(1)+------+       |                 |  LUN 1   |  << 0:0:0:1
+---------------------------+      |       |                 +----------+
                                   |       |                 :          |
                                   |       |                 +----------+
                                   |       |                 |  LUN n   |  << 0:0:0:n
                                   |       +----------------------------+
                                   |
                                   |
                                   |       +----------------------------+
                                   +------>+ SCSI Target (0) |  LUN 0   |  << 0:1:0:0
                                           |                 +----------+
                                           |                 |  LUN 1   |  << 0:1:0:1
                                           |                 +----------+
                                           |                 |  LUN 2   |  << 0:1:0:2
                                           |                 +----------+
                                           |                 :          |
                                           |                 +----------+
                                           |                 |  LUN n   |  << 0:1:0:n
                                           +----------------------------+
```

## 多路径

一个 LUN 可以有多个寻址方式。比如，下面是 FC 的例子：

```text
   HBA (Host Bus Adapter)
 e.g. PCI storage controller                                                SCSI
+--------------------------+   +-----+   +-------------------------+      Addresses
| SCSI     | Bus/Channel(0)+-->+  F  +-->+ SCSI Target (n) | LUN 0 | << 0:0:0:0 AND 1:0:2:0
| Host (0) |               |   |  C  |   |                 +-------+
|          |               |   |     |   |                 | LUN 1 | << 0:0:0:1 AND 1:0:2:1
+--------------------------+   |  S  |   |                 +-------+
                               |  w  |   |                 :       |
+--------------------------+   |  i  |   |                 +-------+
| SCSI     | Bus/Channel(0)+-->+  t  |   |                 | LUN n | << 0:0:0:n AND 1:0:2:n
| Host (1) |               |   |  c  |   +-------------------------+
|          |               |   |  h  |
+--------------------------+   +-----+
```

怎么知道上面的 0:0:0:0 和 1:0:2:0 最终寻址到同一个 LUN 呢？查 WWN 或
者 SCSI ID. [^wwid]

```sh
$ lsscsi -i | grep sda
[0:0:0:0]    disk    ATA    SSDSC2KG019T8R   DL63  /dev/sda   355cd2e41507fe2a0

$ lsscsi -w | grep sda
[0:0:0:0]    disk    ATA    SSDSC2KG019T8R   DL63  0x55cd2e41507fe2a0              /dev/sda

$ /lib/udev/scsi_id -g -u /dev/sda
355cd2e41507fe2a0

$ sg_inq -p 0x83 /dev/sda
VPD INQUIRY: Device Identification page
  Designation descriptor number 1, descriptor length: 24
    designator_type: vendor specific [0x0],  code_set: ASCII
    associated with the Addressed logical unit
      vendor specific:   PHYG908301LF1P9DGN
  Designation descriptor number 2, descriptor length: 72
    designator_type: T10 vendor identification,  code_set: ASCII
    associated with the Addressed logical unit
      vendor id: ATA
      vendor specific: SSDSC2KG019T8R                            PHYG908301LF1P9DGN
  Designation descriptor number 3, descriptor length: 12
    designator_type: NAA,  code_set: Binary
    associated with the Addressed logical unit
      NAA 5, IEEE Company_id: 0x5cd2e4
      Vendor Specific Identifier: 0x1507fe2a0
      [0x55cd2e41507fe2a0]
```

如果配置了多路径，也可以 `multipath -l /dev/mappe/mpathX` 查询。

## WWN & NAA

对比上面的命令输出，可以看到 WWN[^wwn] 相比 SCSI ID 少了一个最前面的 ‘3’. 这
个前缀 ‘3’ 表示后面跟着的 ID 来自设备的 VPD page 0x83，符合 NAA 规范。

其中，'55cd2e41507fe2a0' 是个八字节的 ID，第一个 ‘5’ 表示 NAA type 5
格式。如果第一个字符是 ‘6’，则代表 NAA type 6 格式，占用 16 字节。


```text
55cd2e41507fe2a0
               Vendor
NAA  OUI       Specific
  5  5c-d2-e4  1507fe2a0
  
6000097123456789abcdeffedcba9876
               Vendor    Vendor
NAA  OUI       Specific  Specific Ext.
  6  00-00-97  123456789 abcdeffedcba9876
```

OUI - Organizationally Unique Identifier.[^oui]
- 5c:d2:e4 - Intel Corporate
- 00:00:97 - DeLL EMC.

[^hcil]: Host, Channel, Id, Lun.
[^addr]: 但是一个 SCSI 设备可能有多个路径。
[^wwid]: [How to find the WWID of storage disk](https://access.redhat.com/solutions/474593)
[^wwn]: [World Wide Name](https://en.wikipedia.org/wiki/World_Wide_Name)
[^oui]: [OUI lookup tool](https://www.wireshark.org/tools/oui-lookup.html)
