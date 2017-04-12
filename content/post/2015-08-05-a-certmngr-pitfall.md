---
categories:
- work
date: 2015-08-05T00:00:00Z
description: ""
tags:
- Windows
title: A CertMngr Pitfall
url: /2015/08/05/a-certmngr-pitfall/
---


这两天碰到一个比较坑的问题，对于一个证书，用CertMngr导入进去后，我在自
己的机器上可以导出为pfx，而实习生的机器上死活不行。上午出手去试了一把，
搞定后，实习生手快好奇心重，没有导出就先删掉了。然后重新导入后再导出，
就真的死活都不行了。我满怀信心地在自己的机器删除掉重新导入、导出，发现
结果一模一样。汗。

网上搜了一下，找到了[答案](https://support.microsoft.com/en-us/kb/889651)。
先找到证书的序列号，然后以管理员身份运行：

~~~
certutil -repairstore my "SerialNumber"
~~~
