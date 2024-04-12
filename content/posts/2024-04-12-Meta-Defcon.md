---
title: "Meta Defcon"
date: 2024-04-12T14:39:33+08:00
tags: [ "paper", "reading" ]
categories: [ "programming" ]
draft: false
---

一起读论文：[Defcon: Preventing Overload with Graceful Feature Degradation](https://www.usenix.org/conference/osdi23/presentation/meza)

复杂系统中，一旦有故障发生，则往往容易发展成为[Cascading Failures](https://sre.google/sre-book/addressing-cascading-failures/).
为了防止系统过载影响产品使用，Meta 开发了一个系统叫做：Defcon.

## 潜在方案及其权衡

作者首先列出了若干方案，及其对资源、研发投入、用户体验的影响：

![overload-handle](/media/overload.png)

## Defcon 如何工作？

### Knob 的定义

每个 knob 对应一个功能，它由一个四元组表示：
- name:  功能名称（具有唯一性）；
- oncall：轮值负责团队；
- level：范围为 [1, 2, 3, 4]，数字越小级别越高；
- enabled：打开/关闭状态。

```python
from configs.knobs import KnobConfig
disableCommentsRanking = KnobConfig(
    name = "Feed/DisableCommentsRanking",
	oncall = "owner_team_oncall",
	leve = 2, # Impact Magnitude.
	enabled = True)
export(disableCommentsRanking)
```

### Knob 的种类

- Server-side knob: 由数据中心的服务器端使用，状态调整的响应时间为秒级。

- Client-side knob: 客户端（手机、平板、穿戴设备等等）代码中使用，可以
  用来减少请求。其状态更新一般通过 *Silent Push Notification*, 或者
  *Mobile Configuration Pull* 等等。

### Knob 的使用

应用通过读取 Knob 的状态做相应的处理。在测试过程中，或者事故处理时，运
维操作人员可以通过工具改变 Knob 的状态。Defcon 会处理 Knob 的状态复
制 - 使得该状态被相关服务、移动应用等感知）。Knob 状态存放在数据库中。

```python
from configs import ConfigReader
disableCommentsRanking = ConfigReader(
    "Feed/DisableCommentsRanking")
comments = fetchComments()
if not disableCommentsRanking.enabled:
    comments.RankUsingModel()
else:
    comments.RankChronologically()
```

就是说，产品工程师可以通过 Knob定义框架来控制一段逻辑的执行条件。

### 系统架构

![degredation](/media/degredation.png)

- 用户：应用的使用者（移动应用/网页等等）；
- Degredation portal: 可视化看板、控制台；
- Degredation CLI: 命令行工具（可以用来控制/配置 knobs）；
- Knob Acutator Service: 根据实时事件控制 knobs 的启用状态；
- Degradable service: 可降级的服务。

### 事故处理

![oncall](/media/oncall.png)

## 总结（个人观点）

这套系统的好处大概有：

- 故障粒度的控制（设计和实现的时候就需要考虑故障）；
- 故障影响在功能层面的可视化以及；
- 故障可直接在软件层面模拟（通过控制 Knob 状态）。

当然，天下没有免费的午餐。

- 需要有监控系统的配合；
- knob 的维护。
