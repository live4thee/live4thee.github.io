---
layout: post
title: "Shell Programming"
description: ""
category: linux
tags: [shell]
---
{% include JB/setup %}

这周轮到我 on call，一直平静无事，以至于我怀疑自己的邮件程序是不是出了
问题。直到今天中午，有客户打电话来提了一些数据分析要求。

很快写了几行Shell脚本，虽然平时已经几乎用不到Linux，简单数据分析不外乎
awk/sort再加uniq/wc之类，妥妥的。但喵了一眼输出后却怀疑脚本写错了，感
觉结果不对。折腾来，折腾去，最后发现结果其实是对的。怀疑错了。叹。

当年xiaowen在我司工作了三年去创业，对我说，“XX司的同事真的都很smart。
不过我现在命令行很差，不要嘲笑我。GUI用起来方便，但是CLI使你保持思考。”

我自己的笔记本上装了个PortableGit，这样一直有个MSys的Bash环境可用。我
写了个[小脚本](https://github.com/live4thee/win-config/blob/master/git-bash.bat)，
这样启动shell前可以导入Visual Studio的环境变量。在Bash里就可以直接用到
VS的命令行工具了。
