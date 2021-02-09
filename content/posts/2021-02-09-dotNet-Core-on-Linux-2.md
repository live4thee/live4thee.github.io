+++
title = ".Net Core on Linux - 2"
date = 2021-02-09T15:48:42+08:00
tags = [".Net"]
categories = ["programming"]
draft = false
+++

## dotnet publish

`dotnet publish` - Publishes the application and its dependencies to a folder for deployment to a hosting system.

试验了一下打包应用，放到别的 Linux 机器（没有.Net 运行时）上跑。

### 自包含应用

```sh
$ dotnet publish -h
...
-f, --framework <FRAMEWORK>           The target framework to publish for.
-r, --runtime <RUNTIME_IDENTIFIER>    The target runtime to publish for.
...
--self-contained    Publish the .NET runtime with your application so the runtime
                    does not need to be installed on the target machine.
                    The default is 'true' if a runtime identifier is specified.

$ dotnet publish -r linux-x64 -f net5.0 -o ./linux-publish
$ du -sh linux-publish/
76M     linux-publish/
$ ls -1 linux-publish/*.dll | wc -l
193
```

看了一下 `dotnet publish -h` 的输出，有一个 `--self-contained` 选项，
可以用来打包自包含应用，且 `-r` 指定了目标运行时的话就隐含了自包含。
打包的结果是个文件夹，包含了应用本身以及依赖的库。

### 自包含单体应用

显然，这没有 `go build` 生成出来一个单体应用方便。网上搜了一下，有个额
外参数 `-p:PublishSingleFile=true`.

```sh
$ dotnet publish -r linux-x64 -f net5.0 -p:PublishSingleFile=true -o ./linux-publish
$ du -sh linux-publish/
64M     linux-publish/
$ ls linux-publish/
MyApp  MyApp.pdb
$ file linux-publish/MyApp
linux-publish/MyApp: ELF 64-bit LSB shared object, x86-64, version 1 (SYSV),
dynamically linked, interpreter/lib64/ld-linux-x86-64.so.2, for GNU/Linux 2.6.32,
BuildID[sha1]=42c923debe410c089a93997a66ef968f8574a077, stripped, too many notes (256)
```

是个已经去掉符号表的可执行程序，虽然 64MB 比之前 76MB 小一点，但还是偏
大。

### [upx-ucl](https://upx.github.io/)

拿 `upx-ucl` 压缩一下？

```sh
$ upx-ucl MyApp
                       Ultimate Packer for eXecutables
                          Copyright (C) 1996 - 2018
UPX 3.95        Markus Oberhumer, Laszlo Molnar & John Reiser   Aug 26th 2018

        File size         Ratio      Format      Name
   --------------------   ------   -----------   -----------
  66467643 ->  27944636   42.04%   linux/amd64   MyApp

Packed 1 file.

$ du -h MyApp
27M     MyApp
```

64 MB 压缩到 27 MB，很可观。

```sh
 ./MyApp
Failure processing application bundle; possible file corruption.
Arithmetic overflow while reading bundle.
A fatal error occured while processing application bundle
```

又有什么用？

### 自包含单体应用 - 瘦身

去[官网](https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-publish)查看`PublishSingleFile`的文档，查到了两个信息：

#### -p:PublishSingleFile=true

Packages the app into a platform-specific single-file executable. The
executable is self-extracting and contains all dependencies (including
native) that are required to run the app. When the app is first run,
the application is extracted to a directory based on the app name and
build identifier. Startup is faster when the application is run
again. The application doesn't need to extract itself a second time
unless a new version is used. Available since .NET Core 3.0 SDK.

For more information about single-file publishing, see the
 [single-file bundler design document](https://github.com/dotnet/designs/blob/master/accepted/2020/single-file/design.md).

We recommend that you specify this option in a publish profile rather
than on the command line. For more information, see [MSBuild](https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-publish#msbuild).

#### -p:PublishTrimmed=true
Trims unused libraries to reduce the deployment size of an app when
publishing a self-contained executable. For more information, see
[Trim self-contained deployments and executables](https://docs.microsoft.com/en-us/dotnet/core/deploying/trim-self-contained). Available since .NET Core
3.0 SDK as a preview feature.

We recommend that you specify this option in a publish profile rather
than on the command line. For more information, see [MSBuild](https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-publish#msbuild).

首先，single-file executable 其实是个打包了依赖的自解压程序；另外其实
有 `PublishTrimmed` 来做这个瘦身工作。

```sh
$ dotnet publish -r linux-x64 -f net5.0 -p:PublishSingleFile=true \
  -p:PublishTrimmed=true -o ./linux-publish
$ du -sh linux-publish/
34M     linux-publish/
```

64 MB 瘦身到 34 MB，但明显运行耗时长很多。`Single-file publish`的设计
[文档](https://github.com/dotnet/designs/blob/main/accepted/2020/single-file/design.md)
里提到：bundler 里面其实打包了 PEImage Loader. 因此，Linux下这个单体程
序其实是个披着 ELF 外壳的 PE 程序。
