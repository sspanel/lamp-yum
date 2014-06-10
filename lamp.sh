#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#===============================================================================================
#   System Required:  CentOS5.x (32bit/64bit) or CentOS6.x (32bit/64bit)
#   Description:  Yum Install LAMP(Linux + Apache + MySQL + PHP ) for CentOS
#   Author: Teddysun <i@teddysun.com>
#   Intro:  http://teddysun.com/lamp-yum
#===============================================================================================

clear
echo "#############################################################"
echo "# Yum Install LAMP(Linux + Apache + MySQL + PHP )"
echo "# CentOS5.x (32bit/64bit) or CentOS6.x (32bit/64bit)"
echo "# Intro: http://teddysun.com/lamp-yum"
echo "#"
echo "# Author: Teddysun <i@teddysun.com>"
echo "#"
echo "#############################################################"
echo ""

# Get IP address
IP=`ifconfig | grep 'inet addr:'| grep -v '127.0.0.*' | cut -d: -f2 | awk '{ print $1}' | head -1`
#Current folder
cur_dir=`pwd`

#===============================================================================================
#Description:Install LAMP Script.
#Usage:install_lamp
#===============================================================================================
function install_lamp(){
    rootness
    disable_selinux
    pre_installation_settings
    install_apache
    install_mysql
    install_php
    install_phpmyadmin
    cp -f $cur_dir/lamp.sh /usr/bin/lamp
    sed -i '/Order/,/All/d' /usr/bin/lamp
    sed -i "/AllowOverride All/i\Require all granted" /usr/bin/lamp
    chmod +x /usr/bin/lamp
    clear
    echo ""
    echo 'Congratulations, Yum install LAMP completed!'
    echo "Your Default Website: http://${IP}"
    echo 'Default WebSite Root Dir: /data/www/default'
    echo "MySQL root password:$mysqlrootpwd"
    echo ""
    echo "Welcome to visit:http://teddysun.com/lamp-yum"
    echo "Enjoy it! "
    echo ""
}

#===============================================================================================
#Description:Make sure only root can run our script
#Usage:rootness
#===============================================================================================
function rootness(){
# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "Error:This script must be run as root!" 1>&2
   exit 1
fi
}

#===============================================================================================
#Description:Disable selinux
#Usage:disable_selinux
#===============================================================================================
function disable_selinux(){
if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
fi
}

#===============================================================================================
#Description:Pre-installation settings.
#Usage:pre_installation_settings
#===============================================================================================
function pre_installation_settings(){
    # Install Atomic repository
    wget -q -O - http://www.atomicorp.com/installers/atomic | sh
    if [ $? -ne 0 ]; then
        echo "Error:Atomic repository must be installed!"
        exit 1
    fi
    # Update Atomic repository
    yum -y update atomic-release
    # Set MySQL root password
    echo "Please input the root password of MySQL:"
    read -p "(Default password: root):" mysqlrootpwd
    if [ "$mysqlrootpwd" = "" ]; then
        mysqlrootpwd="root"
    fi
    echo "MySQL password:$mysqlrootpwd"
    echo "####################################"
    get_char(){
        SAVEDSTTY=`stty -g`
        stty -echo
        stty cbreak
        dd if=/dev/tty bs=1 count=1 2> /dev/null
        stty -raw
        stty echo
        stty $SAVEDSTTY
    }
    echo ""
    echo "Press any key to start...or Press Ctrl+C to cancel"
    char=`get_char`
    # Remove Packages
    yum -y remove httpd*
    yum -y remove mysql*
    yum -y remove php*
    # Set timezone
    rm -f /etc/localtime
    ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    yum -y install ntp
    ntpdate -d cn.pool.ntp.org
}

#===============================================================================================
#Description:Install Apache.
#Usage:install_apache
#===============================================================================================
function install_apache(){
    # Install Apache
    echo "Start Installing Apache..."
    yum -y install httpd
    cp -f $cur_dir/conf/httpd.conf /etc/httpd/conf/httpd.conf
    rm -f /etc/httpd/conf.d/welcome.conf /data/www/error/noindex.html
    chkconfig httpd on
    mkdir -p /data/www/default
    chown -R apache:apache /data/www/default
    touch /etc/httpd/conf.d/none.conf
    cp -f $cur_dir/conf/index.html /data/www/default/index.html
    cp -f $cur_dir/conf/lamp.gif /data/www/default/lamp.gif
    cp -f $cur_dir/conf/p.php /data/www/default/p.php
    cp -f $cur_dir/conf/jquery-1.11.1.min.js /data/www/default/jquery-1.11.1.min.js
    cp -f $cur_dir/conf/phpinfo.php /data/www/default/phpinfo.php
    echo "Apache Install completed!"
}
#===============================================================================================
#Description:install mysql.
#Usage:install_mysql
#===============================================================================================
function install_mysql(){
    #install MySQL
    echo "Start Installing MySQL..."
    yum -y install mysql mysql-server
    cp -f $cur_dir/conf/my.cnf /etc/my.cnf
    chkconfig mysqld on
    #Start mysqld service
    service mysqld start
    /usr/bin/mysqladmin password $mysqlrootpwd
mysql -uroot -p$mysqlrootpwd <<EOF
drop database if exists test;
delete from mysql.user where user='';
update mysql.user set password=password('$mysqlrootpwd') where user='root';
delete from mysql.user where not (user='root') ;
flush privileges;
exit
EOF
    echo "MySQL Install completed!"
}

#===============================================================================================
#Description:install php.
#Usage:install_php
#===============================================================================================
function install_php(){
    #install PHP
    echo "Start Installing PHP..."
    yum -y install libjpeg-devel libpng-devel elinks
    yum -y install php php-devel php-cli php-mysql php-mcrypt php-mbstring php-xml php-xmlrpc php-common
    yum -y install php-gd php-pdo php-bcmath php-xmlrpc php-imap php-odbc php-ldap php-mhash php-intl
    yum -y install php-xcache php-ioncube-loader php-zend-guard-loader php-snmp php-soap php-tidy
    cp -f $cur_dir/conf/php.ini /etc/php.ini
    echo "PHP install completed!"
}
#===============================================================================================
#Description:install phpmyadmin.
#Usage:install_phpmyadmin
#===============================================================================================
function install_phpmyadmin(){
    if [ ! -d /data/www/default/phpmyadmin ];then
        echo "Start Installing phpMyAdmin..."
        LATEST_PMA=$(elinks http://iweb.dl.sourceforge.net/project/phpmyadmin/phpMyAdmin/ | awk -F/ '{print $7F}' | grep -iv '-' | grep -iv 'rst' | tail -1)
        echo -e "Installing phpmyadmin version: \033[41;37m $LATEST_PMA \033[0m"
        cd $cur_dir
        if [ -s phpMyAdmin-${LATEST_PMA}-all-languages.tar.gz ]; then
            echo "phpMyAdmin-${LATEST_PMA}-all-languages.tar.gz [found]"
        else
            wget -c http://iweb.dl.sourceforge.net/project/phpmyadmin/phpMyAdmin/${LATEST_PMA}/phpMyAdmin-${LATEST_PMA}-all-languages.tar.gz
            tar zxf phpMyAdmin-${LATEST_PMA}-all-languages.tar.gz
        fi
        mv phpMyAdmin-${LATEST_PMA}-all-languages /data/www/default/phpmyadmin
        cp -f $cur_dir/conf/config.inc.php /data/www/default/phpmyadmin/config.inc.php
        #Create phpmyadmin database
        /usr/bin/mysql -uroot -p$mysqlrootpwd < /data/www/default/phpmyadmin/examples/create_tables.sql
        mkdir -p /data/www/default/phpmyadmin/upload/
        mkdir -p /data/www/default/phpmyadmin/save/
        cp -f /data/www/default/phpmyadmin/examples/create_tables.sql /data/www/default/phpmyadmin/upload/
        chown -R apache:apache /data/www/default/phpmyadmin
        echo "PHPMyAdmin Install completed!"
    else
        echo "PHPMyAdmin had been installed!"
    fi
    #Start httpd service
    service httpd start
}

#===============================================================================================
#Description:uninstall lamp.
#Usage:uninstall_lamp
#===============================================================================================
function uninstall_lamp(){
    echo "Are you sure uninstall LAMP? (y/n)"
    read -p "(Default: n):" uninstall
    if [ -z $uninstall ]; then
        uninstall="n"
    fi
    if [[ "$uninstall" = "y" || "$uninstall" = "Y" ]]; then
        clear
        echo "==========================="
        echo "Yes, I agreed to uninstall!"
        echo "==========================="
        echo ""
    else
        echo ""
        echo "============================"
        echo "You cancelled the uninstall!"
        echo "============================"
        exit
    fi

    get_char(){
        SAVEDSTTY=`stty -g`
        stty -echo
        stty cbreak
        dd if=/dev/tty bs=1 count=1 2> /dev/null
        stty -raw
        stty echo
        stty $SAVEDSTTY
    }
    echo "Press any key to start uninstall...or Press Ctrl+c to cancel"
    char=`get_char`
    echo ""
    if [[ "$uninstall" = "y" || "$uninstall" = "Y" ]]; then
        killall httpd
        killall mysqld
        yum -y remove httpd*
        yum -y remove mysql*
        yum -y remove php*
        rm -rf /data/www/default/phpmyadmin
        rm -f /usr/bin/lamp
        echo "Successfully uninstall LAMP!!"
    else
        echo "Uninstall cancelled, nothing to do"
    fi
}

#===============================================================================
#Description:Add apache virtualhost.
#Usage:vhost_add
#===============================================================================
function vhost_add(){
    #Define domain name
    read -p "(Please input domains such as:www.example.com):" domains
    if [ "$domains" = "" ]; then
        echo "You need input a domain."
        exit 1
    fi
    domain=`echo $domains | awk '{print $1}'`
    if [ -f "/etc/httpd/conf.d/$domain.conf" ]; then
        echo "$domain is exist!"
        exit 1
    fi
    #Create database or not    
    while true
    do
    read -p "(Do you want to create database?[y/N]):" create
    case $create in
    y|Y|YES|yes|Yes)
    read -p "(Please input the user root password of MySQL):" mysqlroot_passwd
    /usr/bin/mysql -uroot -p$mysqlroot_passwd <<EOF
exit
EOF
    if [ $? -eq 0 ]; then
        echo "MySQL root password is correct.";
    else
        echo "MySQL root password incorrect! Please check it and try again!"
        exit 1
    fi
    read -p "(Please input the database name):" dbname
    read -p "(Please set the password for mysql user $dbname):" mysqlpwd
    create=y
    break
    ;;
    n|N|no|NO|No)
    echo "Not create database, you entered $create"
    create=n
    break
    ;;
    *) echo Please input only y or n
    esac
    done

    #Create database
    if [ "$create" == "y" ];then
        /usr/bin/mysql -uroot -p$mysqlroot_passwd  <<EOF
CREATE DATABASE IF NOT EXISTS \`$dbname\`;
GRANT ALL PRIVILEGES ON \`$dbname\` . * TO '$dbname'@'localhost' IDENTIFIED BY '$mysqlpwd';
GRANT ALL PRIVILEGES ON \`$dbname\` . * TO '$dbname'@'127.0.0.1' IDENTIFIED BY '$mysqlpwd';
FLUSH PRIVILEGES;
EOF
    fi
    #Define website dir
    webdir="/data/www/$domain"
    DocumentRoot="$webdir/web"
    logsdir="$webdir/logs"
    mkdir -p $DocumentRoot $logsdir
    chown -R apache:apache $webdir
    #Create vhost configuration file
    cat >/etc/httpd/conf.d/$domain.conf<<EOF
<virtualhost *:80>
ServerName  $domain
ServerAlias  $domains 
DocumentRoot  $DocumentRoot
CustomLog $logsdir/access.log combined
DirectoryIndex index.php index.html
<Directory $DocumentRoot>
Options +Includes -Indexes
AllowOverride All
Order Deny,Allow
Allow from All
php_admin_value open_basedir $DocumentRoot:/tmp
</Directory>
</virtualhost>
EOF
    service httpd reload > /dev/null 2>&1
    echo "Successfully create $domain vhost"
    echo "######################### information about your website ############################"
    echo "The DocumentRoot:$DocumentRoot"
    echo "The Logsdir:$logsdir"
    [ "$create" == "y" ] && echo "MySQL dbname and user:$dbname and password:$mysqlpwd"
}

#===============================================================================
#Description:Remove apache virtualhost.
#Usage:vhost_del
#===============================================================================
function vhost_del(){
    read -p "(Please input a domain you want to delete):" vhost_domain
    if [ "$vhost_domain" = "" ]; then
        echo "You need input a domain."
        exit 1
    fi
    echo "---------------------------"
    echo "vhost account = $vhost_domain"
    echo "---------------------------"
    echo ""
    get_char(){
        SAVEDSTTY=`stty -g`
        stty -echo
        stty cbreak
        dd if=/dev/tty bs=1 count=1 2> /dev/null
        stty -raw
        stty echo
        stty $SAVEDSTTY
    }
    echo "Press any key to start delete vhost...or Press Ctrl+c to cancel"
    echo ""
    char=`get_char`

    if [ -f "/etc/httpd/conf.d/$vhost_domain.conf" ]; then
        rm -f /etc/httpd/conf.d/$vhost_domain.conf
        rm -rf /data/www/$vhost_domain
    else
        echo "Error:No such domain file, Please check your input domain and try again."
        exit 1
    fi

    service httpd reload > /dev/null 2>&1
    echo "Successfully delete $vhost_domain vhost"
}

#===============================================================================
#Description:List apache virtualhost.
#Usage:vhost_list
#===============================================================================
function vhost_list(){
    ls /etc/httpd/conf.d/ | grep -v "php.conf" | grep -v "none.conf" | cut -f 1,2,3 -d "."
}

#===============================================================================================
#Description:Initialization step
#Usage:none
#===============================================================================================
action=$1
[  -z $1 ] && action=install
case "$action" in
install)
    install_lamp
    ;;
uninstall)
    uninstall_lamp
    ;;
add)
   vhost_add
    ;;
del)
   vhost_del
    ;;
list)
   vhost_list
    ;;
*)
    echo "Usage: `basename $0` [install|uninstall|add|del|list]"
    ;;
esac
