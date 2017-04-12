---
categories:
- programming
date: 2016-10-18T00:00:00Z
description: ""
tags:
- c++
title: Modern C++
url: /2016/10/18/modern-cpp/
---


一点笔记，来自 [Modern C++](http://klmr.me/slides/modern-cpp)

最重要的一点：*不要直接用指针*。因为它直接暴露了内存区域，且不能传达出
所有者相关语义。Pointers must *NOT* own resources. 以下是一些例子：

```
// bad
int* pi = new int;
// good
int i;

// bad
int* arr = new int[1024];
// good
std::array<int, 1024> arr;

// bad
int* arr = new int[n];
// good
std::vector<int> arr(n);

// bad
char* str = new char[1024];
// good
std::string str;

// bad
void draw_shape(Shape const* shape);
draw_shape(new Rectangle);

// good
void draw_shape(Shape const& shape);
draw_shape(Rectangle());

// bad
huge_object* build_new_object() {
  huge_object* ret = new huge_object;
  // ...
  return ret;
}
// good
huge_object build_new_object() {
  huge_object ret;
  // ...
  return ret;
}

// bad
struct owner {
  resource* pr;
  owner() : pr(new resource) { }
  ~owner() { delete pr; }
};
// good
struct owner {
  std::unique_ptr<resource> r;

  owner() : r(new resource) { }
};
// or, shared
struct owner {
  std::shared_ptr<resource> r;

  owner() : r(make_shared()) { }
};
```
