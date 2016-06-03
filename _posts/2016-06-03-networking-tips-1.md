---
layout: post
title: "Networking Tips (1)"
description: ""
category: programming
tags: [networking]
---
{% include JB/setup %}

## The Port 0 Trick

经常在 `go` 的网络库测试代码中，看见如下片段：

{% highlight go %}
ln, err := Listen("tcp", "127.0.0.1:0")
if err != nil {
        t.Fatal(err)
}
{% endhighlight %}

绑定 `0` 号套接字端口时，操作系统会自动分配一个 `1024` 号以上某个可用
端口。`Windows` 和 `Linux` 都支持这种用法。

## The '\0' Trick

Linux 对 `Unix Domain Socket` 有个扩展，叫 `Abstract Socket Namespace`。
当创建的 Unix 本地套接字的路径名的起始字节为 `\0` 时，该套接字文件不会
存放在文件系统，比较方便。这种套接字用 `netstat` 显示时以 `@` 打头。

{% highlight plaintext %}
$ netstat -nl | grep @
unix  2      [ ACC ]     STREAM     LISTENING     19729    @/tmp/dbus-tENgH5neni
...
{% endhighlight %}
















