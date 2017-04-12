---
categories:
- linux
date: 2016-05-05T00:00:00Z
description: ""
tags:
- git
title: git post-receive pitfall
url: /2016/05/05/git-post-receive-pitfall/
---


昨天下午折腾一个 `git` 仓库的 hook 脚本问题 - 我在远程仓库的
`post-receive` 脚本中指定去更新另外一个工作目录，虽然脚本被执行了，且
手工单独运行时工作正常，但是放在 hook 脚本中跑就是不行。原因在于远程
`git` 运行 hook 脚本时，环境变量`GIT_DIR` 会被设为 `.`，因而导致错误。

该脚本可以写为如下：

```
cd /path/to/working/dir
unset GIT_DIR
git pull origin master
```

其中清除 `GIT_DIR` 非常重要[^1]。可惜，
[官方文档](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)
中根本就没有提。

或者，更直接一点:

```
git --work-tree=/path/to/working/dir \
    --git-dir=/path/to/working/dir/.git \
    pull origin master
```

[^1]: [git post-receive not working correctly](https://stackoverflow.com/questions/9905882)

