---
title: "RDP w/ Admin"
date: 2024-08-27T13:19:41+08:00
tags: [ "Windows" ]
categories: [ "work" ]
draft: false
---

我的 Windows 环境一直跑在虚拟机里，主要为了使用钉钉和上网。默认用的管
理员账号做 rdp 登录。

添加了一个普通账户后，用 xfreerdp 登录，报错 connect reset. 目测权限问
题 -- 搜索了一下，默认只有管理员、或者远程桌面用户组下的用户才能提供远
程访问。

```text
Remote Desktop -> User accounts -> Select user that can remotely access this PC
```

作为 `usermod -G -a` 的模仿，一路鼠标，把新增用户放到了 rdp 组。再次尝
试 xfreerdp, 果然就可以了。意外的是，第二天再来看，又失败了报相同的错。
查看了一下用户组，新用户神奇地不在 rdp 组。

直接把新用户加到可以使用 rdp 的用户列表。DONE.
