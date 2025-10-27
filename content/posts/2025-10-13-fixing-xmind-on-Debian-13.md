---
title: "Fixing Xmind on Debian 13"
date: 2025-10-13T13:13:32+08:00
tags: [ "sysadmin" ]
categories: [ "linux" ]
draft: false
---

写文档用 flatpak 版的 xmind 绘制脑图时发现，保存文件时，文件选择对话框
一直跳不出来。自打升级到 `Debian 13 Trixie` 还没用过 xmind, 研究了一下。

先从控制台启动，这样可以方便的观察到错误日志：

```sh
$ flatpak run net.xmind.XMind
```

发现，报错为：

```txt
Failed to call method: org.freedesktop.DBus.Properties.Get: object_path= /org/freedesktop/portal/desktop: org.freedesktop.DBus.Error.InvalidArgs: No such interface “org.freedesktop.portal.FileChooser”
```

后来发现，之前的报错在 `journalctl` 中也有记录。

Google 搜索提示：

```sh
# If you are using another desktop environment (like GNOME or XFCE):
$ sudo apt install xdg-desktop-portal-gtk

# Check if xdg-desktop-portal is running
$ systemctl --user status xdg-desktop-portal

# 检查接口是否存在（来自：Qwen3-Max）
$ gdbus introspect --session \
  --dest org.freedesktop.portal.Desktop \
  --object-path /org/freedesktop/portal/desktop \
  --xml | grep org.freedesktop.portal
```

根据提示进行检查，得到结果：

1. `xdg-desktop-portal-gtk` 确实已经安装；
2. `xdg-desktop-portal` 确实已经运行；
3. `gdbus` 的输出确实也没有 FileChooser.

```sh
$ gdbus introspect --session \
  --dest org.freedesktop.portal.Desktop \
  --object-path /org/freedesktop/portal/desktop \
  --xml | grep org.freedesktop.portal
  <interface name="org.freedesktop.portal.Trash">
  <interface name="org.freedesktop.portal.MemoryMonitor">
  <interface name="org.freedesktop.portal.GameMode">
  <interface name="org.freedesktop.portal.ProxyResolver">
  <interface name="org.freedesktop.portal.Inhibit">
  <interface name="org.freedesktop.portal.Secret">
  <interface name="org.freedesktop.portal.NetworkMonitor">
  <interface name="org.freedesktop.portal.Settings">
  <interface name="org.freedesktop.portal.PowerProfileMonitor">
  <interface name="org.freedesktop.portal.Email">
  <interface name="org.freedesktop.portal.Realtime">
```

再次检查 `xdg-desktop-portal` 的运行情况。发现虽然服务在运行，但是有报
错信息：

```sh
systemctl --user status xdg-desktop-portal
● xdg-desktop-portal.service - Portal service
     Loaded: loaded (/usr/lib/systemd/user/xdg-desktop-portal.service; static)
     Active: active (running) since Thu 2025-10-09 09:31:59 CST; 4 days ago
 Invocation: 6dadc91d50754a6f88d4695672aed1f8
   Main PID: 2633 (xdg-desktop-por)
      Tasks: 6 (limit: 18514)
     Memory: 5M (peak: 6.6M)
        CPU: 7.882s
     CGroup: /user.slice/user-1000.slice/user@1000.service/session.slice/xdg-desktop-portal.service
             └─2633 /usr/libexec/xdg-desktop-portal

Oct 09 14:54:07 my-debian xdg-desktop-por[2633]: Realtime error: Could not get pidns for pid 6026: Could not fstatat ns/pid: Not a directory
Oct 09 15:04:23 my-debian xdg-desktop-por[2633]: Realtime error: Could not get pidns for pid 6026: Could not fstatat ns/pid: Not a directory
Oct 09 15:10:33 my-debian xdg-desktop-por[2633]: Realtime error: Could not get pidns for pid 6026: Could not fstatat ns/pid: Not a directory
```

于是尝试重启该服务：

```sh
$ systemctl  --user restart xdg-desktop-portal-gnome.service
Failed to restart xdg-desktop-portal-gnome.service: Unit xdg-desktop-portal-gnome.service is masked.
```

见招拆招：

```sh
$ systemctl --user unmask xdg-desktop-portal-gnome.service
Removed '/home/david/.config/systemd/user/xdg-desktop-portal-gnome.service'.
$ systemctl --user restart xdg-desktop-portal.service
$ systemctl --user status xdg-desktop-portal
● xdg-desktop-portal.service - Portal service
     Loaded: loaded (/usr/lib/systemd/user/xdg-desktop-portal.service; static)
     Active: active (running) since Mon 2025-10-13 13:07:29 CST; 12s ago
 Invocation: 131d5b9e539e4f63bac5842c44b45f98
   Main PID: 92114 (xdg-desktop-por)
      Tasks: 9 (limit: 18514)
     Memory: 4.3M (peak: 5.4M)
        CPU: 88ms
     CGroup: /user.slice/user-1000.slice/user@1000.service/session.slice/xdg-desktop-portal.service
             └─92114 /usr/libexec/xdg-desktop-portal

Oct 13 13:07:28 my-debian systemd[2462]: Starting xdg-desktop-portal.service - Portal service...
Oct 13 13:07:29 my-debian systemd[2462]: Started xdg-desktop-portal.service - Portal service
```

很好，这回 `xdg-desktop-portal` 服务没有报错。再次测试：

```sh
$ gdbus introspect --session \
  --dest org.freedesktop.portal.Desktop \
  --object-path /org/freedesktop/portal/desktop \
  --xml | grep org.freedesktop.portal
  <interface name="org.freedesktop.portal.Inhibit">
  <interface name="org.freedesktop.portal.Background">
  <interface name="org.freedesktop.portal.Location">
  <interface name="org.freedesktop.portal.Notification">
  <interface name="org.freedesktop.portal.Screenshot">
  <interface name="org.freedesktop.portal.Usb">
  <interface name="org.freedesktop.portal.Account">
  <interface name="org.freedesktop.portal.NetworkMonitor">
  <interface name="org.freedesktop.portal.Print">
  <interface name="org.freedesktop.portal.Settings">
  <interface name="org.freedesktop.portal.GameMode">
  <interface name="org.freedesktop.portal.RemoteDesktop">
  <interface name="org.freedesktop.portal.MemoryMonitor">
  <interface name="org.freedesktop.portal.OpenURI">
  <interface name="org.freedesktop.portal.Realtime">
  <interface name="org.freedesktop.portal.Secret">
  <interface name="org.freedesktop.portal.Clipboard">
  <interface name="org.freedesktop.portal.Wallpaper">
  <interface name="org.freedesktop.portal.Camera">
  <interface name="org.freedesktop.portal.InputCapture">
  <interface name="org.freedesktop.portal.GlobalShortcuts">
  <interface name="org.freedesktop.portal.PowerProfileMonitor">
  <interface name="org.freedesktop.portal.DynamicLauncher">
  <interface name="org.freedesktop.portal.ScreenCast">
  <interface name="org.freedesktop.portal.Email">
  <interface name="org.freedesktop.portal.Trash">
  <interface name="org.freedesktop.portal.ProxyResolver">
  <interface name="org.freedesktop.portal.FileChooser">
```

再次运行 `xmind`, 果然正常了。

**2025/10/27 Update**

执行 `unmask xdg-desktop-portal-gnome` 会导致首次登录桌面环境后，`gnome-terminal`
启动很慢的问题，见前文[Debian 13 Trixie]({{< ref "/posts/2025-08-13-trixie">}}).
