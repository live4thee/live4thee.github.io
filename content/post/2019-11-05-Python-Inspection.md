+++
title = "Python Inspection"
description = ""
date = "2019-11-05T10:42:28+08:00"
tags = ["python"]
categories = ["programming"]
+++

作为程序员，经常有查看源代码的需求。如果没有代码，能反汇编也不至于两眼
摸黑。Python 这方面的支持做的挺不错。

## inspect

[inspect](https://docs.python.org/3/library/inspect.html) 定义了很多有
用的函数，比如：_getsource_

~~~py
>>> import netaddr
>>> import inspect
>>> print(inspect.getsource(netaddr.cidr_to_glob))
def cidr_to_glob(cidr):
    """
    A function that accepts an IP subnet in a glob-style format and returns
    a list of CIDR subnets that exactly matches the specified glob.

    :param cidr: an IP object CIDR subnet.

    :return: a list of one or more IP addresses and subnets.
    """
    ip = IPNetwork(cidr)
    globs = iprange_to_globs(ip[0], ip[-1])
    if len(globs) != 1:
        #   There should only ever be a one to one mapping between a CIDR and
        #   an IP glob range.
        raise AddrConversionError('bad CIDR to IP glob conversion!')
    return globs[0]

>>>
~~~

## dis

[dis](https://docs.python.org/3/library/dis.html) 用来反汇编 Python 字
节码。

~~~py
>>> import dis
>>> def add(a, b): return a+b
...
>>> dis.dis(add)
  1           0 LOAD_FAST                0 (a)
              3 LOAD_FAST                1 (b)
              6 BINARY_ADD
              7 RETURN_VALUE
>>>
~~~

## gdb

无论 _dis_ 还是 _inspect_ 都不能处理 C 实现的的函数。比如：

~~~py
>>> from fcntl import flock
>>> dis.dis(flock)
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
  File "/usr/lib/python2.7/dis.py", line 49, in dis
    type(x).__name__
TypeError: don't know how to disassemble builtin_function_or_method objects
~~~

这种情况下，_gdb_ 就成了不二之选。先把 debug 包给装上：

~~~sh
$ sudo debuginfo-install `rpm -q python`
~~~

先 attach 到被调试的 python 进程，假设 pid 是 11170. 然后 'pi' 进入
Python 交互环境。

~~~sh
$ gdb python 11170
(gdb) pi
~~~

接下来，反汇编：

~~~py
>>> from fcntl import flock
>>> frame=gdb.selected_frame()
>>> arch=frame.architecture()
>>> arch.disassemble(flock)
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
TypeError: argument 1 must be integer<K>, not builtin_function_or_method
>>> flock.__str__
<method-wrapper '__str__' of builtin_function_or_method object at 0x7fad357181b8>
>>> arch.disassemble(0x7fad357181b8)
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
gdb.MemoryError: Cannot access memory at address 0x7fad357181b8
>>>
~~~

看来，不咋行。还是老老实实看[源代码](https://github.com/python/cpython/blob/master/Modules/fcntlmodule.c#L38)吧！
