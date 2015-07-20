#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#===============================================================================================
#   System Required:  CentOS / RedHat / Fedora
#   Description:  Yum Install LAMP(Linux + Apache + MySQL/MariaDB + PHP )
#   Author: Teddysun <i@teddysun.com>
#   Intro:  http://teddysun.com/lamp-yum
#           https://github.com/teddysun/lamp-yum
#===============================================================================================

clear
echo ""
echo "#############################################################"
echo "# LAMP Auto yum Install Script for CentOS / RedHat / Fedora #"
echo "# Intro: http://teddysun.com/lamp-yum                       #"
echo "# Author: Teddysun <i@teddysun.com>                         #"
echo "#############################################################"
echo ""

# Get public IP
function getIP(){
    IP=`ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\." | head -n 1`
    if [[ "$IP" = "" ]]; then
        IP=`curl -s -4 icanhazip.com`
    fi
}

# Current folder
cur_dir=`pwd`

# Install LAMP Script
function install_lamp(){
    rootness
    disable_selinux
    pre_installation_settings
    install_apache
    install_database
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
    echo "MySQL root password:$dbrootpwd"
    echo ""
    echo "Welcome to visit:http://teddysun.com/lamp-yum"
    echo "Enjoy it! "
    echo ""
}

# Make sure only root can run our script
function rootness(){
if [[ $EUID -ne 0 ]]; then
   echo "Error:This script must be run as root!" 1>&2
   exit 1
fi
}

# Disable selinux
function disable_selinux(){
if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
fi
}

# Pre-installation settings
function pre_installation_settings(){
    # Install Atomic repository
    wget -q -O - http://www.atomicorp.com/installers/atomic | sh
    if [ $? -ne 0 ]; then
        echo "Error:Atomic repository must be installed!"
        exit 1
    fi
    # Update Atomic repository
    yum -y update atomic-release
    # Display Public IP
    echo "Getting Public IP address..."
    getIP
    echo -e "Your main public IP is\t\033[32m$IP\033[0m"
    echo ""
    # Choose databese
    while true
    do
    echo "Please choose a version of the Database:"
    echo -e "\t\033[32m1\033[0m. Install MySQL-5.5(recommend)"
    echo -e "\t\033[32m2\033[0m. Install MariaDB-5.5"
    read -p "Please input a number:(Default 1) " DB_version
    [ -z "$DB_version" ] && DB_version=1
    case $DB_version in
        1|2)
        echo ""
        echo "---------------------------"
        echo "You choose = $DB_version"
        echo "---------------------------"
        echo ""
        break
        ;;
        *)
        echo "Input error! Please only input number 1,2"
    esac
    done
    # Set MySQL root password
    echo "Please input the root password of MySQL or MariaDB:"
    read -p "(Default password: root):" dbrootpwd
    if [ -z $dbrootpwd ]; then
        dbrootpwd="root"
    fi
    echo ""
    echo "---------------------------"
    echo "Password = $dbrootpwd"
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
    echo ""
    echo "Press any key to start...or Press Ctrl+C to cancel"
    char=`get_char`
    # Remove Packages
    yum -y remove httpd*
    yum -y remove mysql*
    yum -y remove mariadb*
    yum -y remove php*
    # Set timezone
    rm -f /etc/localtime
    ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    yum -y install ntp
    ntpdate -d cn.pool.ntp.org
}

# Install Apache
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
    cp -f $cur_dir/conf/jquery.js /data/www/default/jquery.js
    cp -f $cur_dir/conf/phpinfo.php /data/www/default/phpinfo.php
    echo "Apache Install completed!"
}

# Install database
function install_database(){
    if [ $DB_version -eq 1 ]; then
        install_mysql
    elif [ $DB_version -eq 2 ]; then
        install_mariadb
    fi
}

# Install MariaDB
function install_mariadb(){
    # Install MariaDB
    echo "Start Installing MariaDB..."
    yum -y install mariadb mariadb-server
    cp -f $cur_dir/conf/my.cnf /etc/my.cnf
    chkconfig mysqld on
    # Start mysqld service
    service mysqld start
    /usr/bin/mysqladmin password $dbrootpwd
    /usr/bin/mysql -uroot -p$dbrootpwd <<EOF
drop database if exists test;
delete from mysql.user where user='';
update mysql.user set password=password('$dbrootpwd') where user='root';
delete from mysql.user where not (user='root') ;
flush privileges;
exit
EOF
    echo "MariaDB Install completed!"
}

# Install MySQL
function install_mysql(){
    # Install MySQL
    echo "Start Installing MySQL..."
    yum -y install mysql mysql-server
    cp -f $cur_dir/conf/my.cnf /etc/my.cnf
    chkconfig mysqld on
    # Start mysqld service
    service mysqld start
    /usr/bin/mysqladmin password $dbrootpwd
    /usr/bin/mysql -uroot -p$dbrootpwd <<EOF
drop database if exists test;
delete from mysql.user where user='';
update mysql.user set password=password('$dbrootpwd') where user='root';
delete from mysql.user where not (user='root') ;
flush privileges;
exit
EOF
    echo "MySQL Install completed!"
}

# Install php5.4
function install_php(){
    #install PHP
    echo "Start Installing PHP..."
    yum -y install libjpeg-devel libpng-devel elinks
    yum -y install php php-devel php-cli php-pdo php-mysqlnd php-mcrypt php-mbstring php-xml php-xmlrpc php-common
    yum -y install php-gd php-bcmath php-imap php-odbc php-ldap php-mhash php-intl
    yum -y install php-xcache php-ioncube-loader php-zend-guard-loader php-snmp php-soap php-tidy
    cp -f $cur_dir/conf/php.ini /etc/php.ini
    echo "PHP install completed!"
}
# Install phpmyadmin.
function install_phpmyadmin(){
    if [ ! -d /data/www/default/phpmyadmin ];then
        echo "Start Installing phpMyAdmin..."
        LATEST_PMA=$(curl -s https://www.phpmyadmin.net/files/ | awk -F\> '/\/files\//{print $3}' | cut -d'<' -f1 | sort -V | tail -1)
        if [ -z $LATEST_PMA ]; then
            LATEST_PMA=$(curl -s http://lamp.teddysun.com/pmalist.txt | tail -1 | awk -F- '{print $2}')
        fi
        echo -e "Installing phpmyadmin version: \033[41;37m $LATEST_PMA \033[0m"
        cd $cur_dir
        if [ -s phpMyAdmin-${LATEST_PMA}-all-languages.tar.gz ]; then
            echo "phpMyAdmin-${LATEST_PMA}-all-languages.tar.gz [found]"
        else
            wget -c http://files.phpmyadmin.net/phpMyAdmin/${LATEST_PMA}/phpMyAdmin-${LATEST_PMA}-all-languages.tar.gz
            tar zxf phpMyAdmin-${LATEST_PMA}-all-languages.tar.gz
        fi
        mv phpMyAdmin-${LATEST_PMA}-all-languages /data/www/default/phpmyadmin
        cp -f $cur_dir/conf/config.inc.php /data/www/default/phpmyadmin/config.inc.php
        #Create phpmyadmin database
        /usr/bin/mysql -uroot -p$dbrootpwd < /data/www/default/phpmyadmin/sql/create_tables.sql
        mkdir -p /data/www/default/phpmyadmin/upload/
        mkdir -p /data/www/default/phpmyadmin/save/
        cp -f /data/www/default/phpmyadmin/sql/create_tables.sql /data/www/default/phpmyadmin/upload/
        chown -R apache:apache /data/www/default/phpmyadmin
        rm -f phpMyAdmin-${LATEST_PMA}-all-languages.tar.gz
        echo "PHPMyAdmin Install completed!"
    else
        echo "PHPMyAdmin had been installed!"
    fi
    #Start httpd service
    service httpd start
}

# Uninstall lamp
function uninstall_lamp(){
    echo "Warning! All of your data will be deleted..."
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
        cd ~
        CHECK_MARIADB=$(mysql -V | grep -i 'MariaDB')
        service httpd stop
        service mysqld stop
        yum -y remove httpd*
        if [ -z $CHECK_MARIADB ]; then
            yum -y remove mysql*
        else
            yum -y remove mariadb*
        fi
        yum -y remove php*
        rm -rf /data/www/default/phpmyadmin
        rm -rf /etc/httpd
        rm -f /usr/bin/lamp
        rm -f /etc/my.cnf.rpmsave
        rm -f /etc/php.ini.rpmsave
        echo "Successfully uninstall LAMP!!"
    else
        echo ""
        echo "Uninstall cancelled, nothing to do..."
        echo ""
    fi
}

# Add apache virtualhost
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
    read -p "(Please input the user root password of MySQL or MariaDB):" mysqlroot_passwd
    /usr/bin/mysql -uroot -p$mysqlroot_passwd <<EOF
exit
EOF
    if [ $? -eq 0 ]; then
        echo "MySQL or MariaDB root password is correct.";
    else
        echo "MySQL or MariaDB root password incorrect! Please check it and try again!"
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
    service httpd restart > /dev/null 2>&1
    echo "Successfully create $domain vhost"
    echo "######################### information about your website ############################"
    echo "The DocumentRoot:$DocumentRoot"
    echo "The Logsdir:$logsdir"
    [ "$create" == "y" ] && echo "database name and user:$dbname and password:$mysqlpwd"
}

# Remove apache virtualhost
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

# List apache virtualhost
function vhost_list(){
    ls /etc/httpd/conf.d/ | grep -v "php.conf" | grep -v "none.conf" | grep -v "welcome.conf" | grep -iv "README" | awk -F".conf" '{print $1}'
}

# Initialization step
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
