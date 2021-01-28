+++
title = "Coyote Notes - 1"
date = 2021-01-27T15:35:50+08:00
tags = [".Net"]
categories = ["programming"]
draft = false
+++

这几天在学 [coyote](https://microsoft.github.io/coyote/)，做个笔记。

### 入口

测试入口函数[必须](https://microsoft.github.io/coyote/#tutorials/hello-world-tasks/#summary)
带有属性`[Microsoft.Coyote.SystematicTesting.Test]`，
且是命名为 `Execute` 的静态函数：

```c#
[Microsoft.Coyote.SystematicTesting.Test]
public static void Execute(IActorRuntime runtime)
{
    LogWriter.Initialize(runtime.Logger, RunForever);
    runtime.OnFailure += OnRuntimeFailure;
    runtime.RegisterMonitor<LivenessMonitor>();
    runtime.RegisterMonitor<SafetyMonitor>();
    // ...
}
```

但看了示例之后发现有**例外**：

如果被测代码是用原生`System.Threading.Tasks.Task` 写的，需要用 rewrite 技术来替换：

- 测试函数需要是静态函数（但名字不需要叫做`Execute`）；
- 测试函数有属性 `[Microsoft.Coyote.SystematicTesting.Test]`。

例如：

```c#
[Microsoft.Coyote.SystematicTesting.Test]
public static void TestXXX(ICoyoteRuntime runtime)
{
    CheckRewritten();
    // ... test code ...
    Microsoft.Coyote.Specifications.Specification.Assert(x == n, "error message");
	// ... other test code ...
}
```

### Main 函数

用 `coyote test` 进行测试时，`Main` 函数是不会执行的。如前所述，入口函
数是 `Execute`。
