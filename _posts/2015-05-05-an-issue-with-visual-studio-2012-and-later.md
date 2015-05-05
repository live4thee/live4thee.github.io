---
layout: post
title: "An Issue with Visual Studio 2012 and Later"
description: "An Issue with Visual Studio 2012 and Later"
category: work
tags: [DLL]
---
{% include JB/setup %}

这几天跑单元测试代码的时候，遇到一个奇怪的问题。我有一个单元测试项目，
单独运行的时候，全都通过。但是，和整个 solution 下的其它单元测试一起跑
的时候，就必然会出错。开始怀疑是其他单元测试没写好，破坏了某些环境设置。
然而仔细分析发现，我的测试代码除了一些自己打桩的代码之外，基本没有其他
环境依赖。

最后发现，这更多的是 Visual Studio 的问题。关键信息如下：

Visual Studio will **NOT** copy file to deployment output if:

* DLL is referenced but not directly used and loaded in runtime with reflection (Assembly.Load)
* Visual Studio will copy only DLLs with types directly used

即使该 DLL 已经被放在 `References` 里，且 `Copy to Local` 设为 `True`，
`以上逻辑仍然不变`。我的单元测试用到了 Microsoft.Owin，而它在运行时依
赖于另一个 DLL - Microsoft.Owin.Http.Listener。单元测试失败的原因是它
没有被拷贝到部署目录中。

[这里](https://connect.microsoft.com/VisualStudio/feedback/details/771138/vs2012-referenced-assemblies-in-unit-test-are-not-copied-to-the-unit-test-out-f)
有更多的讨论。
