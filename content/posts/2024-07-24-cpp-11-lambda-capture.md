---
title: "C++11 Lambda Capture"
date: 2024-07-24T17:49:39+08:00
tags: [ "c++" ]
categories: [ "programming" ]
draft: false
---

好记性不如烂笔头，内容来自[cppreference.com](https://en.cppreference.com/w/cpp/language/lambda).

## 语法
c++11 的 lambda capture 大概有如下语法：

`identifier`       | (1)
-------------------|-----|---
`identifier ...`   | (2)
`identifier initializer` | (3) |    (since C++14)
    `& identifier` |  (4)
`& identifier ...` |  (5)
`& identifier initializer` | (6) |(since C++14)
            `this` | (7)
          `* this` | (8)| (since C++17)
`... identifier initializer`   | (9)  | (since C++20)
`& ... identifier initializer` | (10) |  (since C++20)

其中，

- (1) simple by-copy capture
- (2) simple by-copy capture that is a pack expansion
- (3) by-copy capture with an initializer
- (4) simple by-reference capture
- (5) simple by-reference capture that is a pack expansion
- (6) by-reference capture with an initializer
- (7) simple by-reference capture of the current object
- (8) simple by-copy capture of the current object
- (9) by-copy capture with an initializer that is a pack expansion
- (10) by-reference capture with an initializer that is a pack expansion

如果某个 lambda 的 capture-default 是 `&`, 则后续的 simple capture 不能再以 `&` 打头 -- 没啥意义。

### 示例1

```c++
struct S2 { void f(int i); };
void S2::f(int i)
{
    [&] {};          // OK: by-reference capture default
    [&, i] {};       // OK: by-reference capture, except i is captured by copy
    [&, &i] {};      // Error: by-reference capture when by-reference is the default
    [&, this] {};    // OK, equivalent to [&]
    [&, this, i] {}; // OK, equivalent to [&, i]
}
```

同理， 如果某个 lambda 的 capture-default 是 `=`, 则后续的 simple capture 必须以 `&` 打头。

### 示例2

```c++
struct S2 { void f(int i); };
void S2::f(int i)
{
    [=] {};        // OK: by-copy capture default
    [=, &i] {};    // OK: by-copy capture, except i is captured by reference
    [=, *this] {}; // until C++17: Error: invalid syntax
                   // since C++17: OK: captures the enclosing S2 by copy
    [=, this] {};  // until C++20: Error: this when = is the default
                   // since C++20: OK, same as [=]
}
```

### 示例3

capture 只能出现一次，且不能和参数重名。

```c++
struct S2 { void f(int i); };
void S2::f(int i)
{
    [i, i] {};        // Error: i repeated
    [this, *this] {}; // Error: "this" repeated (C++17)

    [i] (int i) {};   // Error: parameter and capture have the same name
}
```
