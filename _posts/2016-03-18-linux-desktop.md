---
layout: post
title: "Linux Desktop"
description: ""
category: linux
tags: [xfce, jekyll]
---
{% include JB/setup %}

Xubuntu 安装好后发现一些问题，解决方法记录在此。

1. 默认分辨率 1920x1080 下，偶尔有闪屏的情况，降低分辨率后没有发生过。
2. 默认的视频播放器 `Parole` 播放时画面没有按比例调整，菜单也弹不出来（没有播放
   时可以）。用 `vlc` 提醒访问 `/dev/fb0` 失败。改用 `mpv` 后比较完美。
3. apt-get 装 `jekyll` 后，还要安装 `ruby-nokogiri`, `ruby-bundler`。
4. 摄像头似乎 `不工作`。

已经很久没有把 Linux 当桌面用了，以前一直是 `ssh + tmux`。比起十年前在 HP 
4200 上跑 Ubuntu，体验要好很多。比较欠缺的还是输入法体验。没有装 Emacs, 看
看纯用 Vim 能撑多久。也不折腾 Mutt 了，就用 Thunderbird 啦！
