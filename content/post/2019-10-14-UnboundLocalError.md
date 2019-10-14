+++
title = "UnboundLocalError"
description = ""
date = "2019-10-14T09:36:10+08:00"
tags = ["python"]
categories = ["programming"]
+++

最近碰到个 'UnboundLocalError', 初看不可思议，知道原理后就释然了。

```python
# file: test.py
def e(x): print(x)

def g():
    e(1)
    e = 1

g()
```

运行一下：

```sh
$ python test.py
Traceback (most recent call last):
  File "test.py", line 7, in <module>
    g()
  File "test.py", line 4, in g
    e(1)
UnboundLocalError: local variable 'e' referenced before assignment
```

这里的问题在于那一行 'e = 1'. 有了这一行，Python 就认为 'e' 是函数 'g'
的本地变量（因为没有在 'g' 里面写 'global e'），这就导致了调用 'e(1)'
的报错 - 因为这时候变量 'e' 在函数 'g' 内尚未绑定任何值。

## Python 的变量作用域规则

```text
In python all the variables inside a function are global if they are
not assigned any value to them. That means if a variable is only
referenced inside a function, it is global. However if we assign any
value to a variable inside a function, its scope becomes local to that
unless explicitly declared global.
```

更多例子，参考：[Python Scoping Rules](https://stackoverflow.com/questions/291978/short-description-of-the-scoping-rules)
