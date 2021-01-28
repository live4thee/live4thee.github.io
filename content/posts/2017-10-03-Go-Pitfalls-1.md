+++
categories = ["programming"]
date = "2017-10-03T22:48:40+08:00"
description = ""
tags = ["golang"]
title = "Go Pitfalls (1)"
url = "/2017/10/03/go-pitfalls-1/"
+++

用 `golang` 以来，遇到过一些坑，这里搜集了三个坑的比较惨的例子。

## Variable Shadowing

这个非常容易中招，比如，下面其实是个死循环。

```go
package main

import "fmt"

func getNextCursor(cursor int) (int, error) {
	return cursor + 1, nil
}

func main() {
	for cursor := 1; cursor != 10; {
		cursor, err := getNextCursor(cursor)
		fmt.Println("cursor:", cursor)
		if err != nil {
			return
		}
	}
}

```

还好，可以用 `go tool vet -shadow` 来检查。

```sh
$ go tool vet -shadow x.go
x.go:11: declaration of "cursor" shadows declaration at x.go:10
```

## EOF Handling

这个和 UNIX/Linux 系统调用 `read` 的处理有差异之处。

```go
// ...
// Callers should always process the n > 0 bytes returned before
// considering the error err. Doing so correctly handles I/O errors
// that happen after reading some bytes and also both of the
// allowed EOF behaviors.
// ...
type Reader interface {
    Read(p []byte) (n int, err error)
}
```

对于系统调用 `read`，永远是返回 0 意味着读到了结尾。

## 'defer' Scope

'defer' 是其所在函数的作用域结束才会执行，如果 C++ RAII 用的多一点，这
个其实不是非常完美。'defer' 所在作用域退出就执行会比较好一点。

![Golang defer scope](/media/golang-defer.png)

