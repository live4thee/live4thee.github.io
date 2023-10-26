+++
title = "Tracker Miners and Git LFS"
date = 2023-10-26T09:44:33+08:00
tags = ["git"]
categories = ["linux"]
draft = false
+++

GNOME 索引程序 `tracker-miner-fs` 占用 CPU 高的原因是我在本机
`Documents` 目录里面有差不多三百个 git 仓库，索引一遍比较耗时。

```text
$ LANG=C tracker3 status
Currently indexed: 369684 files, 48866 folders
... omitted ...
149 recorded failures

Path                                             Message
garage/doc/talks/2021-09-13-ngi-kickoff/talk.pdf Couldn't open PopplerDocument:PDF document is damaged
... omitted ...
```

索引日志里报告本地
[garage](https://git.deuxfleurs.fr/Deuxfleurs/garage.git) 仓库里有一些
pdf 文件损坏。看了一下内容：

```sh
$ file doc/talks/2021-09-13-ngi-kickoff/talk.pdf
doc/talks/2021-09-13-ngi-kickoff/talk.pdf: ASCII text
$ cat doc/talks/2021-09-13-ngi-kickoff/talk.pdf
version https://git-lfs.github.com/spec/v1
oid sha256:d71148e1dae22490588be05b87afadac35a91e029968afb6e54f81b8551c5642
size 439021
```

原来这些 pdf 是用 [git-lfs](https://git-lfs.com/) 管理的。恢复 pdf 文
件也很简单：

```sh
$ sudo apt-get install git-lfs
$ git lfs fetch doc/talks/2021-09-13-ngi-kickoff/talk.pdf
$ git lfs checkout doc/talks/2021-09-13-ngi-kickoff/talk.pdf

# 列出 lfs 管理的文件
$ git lfs ls-files
f0ebb9896b * doc/talks/2020-12-02_wide-team/talk.pdf
4f6cb97852 - doc/talks/2021-04-28_spirals-team/figures/c1.pdf
... omitted ...
```

另外还有一个坑：之前倒数据直接 `scp -r` 而不是 tar over ssh, 而 `scp
-r` 会 follow symbol link, 因此原来的符号链接复制后会变成真实文件本身。
