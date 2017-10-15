+++
categories = ["work"]
date = "2017-10-15T22:07:53+08:00"
description = ""
tags = ["python", "CherryPy"]
title = "Hunting a Bug (6)"
url = "/2017/10/15/hunting-a-bug-6/"
+++

最近几天被一个 bug 折磨得不要不要的，经过诸多分析后，最终发现它藏在
[CherryPy](http://cherrypy.org) 的代码里，如下：

![readline](/media/readline.png)

该函数在最新版本里至今仍一行未改：
[传送门](https://github.com/cherrypy/cherrypy/blob/master/cherrypy/_cpreqbody.py#L846)

这段代码会变成我司的研发面试题。
