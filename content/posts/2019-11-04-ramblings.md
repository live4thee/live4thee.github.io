+++
title = "ramblings"
description = ""
date = "2019-11-04T20:35:06+08:00"
tags = ["family", "sysadmin", "photography"]
categories = ["linux"]
+++

## 懂事的孩子

老师问小朋友，“你的尺子断了，铅笔也很短了，怎么还没换啊？” 

小朋友回答说，“家长很忙。”

这段对话是老师告知的。家长很惭愧。

## 传感器惊魂

为了凑单，买了个相机传感器的清理工具。包装盒上写了步骤：

~~~
1. 准备好清洁棒
2. 打开反光板预升
3. 清洁棒对准传感器来回擦
~~~

看着贼简单。卸除镜头，开机、打开反光板预升，按快门没反应。按两次，也没
反应。怪哉。机智地打开液晶屏实时取景，果然反光板应声而起。刚擦了一个方
向，就听见咔嚓一声，LCD 亮起了令人绝望的 "Err 20".

关机、开机，"Err 20". 把反光板轻轻撸正位置，开关机，还是 "Err 20"。

心里一沉。

慢慢回复心情。

老婆在一边锻炼得正嗨。

空气很安静。

~~~
“我好像把相机弄坏了”
“你骗我的吧” (毕竟，双11就要到了）
“我再看看...”
~~~

网上各种搜。无解。拔掉电池再放进去，竟然好了。喜极而泣。

## 传感器惊魂(2)

隔天一搜油管，立马就有一个教学视频。渣能的菜单里面有一个清理传感器选项：

1. 自动清理
2. 立即清理
3. 手动清理

视频博主一本正经的说（英文）：手动清理，等 30s 就好了。当时一看就想抽
自己：厂商做这么傻瓜化了，自己还折腾个啥啊？

晚上回去一看：手动清理是自动升起反光板，然后用户自己清理。还有个提示：
手动清理完后，请关闭电源。

## 科学上网

手贱，用 [fast.com](https://fast.com) 测了一下网速，然后就发现打开不了
gg 搜索了。SSH 到虚拟机非常非常慢，看日志有好几个 OOM （毕竟是最便宜的
实例），但都不是当天的。可用内存所剩无几，而且没有开 swap，之前没注意。

~~~sh
$ sudo fallocate -l 512M /var/swap
$ sudo mkswap /var/swap
$ sudo swapon /var/swap # 稍微卡住一段时间
$ swapon -s             # 显示生效
~~~

过了一会儿，科学恢复了。

## 神奇的 BUG

前段时间碰到一个环境，做 _virsh blockcopy_ 的时候会报个莫名其妙的错误：
_permission denied_. 但是手动检查了权限也没发现什么问题。客户环境是
OpenNenula，缩小了搜索范围后，找到了这样一个[补
丁
](https://github.com/OpenNebula/one/pull/2701/commits/6ed0de0438139d34b69732bb4f4ab13a9e9aaa0b)
。验证了一下，确实工作，原因还没细究。只知道空文件确实被特殊处理了。

~~~c
// file: src/qemu/qemu_driver.c
// func: qemuDomainBlockCopyValidateMirror
if (S_ISBLK(st.st_mode)) {
    /* if the target is a block device, assume that we are reusing it,
     * so there are no attempts to create it */
    *reuse = true;
} else {
    if (st.st_size && !(*reuse)) {
        virReportError(VIR_ERR_CONFIG_UNSUPPORTED,
                       _("external destination file for disk %s already "
                         "exists and is not a block device: %s"),
                       dst, mirror->path);
        return -1;
    }

    if (desttype == VIR_STORAGE_TYPE_BLOCK) {
        virReportError(VIR_ERR_INVALID_ARG,
                       _("blockdev flag requested for disk %s, but file "
                         "'%s' is not a block device"),
                       dst, mirror->path);
        return -1;
    }
}
~~~
