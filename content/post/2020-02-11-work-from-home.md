+++
title = "Work From Home"
date = 2020-02-11T23:10:55+08:00
tags = ["Windows"]
categories = ["work"]
draft = false
+++

相应号召，最近在家工作，不免总结一番。

## 作息

每天夫人先起床，早餐差不多了，小朋友起床。小朋友的起床后兴致勃勃的任务
之一是叫我起床。一家三口，生物钟在晚上九点半前基本上出奇的一致。小朋友
上网课，大人管自己的工作，也不吵闹。

## 联网

公司的 L2TP 基本上属于没喘气就会挂掉，因此我只能用家里的 Surface Pro4
上装的程序拨号，主力开发机 Linux 笔记本就有点闲置。苏菲婆里固然也装了
个 IntelliJ，不过考虑到 Core M 处理器的性能，还是别逗了。

- Windows 上装了个 Squid，提供 HTTP 代理；
- Linux 上提供 SSH server；
- Linux 用HTTP 代理访问公司内网的 git，开发机。

### .gitconfig

Git 可以指定域名配置 proxy，不过域名要把端口写全。192.168.x.y 是苏菲婆
的内网 IP 地址。

~~~sh
[http "http://my.company.io:9080"]
        proxy = http://192.168.x.y:3128
~~~

缺点是访问 git 也得改用 http 方式，不能是 ssh

### .ssh/config

研究了一下，Squid 可以编译时打开 socks5 支持，这样也可以作为 socks 代
理，但是我用的版本不支持，因此 SSH 访问公司内网得转 HTTP 代理。配置一
下 ~/.ssh/config:

~~~sh
Host 172.20.*
    ProxyCommand connect -H 192.168.x.y:3128 %h %p
~~~

## 总结

Windows 里用微信、钉钉桌面版体验还是挺好的。比在 Linux 里用 Electron
版的替代品好用（尤其是钉钉）。还有输入法，唉，算了。

## 号外

之前惊险的相机 CMOS 清理似乎卓有成效，最近的照片挺干净。
