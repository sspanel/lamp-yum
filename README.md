## 简介
* 1. LAMP 指的是 Linux + Apache + MySQL + PHP 运行环境
* 2. LAMP 一键安装是用 Linux Shell 语言编写的，用于在 Linux 系统(Redhat/CentOS/Fedora)上一键安装 LAMP 环境的工具脚本。

## 本脚本的系统需求
* 需要 2GB 及以上磁盘剩余空间
* 需要 64M 及以上内存空间
* 服务器必须配置好软件源和可连接外网
* 必须具有系统 Root 权限
* 建议使用干净系统全新安装
* 日期：2014年08月18日

## 关于本脚本
* 一键 yum 安装所有的软件包，方便升级；
* 支持 PHP 自带所有组件；
* 支持 MySQL ，MariaDB 数据库;
* 支持 XCache；
* 支持 Zend Guard Loader；
* 支持 ionCube PHP Loader；
* 支持自助升级 phpMyAdmin；
* 命令行新增虚拟主机，操作简便；
* 一键卸载。

## 将会安装（yum 安装）
* 1、Apache 2.2.15
* 2、MySQL 5.5.38 或 MariaDB 5.5.37
* 3、PHP 5.4.31
* 4、phpMyAdmin 4.2.7.1
* 5、xcache
* 6、Zend Guard Loader
* 7、ionCube PHP Loader

## 如何安装
### 第一步，下载、解压、赋予权限：

    wget --no-check-certificate https://github.com/teddysun/lamp-yum/archive/master.zip -O lamp-yum.zip
    unzip lamp-yum.zip
    cd lamp-yum-master/
    chmod +x *.sh

### 第二步，安装LAMP
终端中输入以下命令：

    ./lamp.sh 2>&1 | tee lamp.log

##使用提示：

* lamp add(del,list)：创建（删除，列出）虚拟主机。
* lamp uninstall：一键删除 LAMP （切记，删除之前注意备份好数据！）

##目录说明：

* MySQL 或 MariaDB 数据库目录： /var/lib/mysql/
* 默认的网站根目录： /data/www/default
* 新建虚拟主机目录： /data/www/domain（此处 domain 为添加的域名）

##命令一览：
* MySQL 或 MariaDB 命令: 

        /etc/init.d/mysqld(start|stop|restart|reload|status)
        service mysqld(start|stop|restart|reload|status)

* Apache 命令: 

        /etc/init.d/httpd(start|stop|restart|reload|status)
        service httpd(start|stop|restart|reload|status)      

如果你在安装后使用遇到问题，请访问 [http://teddysun.com/lamp-yum](http://teddysun.com/lamp-yum) 或发邮件至 i@teddysun.com。

最后，祝你使用愉快！
