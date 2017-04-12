---
categories:
- work
date: 2017-04-11T00:00:00Z
description: ""
tags:
- java
title: Hunting a Bug (5)
url: /2017/04/11/hunting-a-bug-5/
---


今天调试一个 `bug` 的过程非常有趣，起承转合很像央视《走近科学》的风格。
故障代码类似于这样：

```java
if (mgr.getSomeObj().getSomeField() != null) {
    hostnum = mgr.getSomeObj().getSomeField();
} else {
    // ...
}
```

断点成功断在第一行，单步进入 `getSomeField` 后确定返回的是 `null`。然
后神奇的事情发生了：再次单步就发生了 `NullPointerException`。既没有进
入 `if` 块，也没有进入 `else` 块。简直不敢相信自己的眼睛 - 不相信就对
了，因为远程执行的代码和本地 `IntelliJ` 打开的代码不一样。远程的代码应
该类似这样：

```java
foo = mgr.getSomeObj().getSomeField();
```

从 JVM 的角度去理解，本地和远程在出错前跑的代码都是一样的（也许这也是
`IntelliJ` 一直没有报错说代码不匹配的原因）：

```
325: getfield        #546
328: invokeinterface #1389, 1
333: invokevirtual   #1421 // getSomeField()
336: invokevirtual   #288  // java/lang/Integer.intValue:()I
```

`NullPointerException` 是 `336` 导致的。因为远程代码中，`foo` 被声明为
`int`，而 `getSomeField()` 返回的是 `Integer`。由于编译器自动 `unbox`，
对 `null` 值进行了 `intValue()` 计算，发生了异常。

其实这个`bug`半个月前同事就修复了，而测试团队用的是老的代码。又恰好
`336` 前所有 JVM 指令也都是一样的，`IntelliJ` 也没有报告代码不匹配，造
成了这个神秘的假象。
