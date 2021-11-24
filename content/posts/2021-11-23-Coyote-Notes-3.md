+++
title = "Coyote Notes - 3"
date = 2021-11-23T11:22:27+08:00
tags = [".Net"]
categories = ["programming"]
draft = false
+++

内容来自[官网](https://microsoft.github.io/coyote/#concepts/actors/overview/)。

### Actors and StateMachine

[上篇](/posts/2021-02-02-coyote-notes-2/)提到，[Coyote](https://microsoft.github.io/coyote/) 提供了异步
Actor 编程模型。Coyote 框架提供了一种特殊的 Actor 类型, 叫
[`StateMachine`](https://microsoft.github.io/coyote/#concepts/actors/state-machines/)
，这种 Actor 可以用来显示定义状态以及状态转换，从而更有助于 `coyote
test` 进行自动状态识别以及系统化测试。

#### 声明和创建 Actors

上篇简要介绍了 Actor 的创建，下面我们看看一个 Actor 是怎么实现的。

```c#
using System;
using Microsoft.Coyote.Actors;

class SetupEvent : Event
{
    public readonly ActorId ServerId;

    public SetupEvent(ActorId server)
    {
        this.ServerId = server;
    }
}

[OnEventDoAction(typeof(PongEvent), nameof(HandlePong))]
class Client : Actor
{
    // 通过 `initialEvent' 获得 Server 的 Actor ID.
    protected override Task OnInitializeAsync(Event initialEvent)
    {
        Console.WriteLine("{0} initializing", this.Id);
        var serverId = ((SetupEvent)initialEvent).ServerId;
        Console.WriteLine("{0} sending ping event to server", this.Id);
        this.SendEvent(serverId, new PingEvent(this.Id));
        return base.OnInitializeAsync(initialEvent);
    }

    // Handler 方法的 `Event' 参数在 Coyote 里是可选的。
    // 也可以是 `async Task'，但方法里不能调用 `Task.Run()', `Task.Delay' 或 `Task.Yield'.
    public void HandlePong()
    {
        Console.WriteLine("{0} received pong event", this.Id);
    }
}

[OnEventDoAction(typeof(PingEvent), nameof(HandlePing))]
class Server : Actor
{
    public void HandlePing(Event e)
    {
        PingEvent ping = (PingEvent)e;
        Console.WriteLine("Server handling ping, sending pong back to caller");
        this.SendEvent(ping.Caller, new PongEvent());
    }
}

class PingEvent : Event
{
    public readonly ActorId Caller;

    public PingEvent(ActorId caller)
    {
        this.Caller = caller;
    }
}

class PongEvent : Event { }

[Microsoft.Coyote.SystematicTesting.Test]
public static void Execute(IActorRuntime runtime)
{
    ActorId serverId = runtime.CreateActor(typeof(Server));
    // c.f. OnInitializeAsync()
    runtime.CreateActor(typeof(Client), new SetupEvent(serverId));
    runtime.CreateActor(typeof(Client), new SetupEvent(serverId));
}
```

#### State machines

除了 `StateMachine` 这个类供继承之外，Coyote 还提供了一个 `State` 类，
以及相应的属性。它们一起为开发者提供了显式定义状态变迁的能力。

```c#
class ReadyEvent : Event { }

class Server : StateMachine
{
    [Start]
    [OnEntry(nameof(InitOnEntry))]
    [OnEventGotoState(typeof(ReadyEvent), typeof(Active))]
    class Init : State { }

    void InitOnEntry()
    {
        // 触发状态转换到 `Active'.
        // RaiseEvent() will send event to self.
        // But, raised events are *prioritized* over any events in the inbox.
        this.RaiseEvent(new ReadyEvent());
    }

    [OnEventDoAction(typeof(PingEvent), nameof(HandlePing))]
    class Active : State { }

    void HandlePing(Event e)
    {
        var pe = (PingEvent)e;
        Console.WriteLine("Server received ping event from {0}", pe.Caller.Name);
        this.SendEvent(pe.Caller, new PongEvent());
    }
}
```

我们看到，`Server` 类里有两个继承了 `State` 的嵌套类：`Init`,
`Active`. 它们分别表明了 `Server` 可能的两个状态。

- `Start` 属性用来指定状态机的初始状态（这里是`Init`）；
- `OnEntry` 属性指定状态机进入当前状态时执行的动作；
- `OnExit`  属性指定状态机离开当前状态时执行的动作；
- 动作函数没有参数，或者有一个 `Event` 参数；返回 void 或者 async
  Task.
- `OnExit` 指定的动作函数不能带 `Event` 参数；
- `OnEventGotoState` 属性指定当前状态下，收到给定 `Event` 后进入目标状态；

上述 `OnEventGotoState` 和 `RaiseEvent()` 的配合有一个更快的便捷方法：

```c#
this.RaiseGotoStateEvent<Active>();
```

显示状态还有一个好处：可以更细粒度地控制某些状态下能够处理哪些事件。

#### Push and Pop states

状态机的活跃状态其实是个堆栈，用户还可以通过 `RaisePushStateEvent()`,
`RaisePopStateEvent()` 来操纵当前 Actor 的状态。

```c#
void HandlePing()
{
    Console.WriteLine("Server received ping event while in the {0} state",
        this.CurrentState.Name);
    // pop the current state off the stack of active states.
    this.RaisePopStateEvent();
}
```

注意，对于状态迁移函数，每个 Event handler 执行过程中只能调用一个。否
则，Coyote 会抛一个运行时 Assert.

- RaiseEvent
- RaiseGotoStateEvent
- RaisePushStateEvent
- RaisePopStateEvent
- RaiseHaltEvent

#### Deferring and ignoring events

`Defer` 的用处是让状态机能在指定状态下忽略一些事件；`Ignore` 的作用是
在指定状态下抛弃一些事件。比如：

```c#
[DeferEvents(typeof(PingEvent), typeof(PongEvent))]
[IgnoreEvents(typeof(ReadyEvent))]
class SomeState : State { }
```

这里，当状态机处于 `SomeState` 状态时，Actor 从队列里获取事件
`PingEvent` 和 `PongEvent` 时会忽略（但不会丢弃），继续读取下一个实际。
如果获取到 `ReadyEvent` 则立刻抛弃而不会调用事件处理函数。

#### Default events

默认事件可以用来实现 Actor 的消息队列为空时的处理逻辑。

```c#
[OnEventDoAction(typeof(DefaultEvent), nameof(OnIdle))]
class Idle : State { }

public void OnIdle()
{
    Console.WriteLine("OnIdle");
}
```

当状态机处于 `Idle` 状态，且 Actor inbox 为空时，执行 `OnIdle`.

#### WildCard events

有一个特殊的事件，叫 `WildCardEvent`，它在运行时匹配所有事件（除了
`DefaultEvent`）。这个事件可以用来实现通用逻辑。

```c#
internal class WildMachine : StateMachine
{
    [Start]
    [OnEntry(nameof(OnInit))]
    [OnEventGotoState(typeof(WildCardEvent), typeof(CatchAll))]
    public class Init : State { }

    public void OnInit()
    {
        Console.WriteLine("Entering state {0}", this.CurrentStateName);
    }

    [OnEntry(nameof(OnInit))]
    [OnEntry(nameof(OnCatchAll))]
    [OnEventDoAction(typeof(WildCardEvent), nameof(OnCatchAll))]
    public class CatchAll : State { }

    void OnCatchAll(Event e)
    {
        Console.WriteLine("Catch all state caught event of type {0}", e.GetType().Name);
    }
}

class X : Event { };
var actor = runtime.CreateActor(typeof(WildMachine));
runtime.SendEvent(actor, new X());
```

输出：

```text
Entering state Init
Entering state CatchAll
Catch all state caught event of type X
```
