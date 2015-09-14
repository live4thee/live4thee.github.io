---
layout: post
title: "Problem Solved"
description: ""
category: work
tags: [Unity, WebApi]
---
{% include JB/setup %}

折腾了四五天的Unity的问题，今天终于搞定了。

做了各种尝试，最后发现是因为自己对IIS的运行时环境不够了解。简单来说，
我有点把Azure的Web Role当成Worker Role在用，然后由于我的后台线程的运行
时上下文和MVC的运行时上下文并不属于同一个进程（以前不知道），导致我的
Unity配置在后台线程的上下文中没有加载，导致一系列问题。

具体解释在
[这里](https://azure.microsoft.com/en-us/blog/new-full-iis-capabilities-differences-from-hosted-web-core/?rnd=1)
。同事说，你砍出了99刀，终于有一刀命中了。不容易！其中比较坑的地方在于，
本地调试的时候我用的是IIS Express而不是IIS，两者的运行时环境不一样。前
者是HWC(Hosted Web Core)，跑起来一点问题都没有，导致很多误解。
