---
layout: post
title: "Hunting a Bug (3)"
description: ""
category: work
tags: [Azure]
---
{% include JB/setup %}

使用第三方服务API总是会有各种从未想到的边界条件，不断颠覆各种假设。然
而这几天发现的一个bug却非常有意思。

我有段代码是抓取友商的日志文件，友商的REST调用接口会返回每条日志文件的
起始时间、文件大小和地址。为了记下曾经处理过的日志，我把历史纪录放在了
一个`Azure Table Storage`，其中`PartitionKey`是类似账号加域名的组合，
而`RowKey`则设置为友商的ID和起始时间的组合。

看起来很美好，但是万万没想到，在某种情况下，友商返回的记录中，相同域名
下的记录可能返回同样的起始时间。为了性能，我插入记录时进行了Batch操作，
相同的`RowKey`导致了冲突，错误信息类似：
`Microsoft.WindowsAzure.Storage.StorageException: Unexpected response
code for operation : 3`。
[Stackoverflow](https://stackoverflow.com/questions/19976862/unexpected-response-code-from-cloudtable-executebatch)
上得到一个有用的信息：这个数字'3'其实代表了出问题的Entity在batch里面的
索引（坑爹的出错信息啊）。

解决这个问题还算简单，因为我有单独的列记下了起始时间，所以`RowKey`中的
其实时间用一个`GUID`替换即可。当初如果不是batch，而是一条一条
`InsertOrReplace`，则这个问题不会很快被发现。当初如果需要很快通过域名
查询到单个记录，则不能如此修改（现在的实现不怎么在乎RowKey）。但是，这
么改了之后还会造成一个潜在的问题 - 生成的数据集不能通过域名加起始时间
的方式命名，因为不能保证唯一性。

这个问题使得我发现了自己程序的一个缺陷 - 即我的代码中的任务调度逻辑存在
饿死的情况，因为重复抓取失败任务而没有更新时间戳，使得其他任务无法执行。

作为流水账 - 另外一个bug是，检查`Event Handler`是否为空时，忘记了更新
本地拷贝。
