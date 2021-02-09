+++
title = "Coyote Notes - 2"
date = 2021-02-02T15:57:27+08:00
tags = [".Net"]
categories = ["programming"]
draft = false
+++

### Actors

Coyote 提供了两大编程模型，其中一个就是 [Asynchronous Actors](https://microsoft.github.io/coyote/#programming-models/actors/overview/).

[Actor 模型](https://en.wikipedia.org/wiki/Actor_model) 有几个特征：

- 创建 Actor 以及向 actor 发送消息是非阻塞的；
- Actor 对消息的处理是顺序的，因此处理逻辑不需要额外加锁。

Microsoft.Coyote 库的 Actor 抽象类实现了若干 `createActor` 函数，比如：

```c#
//
// Summary:
//     Creates a new actor of the specified type and with the specified optional Microsoft.Coyote.Event.
//     This Microsoft.Coyote.Event can only be used to access its payload, and cannot
//     be handled.
//
// Parameters:
//   type:
//     Type of the actor.
//
//   initialEvent:
//     Optional initialization event.
//
//   eventGroup:
//     An optional event group associated with the new Actor.
//
// Returns:
//     The unique actor id.
protected ActorId CreateActor(Type type, Event initialEvent = null, EventGroup eventGroup = null);
```

另外，Actor 自己也有一个 `Id` 属性：

```c#
//
// Summary:
//     Unique id that identifies this actor.
protected internal ActorId Id { get; }
```

为了编程方便，Coyote 的 `IActorRuntime` 接口也提供了 `CreateActor` 方
法。实现这个接口的对象可以在运行 `coyote test` 的时候被注入进来。这样，
测试入口就能很方便地写成：

```c#
[Microsoft.Coyote.SystematicTesting.Test]
public static void Execute(IActorRuntime runtime)
{
    runtime.CreateActor(typeof(TestActor));
}
```

这里，`TestActor` 是封装了任意测试逻辑的一个 Actor。
