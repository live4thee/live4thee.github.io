+++
title = ".Net Core on Linux"
date = 2021-01-27T22:22:51+08:00
tags = [".Net"]
categories = ["programming"]
draft = false
+++

因为要学 [coyote](https://microsoft.github.io/coyote/)，又不想用
Windows，于是在本机 Xubuntu 20.04 上装了一个 .Net Core，没想到体验还挺
不错。我在 Fedora 33 以及 Windows 2012 R2 虚拟机里测试了也可以，主力环
境还是 Xubuntu 20.04.

### 安装源

步骤来自[官网](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux)：

```sh
# Download the Microsoft repository GPG keys
$ wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb
# Register the Microsoft repository GPG keys
$ sudo dpkg -i packages-microsoft-prod.deb
# Update the list of products
$ sudo apt-get update
$ sudo apt-get install dotnet-host dotnet-runtime-5.0 dotnet-sdk-5.0
```

注意：纯用 .Net Core 并不需要安装 `powershell`。

### 基本信息

安装完成后，可以运行 `dotnet` 命令：

```sh
$ dotnet --list-sdks
5.0.102 [/usr/share/dotnet/sdk]
$ dotnet --list-runtimes
Microsoft.AspNetCore.App 5.0.2 [/usr/share/dotnet/shared/Microsoft.AspNetCore.App]
Microsoft.NETCore.App 5.0.2 [/usr/share/dotnet/shared/Microsoft.NETCore.App]
$ dotnet --info
.NET SDK (reflecting any global.json):
 Version:   5.0.102
 Commit:    71365b4d42

Runtime Environment:
 OS Name:     ubuntu
 OS Version:  20.04
 OS Platform: Linux
 RID:         ubuntu.20.04-x64
 Base Path:   /usr/share/dotnet/sdk/5.0.102/

Host (useful for support):
  Version: 5.0.2
  Commit:  cb5f173b96

.NET SDKs installed:
  5.0.102 [/usr/share/dotnet/sdk]

.NET runtimes installed:
  Microsoft.AspNetCore.App 5.0.2 [/usr/share/dotnet/shared/Microsoft.AspNetCore.App]
  Microsoft.NETCore.App 5.0.2 [/usr/share/dotnet/shared/Microsoft.NETCore.App]

To install additional .NET runtimes or SDKs:
  https://aka.ms/dotnet-download
```

比较让我惊喜的是，里面带了一个 F# 解释器：

```sh
$ dotnet fsi

Microsoft (R) F# Interactive version 11.0.0.0 for F# 5.0
Copyright (c) Microsoft Corporation. All Rights Reserved.

For help type #help;;

>
```

### 安装 Coyote

安装 `coyote` （以及其他任何 `nuget` 包）很方便：

```sh
$ dotnet tool install --global Microsoft.Coyote.CLI
$ dotnet tool update --global Microsoft.Coyote.CLI # 更新 coyote
$ dotnet tool list --global
```

### Hello world!

创建一个空的终端项目，并编译之：

```sh
$ mkdir hello; cd hello
$ dotnet new console  # will create hello.csproj
$ dotnet build
$ ./bin/Debug/net5.0/hello
Hello World!
```

上面的 `dotnet build` 以及执行程序可以合并成一条`dotnet run`命令。另外，
可以运行 `dotnet clean` 清除编译结果。

可以建立一个`sln`文件来管理多个工程：

```sh
$ dotnet new sln
$ dotnet sln add hello.csproj
$ dotnet sln list  # list projects
```

如果从网上下载了一个 .Net Core 项目的源代码，本地先运行 `dotnet restore`
重建依赖。

### 疑似 BUG

运行 `dotnet new sln -n xxx` 或者 `dotnet new console` 可能会挂住，有
些时候还可能不响应 `CTRL-C`，这时候只能找到进程号并`kill -TERM`。
