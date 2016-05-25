## 简介
* 1. LAMP 指的是 Linux + Apache + MySQL + PHP 运行环境
* 2. LAMP 一键安装是用 Linux Shell 语言编写的，用于在 Linux 系统(Redhat/CentOS/Fedora)上一键安装 LAMP 环境的工具脚本。

## 本脚本的系统需求
* 需要 2GB 及以上磁盘剩余空间
* 需要 64M 及以上内存空间
* 服务器必须配置好软件源和可连接外网
* 必须具有系统 Root 权限
* 建议使用干净系统全新安装
* 日期：2015 年 11 月 01 日

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

## 将会安装（通过 yum 安装）
* 1、Apache (Default version)
* 2、MySQL 5.5 or MariaDB 5.5 latest version
* 3、PHP 5.4 or 5.5 or 5.6 latest version
* 4、phpMyAdmin 4.4 latest version
* 5、Xcache (PHP 5.4 only)
* 6、Zend Guard Loader (PHP 5.4 only)
* 7、ionCube PHP Loader (PHP 5.4 only)

## 如何安装
### 第一步，下载、解压、赋予权限：

    yum install -y unzip
    wget --no-check-certificate https://github.com/sspanel/lamp-yum/archive/master.zip -O lamp-yum.zip
    unzip lamp-yum.zip
    cd lamp-yum-master/
    chmod +x *.sh

### 第二步，安装LAMP
终端中输入以下命令：

    ./lamp.sh 2>&1 | tee lamp.log

##使用提示：

* lamp uninstall：一键删除 LAMP （切记，删除之前注意备份好数据！）

##目录说明：

* MySQL 或 MariaDB 数据库目录： /var/lib/mysql/
* 默认的网站根目录： /data/www/default

##命令一览：
* MySQL 或 MariaDB 命令: 

        /etc/init.d/mysqld(start|stop|restart|reload|status)

* Apache 命令: 

        /etc/init.d/httpd(start|stop|restart|reload|status)

如果你在安装后使用遇到问题，请访问 [https://teddysun.com/lamp-yum](https://teddysun.com/lamp-yum) 提交评论。

Copyright (C) 2015 Teddysun <i@teddysun.com>
