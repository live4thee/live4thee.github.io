+++
title = "Meet JVM OOM - cont'd"
description = ""
date = "2018-05-02T20:10:46+08:00"
tags = ["java"]
categories = ["programming"]
+++

接上篇。

## Groovy

内存泄漏的原因还是因为不当使用了`GroovyShell`，因为需要动态的加载并执
行生成的 groovy 脚本。Groovy是一门动态语言，每个方法调用都是动态分发。
为了优化该过程，Groovy 使用了 MetaClassRegistry 来记录每个 MetaClass.
默认情况下，GroovyShell 使用全局的 ClassLoader 来动态加载脚本，过程中
生成的 Weak Reference 无法被 GC 掉。

解决的办法在于两点：

- 每个 GroovyShell 使用一个 ClassLoader
- 用完 GroovyShell 后清除 MetaClassRegistry

```groovy
GroovySystem.getMetaClassRegistry().removeMetaClass(script.getClass())
```

## 工具

在常用的几台机器上安装了 openjdk，以及 visualvm，方便随时查看。不过
Java的分析工具真是贼多。

### jmap

`jmap -clstats` 之前没有成功的原因是，它需要装`debuginfo`包：

```sh
debuginfo-install java-1.8.0-openjdk-devel
```

### jconsole/jstat

`jstat` 可以打印出很多有用的 JVM 统计信息。

```sh
$ jstat -class 17966
Loaded  Bytes  Unloaded  Bytes     Time
113136 240382.4    69286 155529.1     249.35

$ jstat -gc 17966
...

$ jstat -gccause 17966
...
```

`jconsole` 提供了图形界面监控和管理 Java 程序。

```sh
jconsole <pid>
```

### Memory Analyzer

[MAT](https://www.eclipse.org/mat/downloads.php)不仅仅作为Eclipse的插
件而存在，它还有 stand-alone 的安装包。试用了一下内存泄漏检查，运行了
一会儿后说完成了，不知道分析结果在哪里，有点莫名奇妙。后来无意中发现，
分析结果在内存转储文件所在文件夹内，一个压缩好的zip文件。
