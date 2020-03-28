+++
title = "MySQL/Mariadb Notes - 1"
date = 2020-03-28T14:31:09+08:00
tags = ["sysadmin"]
categories = ["programming"]
draft = false
+++

## MySQL 8

跑部署脚本的时候，一直报错：

~~~text
ERROR 1064 (42000): You have an error in your SQL syntax; check the manual that corresponds
to your MySQL server version for the right syntax to use near 'IDENTIFIED BY 'secret' at
line 1
~~~

啥，语法错？看了一下执行的 SQL 语句，很正常的样子：

~~~sql
GRANT ALL PRIVILEGES ON dbname.* to 'user'@'%' IDENTIFIED BY "secret";
~~~

把 IDENTIFIED 那段删掉，果然就可以了。搜了一下，原来前几天 apt-get 升
级的时候，本机的 MySQL 升级到了 MySQL 8 版本。现在 GRANT 权限之前，必
须先创建用户。也就是写成：

~~~sql
CREATE USER 'user'@'% IDENTIFIED BY 'secret';
GRANT ALL ON dbname.* TO 'user'@'%';
~~~

c.f. [MySQL 8 removes shorthand for creating user + permissions](https://ma.ttias.be/mysql-8-removes-shorthand-creating-user-permissions/)

## flyway

另外一个 CentOS 环境把 Mariadb 5.5 升级到了 10.3, 跑 flyway 的时候发现
几句 SQL 的写法在新版本已经不合法了。必须改 SQL。但改掉后会改变文件的
哈希值，导致升级时跑 flyway 报错。

### beforeMigrate

第一个尝试是在 flyway 的 beforeMigrate [callbacks](https://flywaydb.org/documentation/callbacks.html) 里面先
把 *schema_version* 里的哈希值改掉。某个帖子看到：beforeMigrate 执行
的时候，*schema_version* 表还没锁。有戏。

兴冲冲写了个 beforeMigrate, 然后 flyway 一个大耳光：哈希错。加上 '-X' 打印调试信息，原来是 valiation 阶段就报错了，还没跑到 migrate 阶
段。不慌，之前的 [callbacks](https://flywaydb.org/documentation/callbacks.html) 里面有个 beforeValidate...

### beforeValidate

beforeValidate 确实打开了新世界的大门。把之前写在 beforeMigrate 的代码
移过去后，验证了一下老版本升级，美美美。沉醉在代码里不可自拔。

恢复环境，回退到老版本，未果。安装脚本报 repo 版本不对。删掉安装目录，
DROP 数据库再次安装，居然报错了！beforeValidate 脚本报错！我美妙的
检查：

~~~sql
IF EXISTS(SELECT table_name FROM information_schema.tables WHERE table_name = 'schema_version')
IF EXISTS(SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'dbname)
~~~

居然统统没管用！但是，单独执行 `mysql ... < beforeValidate.sql` 又工作的很好。
神奇。

### beforeValidate again!

搜到这样[一段描述](https://oipapio.com/question-9217299)：

![flyway](/media/flyway.png)

这个 "one caveat" 仿佛黑暗中一道闪光。flyway 的官网扒了一下 callbacks，
只有简要的描述，没有示例，这对于 error handling 相关的使用毫无用处。最
后 Frank 同学提示可以试试 flyway 的 `baseline` 命令。几番魔改，得到这
样一个稳定工作的时序：

~~~sh
flyway clean # clean environment
flyway baseline
mysql ... 'DELETE FROM schema_version'
flyway migrate
~~~

回头再看，beforeValidate 里的 'IF EXISTS' 既无用也多余。
