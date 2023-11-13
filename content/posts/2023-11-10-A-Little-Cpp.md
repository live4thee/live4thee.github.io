+++
title = "A Little C++"
date = 2023-11-10T11:30:45+08:00
tags = ["c++"]
categories = ["work"]
draft = false
+++

好久没用 `C++` 了，当项目里重度使用现代 `C++`（`c++11` 以及后续标准）
的新特性时，就有点力不从心 -- 书到用时方恨少。

```cpp
template <typename... A>
void set(A&&... a) noexcept {
  assert(_u.st == state::future);
  new (this) future_state(ready_future_marker(), std::forward<A>(a)...);
}
```

这段代码来自
[Seastar](https://github.com/scylladb/seastar/blob/master/include/seastar/core/future.hh#L622),
是在 `future_state` 上实现了 `set` 方法。

## parameter pack

我们知道 C 里面有变长参数，比如 `printf` 的原型：

```c
int printf(const char *format, ...);
```

C++ 模板类型后面的跟三个点是 C++11 里引入的模板参数包 ([template parameter pack](https://en.cppreference.com/w/cpp/language/parameter_pack)). 比如，以 C++11 风格定义一个 Tuple 模板：

```cpp
template<typename... Types>
struct Tuple {};

Tuple<> t0;           // Types contains no arguments
Tuple<int> t1;        // Types contains one argument: int
Tuple<int, float> t2; // Types contains two arguments: int and float
```

既然有 `pack`, 那么相应的就有 `unpack` 或者 `expansion`, 直接看[标准](https://en.cppreference.com/w/cpp/language/parameter_pack)。

## l-value & r-value

左值和右值是 C 里面就有的[概念](https://www.internalpointers.com/post/understanding-meaning-lvalues-and-rvalues-c)，“左”和“右” 是赋值操作符 “=” 的左侧和右侧。左值可被赋值，而右值一般没
有内存地址，不可被赋值。简单来说，左值是指可以取地址的、具有持久性的对
象，而右值是指不能取地址的、临时生成的对象。比如：

```c
int a = 10;
```

这里 `a` 是左值（`a+0` 是右值），`10` 是右值，可能只会在汇编代码的立即
数中出现，临时存放在某个寄存器而不是内存中。在 C++ 里，下面的代码无法
编译成功：

```cpp
int& b = 3;
```

报错：

```text
cannot bind non-const lvalue reference of type ‘int&’ to an rvalue of type ‘int’
```

传统 C++ 代码中，这里改成常量左值引用就可以。

```cpp
const int& b = 3; // ok. bind a const lvalue to an rvalue
```

### r-value references

`T&& v` 的意思是：`v` 是一个右值引用。右值引用是 C++11 引入的概念，并且，
右值也可以被修改！比如，下面的代码：

```cpp
int&& b = 3;      // ok. rvalue reference
b += 1;           // ok. `b' 可以被修改！
```

这[有啥好处](https://www.internalpointers.com/post/c-rvalue-references-and-move-semantics-beginners)呢？用来实现 move semantics, 提高性能。[^vcat]

[^vcat]: 进一步的分类可参考 [value category](https://en.cppreference.com/w/cpp/language/value_category).

### move semantics

`Move semantics` 的核心要素是避免拷贝开销。

> Move semantics is a new way of moving resources around in an optimal
> way by avoiding unnecessary copies of temporary objects, based on
> rvalue references.

C++ 有一个 [Rules of Three](https://en.wikipedia.org/wiki/Rule_of_three_%28C++_programming%29),
就是说当某个类需要管理动态内存时，最好显式地实现三个成员方法：

1. 析构函数
2. 拷贝构造函数
3. 重载拷贝赋值运算符(copy assignment operator) 

```cpp
Foo f1;      // regular constructor
Foo f2 = f1; // copy constructor
Foo f3(f1);  // copy constructor (alternate syntax)
Foo f4;
f4 = f1;     // copy assignment operator
```

一般来说，拷贝构造函数、重载赋值操作符有类似如下逻辑：

```cpp
// copy constructor
Foo(const Foo& rhs)
{
  m_data = new int[rhs.m_size];  // 初始化内存
  std::copy(rhs.m_data, rhs.m_data + rhs.m_size, m_data); // 复制数据
  m_size = rhs.m_size;
}

// assignment operator
Foo& operator=(const Foo& rhs) 
{
  if(this == &rhs) return *this;  // 避免自我赋值
  delete[] m_data;                // 释放已有内存
  m_data = new int[rhs.m_size];   // 分配新内存
  std::copy(rhs.m_data, rhs.m_data + rhs.m_size, m_data); // 复制数据
  m_size = rhs.m_size;
  return *this;
}
```

两者的共同特征有：

1. 作为输入参数的被复制对象都是以 `const` 引用传入；
2. 作为输出对象，其管理的内存都是复制了一份，源对象的内容没有改动。

### copy ctor & move ctor

如果代码里存在这样的调用：

```cpp
// 注意: 这里显然不能返回 Foo&, 否则将会引用一个已经释放的本地变量。
Foo createFoo(int n) {
  return Foo(n);
}
```

对于这段代码，`Foo f = createFoo(10);` 将会造成若干数据拷贝：[^rvo]
- `Foo(n)` 产生一次构造函数
- `return` 产生一次拷贝构造函数
- `Foo f = ...` 产生一次拷贝构造函数

[^rvo]: 需要指定`-fno-elide-constructors`，否则将因为 RVO 优化而只会
    调用一次构造函数。

为了解决临时拷贝的开销，c++11 引入了 `move semantics`: 传递数据的地址
（而不是内容本身）。因此，c++11 额外定义了 `move constructor` 以及 `move
assignment constructor`. 入参都是 `rvalue reference`:

```cpp
Foo(Foo&& other) {
  m_data = other.m_data;   // 直接保存地址
  m_size = other.m_size;
  other.m_data = nullptr;  // 所有权转移到了新对象，避免被释放多次。
  other.m_size = 0;
}

Foo& operator=(Foo&& other) {
  if (this == &other) return *this;

  delete[] m_data;         // 先释放已有内存

  m_data = other.m_data;   // 直接保存地址
  m_size = other.m_size;

  other.m_data = nullptr;  // 避免释放多次
  other.m_size = 0;
  return *this;
}

Foo createFoo(int n) {
  return Foo(n); // 此时会使用 move constructor
}

int main()
{
  Foo f1;      // regular constructor, 不变
  Foo f2 = f1; // copy constructor, 不变
  Foo f3(f1);  // copy constructor (alternate syntax), 不变
  Foo f4;
  f4 = f1;     // copy assignment operator, 不变
  f4 = createFoo(5) // move assignment.
}
```

前面我们看到 `createFoo()` 因为编译器的 RVO 优化，使得看起来即使不实现
`move constructor` 也无伤大雅。但是，我们其实也可以通过 `move
semantics` 偷窃一个入参：

```cpp
  Foo f1(1000); // f1 is an lvalue
  Foo f2(f1);   // copy-constructor invoked (because of lvalue in input)
  Foo f3(std::move(f1)); // move-constructor invoked
```

注意：当 `f3` 偷窃了来自 `f1` 的数据之后，后者的指针会被设为
`nullptr`![^guide] 看起来有点吓人，因此以下是一些忠告：

- 为 `move constructor` 以及 `move assignment constructor` 加上
  `noexcept`. 这两个构造函数不应该涉及分配资源。
- 为了避免示例中的重复代码，考虑使用 [copy-and-swap](https://stackoverflow.com/a/3279550/3296421).
- 实现完美转发(perfect forwarding)。[^fwd]

[^guide]: 参考 [C++ rvalue references and move semantics for beginners](https://www.internalpointers.com/post/c-rvalue-references-and-move-semantics-beginners)

[^fwd]: 参考 https://stackoverflow.com/a/3582313/3296421

##  std::forward

[std::forward](https://en.cppreference.com/w/cpp/utility/forward) 也是
C++11 引入的。它的作用是根据传入的参数，决定将参数以左值引用还是右值引
用的方式进行转发。使用左值还是右值的引用，决定转发后调用构造函数还是移
动构造函数。详情参考[完美转发示例](https://www.justsoftwaresolutions.co.uk/cplusplus/rvalue_references_and_perfect_forwarding.html)，[示例2](https://stackoverflow.com/a/3582313/3296421)，
以及背后的[原理](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2002/n1385.htm)。

## new(this)

用来调用指定对象的构造函数，类似拷贝构造函数的行为。

```cpp
struct base {
  base() {
    std::cout << "base" << std::endl;
  }
};

struct derived : base {
  derived() {
    std::cout << "derived" << std::endl;
	new(this) base(); // line 10
  }
};
```

声明一个对象 `derived d`，则会打印出：

```text
base
derived
base
```

`derived` 的构造函数执行时，其继承的基类 `base` 的构造函数已经执行完毕，
后续第 10 行再次执行里 `base` 的构造函数。

这种用法需要注意两个问题：
1. 如果第 10 行是 `new(this) derived()`, 就会重复调用构造函数自身造成
   堆栈溢出 -- 不要在构造函数里使用；
2. 如果 `this` 实例的成员变量包含动态分配的内存，则会发生内存泄漏。
