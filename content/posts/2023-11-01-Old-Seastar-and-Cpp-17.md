+++
title = "(Old) Seastar and C++17"
date = 2023-11-01T15:26:01+08:00
tags = ["c++"]
categories = ["work"]
draft = false
+++

在 CentOS Stream 8 上编译老版本 [Seastar](https://seastar.io/) 时碰到两个问题，记录一下。

### cannot deduce template arguments for ‘tuple’ from ()

编译 `sharded.hh` 报错，用[最新的代码](https://docs.seastar.io/master/sharded_8hh_source.html)也还是错，于是手动修改如下：

```diff
--- include/seastar/core/sharded.hh.orig      2023-11-01 15:22:58.800059019 +0800
+++ include/seastar/core/sharded.hh   2023-11-01 13:28:22.994261504 +0800
@@ -764,7 +764,7 @@
     static_assert(std::is_same_v<futurize_t<std::invoke_result_t<Func, Service&, Args...>>, future<>>,
                   "invoke_on_all()'s func must return void or future<>");
   try {
-    return invoke_on_all(options, invoke_on_all_func_type([func, args = std::tuple(std::move(args)...)] (Service& service) mutable {
+    return invoke_on_all(options, invoke_on_all_func_type([func, args = std::tuple<Args...>(std::move(args)...)] (Service& service) mutable {
         return futurize_apply(func, std::tuple_cat(std::forward_as_tuple(service), args));
     }));
   } catch (...) {
```

### undefined reference to `std::filesystem::...`

CentOS Stream 8 当前维护的是 GCC 8.5.0, 里面实现了 C++17 标准中定义的
`std::filesystem` 接口。作为试验特性，代码并未包含在标准库 `libstdc++`
中。使用的时候需要指定 `--std=c++17 -lstdc++fs`, 否则就会链接报错。
有意思的是，磁盘上并没有 `/usr/lib64/libstdc++fs.so`.

GCC 9 不需要（也不能）指定 `-lstdc++fs` 这个链接选项。
