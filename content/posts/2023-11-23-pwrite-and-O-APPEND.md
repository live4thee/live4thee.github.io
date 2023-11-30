+++
title = "pwrite() & O_APPEND"
date = 2023-11-23T13:03:41+08:00
tags = ["c++"]
categories = ["linux"]
draft = false
+++

Linux 的 `pwrite()` 有个 BUG: 当文件以 `O_APPEND` 模式打开时，虽然 file offset
不会变，但是写入的内容会追加到文件尾部。

此外，`pwrite()` 和 `pwritev()` 的 offset 参数不能为 -1, 否则会 EINVAL. 
但是 `pwritev2()` 可以，表示使用当前的 file offset 并且会更新之。

```text
man(2) pwrite
BUG
    POSIX  requires that opening a file with the O_APPEND flag should have
    no effect on the location at which pwrite() writes data.  However,  on
    Linux, if a file is opened with O_APPEND, pwrite() appends data to the
    end of the file, regardless of the value of offset.
```

下面是个示例程序：

```c
#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>

int main(int argc, char* argv[])
{
    int flags, fd;

    if (argc != 2) {
        printf("usage: %s file\n", argv[0]);
        return 1;
    }

    flags = O_RDWR | O_CREAT | O_TRUNC;
    if (strstr(argv[1], "append") != NULL) {
        flags |= O_APPEND;
    }

    fd = open(argv[1], flags, 0600);
    if (fd < 0) {
        perror("open");
        return 1;
    }

    if (write(fd, "hello\n", 6) < 0) {
        perror("write");
    }

    printf("offset: %ld\n", lseek(fd, 0, SEEK_CUR));

    /* offset = -1 => EINVAL */
    if (pwrite(fd, "world\n", 6, 0) < 0) {
        perror("pwrite");
    }

    printf("offset: %ld\n", lseek(fd, 0, SEEK_CUR));

    close(fd);
    return 0;
}
```

运行结果：

```sh
$ ./a.out hello; cat hello
offset: 6
offset: 6
world
$ ./a.out append; cat append
offset: 6
offset: 6
hello
world
```
