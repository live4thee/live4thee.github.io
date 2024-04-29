---
title: "Ramblings"
date: 2024-04-29T09:45:47+08:00
tags: [ "family" ]
categories: [ "life" ]
draft: false
---

## 目标和松弛

25 号中午跑完一次艰苦的无氧后，本月跑量达到了 92.2 公里，距离之前的
100.4 公里最好记录仅一步之遥。然而这几天没有一鼓作气，训练状态从
Productive 到 Maintaining 再滑到 Recovery.

- “行百里者半九十” -- 古人诚不我欺。
- “只要还有时间，工作就会不断扩展，直到用完所有的时间。” -- 帕金森诚不欺我。

中午跑了 9.28km, 月跑量记录完成了一次小突破。统计信息中 RHR 仍然是 49, 
肉眼算了一下，最后心率提到 164, 休息看表的时候 115 左右，居然大差不差。

状态再次回到 Maintaining... 哎～ 数据驱动的~~科学~~讨厌之处。

## 盲道

### 一部MV (Music Video)

周末休息一天。午餐后，一起散布。顺口和孩子讲了地上铺的盲道，然后就和夫
人讨论盲人能不能独自、独力生活。此时，小朋友也一本正经地闭上眼睛，发现
自己走不了几步就偏离的方向。我突然想起大学时有个非常风靡的韩国MV. 大意
是一位男摄影师偶遇了后来成为助手的女主，后者某次不小心在暗房打翻了放在
高处的显影剂，双眼致盲，然后男主把眼睛换给女主。片子最后女主康复，
出门偶遇戴着墨镜、牵着导盲犬的男主，失声痛哭。

夫人问，是不是“[假如爱有天意](https://www.bilibili.com/video/BV1gp4y1D738/)”？
-- 女主是孙艺珍哦。搜了一下，不是。
再搜，答案是“[因为是女子](https://www.bilibili.com/video/BV15f4y1A76n/)”, 
评论区有一条饱含时光的评论：“有谁还记得3GP这个格式”。

### 一部电影

另一部看过的盲人相关的电影是《[闻香识女人](https://movie.douban.com/subject/1298624/)》。
无论标题、还是那段名垂影史的探戈，都容易让人认为这是一部香艳的爱情电影。
然而实际上本片几乎没有女主。

> 无论生活的面目是温顺还是狰狞，我们都需要为我们的选择、要走的道路，想
> 要追求的目标做出努力。而死亡永远不能成为逃避的借口和途径，活着需要有
> 比选择死亡更大的勇气，承担责任的勇气。

以上来自[影评](https://movie.douban.com/review/1284110/)。

## darktable

### 两种工作流

相机两张卡，分别存放 jpg 和 raw. 和夫人各取所需。

- 不用 RAW 还买什么相机？
- RAW 有更大的后期调色空间、包括各种堆栈等等。

作为工科出身，我自然是赞同的。直到 -- “拍照一时爽，修图火葬场”，特别是
从 Canon 换到 Sony 之后的一段时间。夫人 JPG 一导，朋友圈一发，结束。
当日事、当日毕，效率极高。

至于我，周末盯着屏幕纹丝不动的时候，经常耳边传来：“这都是哪年的图了，
你怎么还在修？” 神奇的是：音量会越来越小。可能是夫人走开了，也可能我进
化出了自动“降噪”的能力。不禁怀疑前述两点有相关厂商的推波助澜。

### 我爱学习？

我的调色软件用[darktable](https://www.darktable.org/). 导入 Sony 的
RAW 后默认的颜色看起来那叫一个寡淡（`dull`）。以我工科大脑的审美水平，
调出来的照片那叫一个糟糕（`terrible`）。

遇事不决多学习。[PIXLS.US](https://discuss.pixls.us/tag/darktable)有很
多丰富的知识，比如：[Profiling a camera with darktable-chart](https://pixls.us/articles/profiling-a-camera-with-darktable-chart/).
掌握了该方法后，就能创建出任何想要的 LUT - 一套上去就能获得想要的风格。
掂量了一番自己的知识水平和要花费的时间之后，还是选择了“拿来主义” -- 找
到了一个现成的针对 A7m3 的 LUT. 也就是说，RAW + LUT 得到了一个机内 jpg
默认直出的视觉效果。呃...

### 客户的角度？

我司有个良好的价值主张：客户第一。如果把自己看成是客户：我要的是短平快，
再酌情为图片增加一点自己的偏好。因此，如果 DT 导入图片后，如果像 Lr 那
样默认给出一个好看的效果，这应该是绝大部分人希望看见的结果（包括我）。

DT 导入 RAW 后给出的是未经任何调整的色彩。PIXLS.US 有若干讨论：

- 2021/06 [Software defaults, looks and starting points - Not software specific discussion](https://discuss.pixls.us/t/software-defaults-looks-and-starting-points-not-software-specific-discussion/25338)
- 2021/09 [Dull Images after importing](https://discuss.pixls.us/t/dull-images-after-importing/26728)
- 2022/03 [Why do darktable colours look like sh*t](https://www.youtube.com/watch?v=EZCwB7FogUs)? - 来自 DT 开发者。
- 2022/10 [How to get more accurate colors in DT for Sony (Capture One vs Darktable)](https://discuss.pixls.us/t/how-to-get-more-accurate-colors-in-dt-for-sony-capture-one-vs-darktable/32959)?
- 2023/02 [How to get a pleasing result in a quick way](https://discuss.pixls.us/t/how-to-get-a-pleasing-result-in-a-quick-way-comparison-to-lightroom/35452)?

其中有几点，有点意思：

> “People” don’t exist. The “average photographer” does not
> exist. There are defined groups of people, with different skills
> sets and expectation, that are irreconciliable with each other.

我认同上述论据，但并不认同因此而采取的决策。作为无损编辑软件，用户可以
选择取消预设的编辑。喜欢的可以自己用，不喜欢的取消预设自己调即可。

> And I don’t care what the big companies are doing. They are there to
> make profits and sales. Eastman understood way ahead of his time
> that profits are in the unskilled, the untrained and the
> amateurs. Those users have plenty of commercial options. Now, what
> do the other have? You know, the non-profitable fringe of the market
> that doesn’t need hand-holding ? They have endless cycles of
> tutorials and dumb software that want them to stay beginner for
> life.
>
> There is no point in redoing opensource commercial software with
> less ressources. It’s doomed to fail. Salvation comes from allowing
> what they don’t, catering to the crowd they choose to forgot.

翻译一下，主要表达了如下观点：

- DT 面向的是专业用户 - 提供机制而非策略，用户需要了解自己的工具箱。
- 商业软件在某种程度上让用户一直保持在入门水平。
- 用有限的资源去重复商业软件的行为注定会失败。

作为免费使用的开源软件，DT 无疑是优秀的。我是 DT 的用户，却不是客户（没花钱）。
主动也好、被动也罢，使用 DT 的过程中，也学到了一些知识。

下图左边直出，右边手调。虽然暗部还是略矬，总算比直出看起来好一点了。

![jpg-raw](/media/jpg-raw-dev.jpg)
