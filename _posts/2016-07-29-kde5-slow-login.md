---
layout: post
title: "Solve KDE5 Slow Login"
description: ""
category: linux
tags: [kde]
---
{% include JB/setup %}

为了`Okular`改用了KDE，但是KDE5有个大
[bug](https://bugs.launchpad.net/ubuntu/+source/breeze/+bug/1584604)，
导致输入密码到桌面可用需要30秒时间。一个绕过该问题的
[方法](https://bugs.launchpad.net/ubuntu/+source/breeze/+bug/1584604/comments/14)
是把默认的Splash Screen主题给禁用掉。

~~~
System Settings -> Workspace Theme -> Splash Screen -> Set Theme to "None"
~~~

果然，飞一般的感觉。
