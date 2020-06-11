+++
title = "Random Bits (3)"
date = 2020-06-12T00:04:43+08:00
tags = ["zstack"]
categories = ["work"]
draft = false
+++

最近救了两场火，聊以记录。

## Vyos on ARM64

同学终于搞出可用的 Vyos ARM64 镜像，但 `commit` 总是报错。上去看了一下，
默认的 `Perl` 版本和 `perl-modules` 版本不一样。重新编译了 Vyatta 相关的包，
去除不正确的 `perl-modules` 依赖即可。

## OpenSSH 8.2 for CentOS 7

CentOS 7 上没法直接用 CentOS 8 的 OpenSSH `rpm` 包，需要自己动手编译。
源代码里自带的 `contrib/redhat/openssh.spec` 需要小修改一下。最有意思
的还是 `Fedora Project` 自己的[文档](https://docs.fedoraproject.org/en-US/packaging-guidelines/Scriptlets/)， 
解释了各种 `trigger` 脚本的执行时序和条件。深入理解 `spec` 文件的好帮手。

   -      | install | upgrade | uninstall
----------|---------|---------|----------
%pretrans | $1 == 0 | $1 == 0 | (N/A)
%pre      |	$1 == 1 | $1 == 2 | (N/A)
%post     | $1 == 1 | $1 == 2 | (N/A)
%preun    | (N/A)   | $1 == 1 | $1 == 0
%postun   | (N/A)   | $1 == 1 | $1 == 0
%posttrans| $1 == 0 | $1 == 0 | (N/A)

## net.schmizz sshj with OpenSSH 8.2

CentOS 7 上的 OpenSSH-8.2 是编译出来了，安装、升级也都挺好使。碰到了
sshj 报错协商密钥交换算法失败。似乎 `sshj` 只支持 DH-G-sha1，尝试升级了
其依赖的 `bcprov-jdk16` 也不顶用。改用 `jsch` 解决之。
