---
categories:
- work
date: 2015-11-24T00:00:00Z
description: ""
tags:
- Azure
title: Hunting a Bug (2)
url: /2015/11/24/hunting-a-bug-2/
---


最近一周一直被一个`IOException`异常所困扰。异常消息的内容为`Not enough
space on the disk`，搜索后发现，Azure Cloud Service 的磁盘用量是有配额
限制的，默认100MB - 远少于我的业务逻辑需要的磁盘空间。

问题的诡异之处在于，根据文章[^1] 中的方案，另外配置了一个比较大的磁盘
空间后，`IOException`还是没有消失。而且糟糕的是，因为代码中捕获了该异
常并记入了日志，所以日志中每分钟会产生将近6万条记录，因此日志中其它的
信息很快被淹没。我能确信的事实如下：

1. 需要处理的大文件确实放在了我分配的目录中；
2. File Server Resource Manager[^2] 中看到的目录配额确实是我新设置的；
3. 整个项目全文搜索（包括第三方代码），没有发现用临时文件的地方；
4. 搜索了相关IO函数的源代码，也没有发现悄悄使用临时文件的行为。

下午新的代码部署上去后，相关异常只记录一次，重新看了一下日志，情况顿时
变得很明朗：我使用的一个中间文件是用`Path.GetFileNameWithoutExtension`
得到的文件名，而该函数把目录给去掉了，而我的单元测试的测试用例中，输入
只有各种单纯的文件名，没有带文件全路径。处理中间文件时，该文件所在目录
的磁盘配额超标了。

这个问题给我的教训是：

1. 关键信息一定要记日志，不要怕多余；
2. 循环语句中记日志一定要三思；
3. 尽量怀疑自己的代码，而不是编译器、虚拟机；

最后，根据微软官方文档[^3] 和[^4] 中的说明，不同配置的虚拟机实例其实是
有不同的资源配额上限。比较重要的，比如：本地磁盘资源的大小，对外网络带
宽等。

[^1]: [Not enough space on the disk - Azure Cloud Service](http://blog.maartenballiauw.be/post/2015/09/17/Not-enough-space-on-the-disk-Azure-Cloud-Services.aspx)
[^2]: [File Server Resource Manager](https://technet.microsoft.com/en-us/library/cc732431.aspx)
[^3]: [Sizes for Cloud Services](https://azure.microsoft.com/en-us/documentation/articles/cloud-services-sizes-specs/)
[^4]: [Sizes for virtual machines](https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-size-specs/)
