#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#===============================================================================================
#   System Required:  CentOS / RedHat / Fedora
#   Description:  Auto Update Script for phpMyAdmin
#   Author: Teddysun <i@teddysun.com>
#   Intro:  http://teddysun.com/lamp
#===============================================================================================
if [[ $EUID -ne 0 ]]; then
   echo "Error:This script must be run as root!" 1>&2
   exit 1
fi
cur_dir=`pwd`

clear
echo "#############################################################"
echo "# Auto Update Script for phpMyAdmin"
echo "# System Required:  CentOS / RedHat / Fedora"
echo "# Intro: http://teddysun.com/lamp"
echo ""
echo "# Author: Teddysun <i@teddysun.com>"
echo ""
echo "#############################################################"
echo ""

# Description:phpMyAdmin Update
if [ -d /data/www/default/phpmyadmin ]; then
    INSTALLED_PMA=$(awk '/Version/{print $2}' /data/www/default/phpmyadmin/README)
else
    if [ -s "$cur_dir/pmaversion.txt" ]; then
        INSTALLED_PMA=$(awk '/phpmyadmin/{print $2}' $cur_dir/pmaversion.txt)
    else
        echo -e "phpmyadmin\t0" > $cur_dir/pmaversion.txt
        INSTALLED_PMA=$(awk '/phpmyadmin/{print $2}' $cur_dir/pmaversion.txt)
    fi
fi

LATEST_PMA=$(elinks http://iweb.dl.sourceforge.net/project/phpmyadmin/phpMyAdmin/ | awk -F/ '{print $7F}' | grep -iv '-' | grep -iv 'rst' | tail -1)
echo -e "Latest version of phpmyadmin: \033[41;37m $LATEST_PMA \033[0m"
echo -e "Installed version of phpmyadmin: \033[41;37m $INSTALLED_PMA \033[0m"
echo ""
echo "Do you want to upgrade phpmyadmin ? (y/n)"
read -p "(Default: n):" UPGRADE_PMA
if [ -z $UPGRADE_PMA ]; then
    UPGRADE_PMA="n"
fi
echo "---------------------------"
echo "You choose = $UPGRADE_PMA"
echo "---------------------------"
echo ""
get_char() {
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

# Download && Untar files
function untar(){
    local TARBALL_TYPE
    if [ -n $1 ]; then
        SOFTWARE_NAME=`echo $1 | awk -F/ '{print $NF}'`
        TARBALL_TYPE=`echo $1 | awk -F. '{print $NF}'`
        wget -c -t3 -T3 $1 -P $cur_dir/
        if [ $? -ne 0 ];then
            rm -rf $cur_dir/$SOFTWARE_NAME
            wget -c -t3 -T60 $2 -P $cur_dir/
            SOFTWARE_NAME=`echo $2 | awk -F/ '{print $NF}'`
            TARBALL_TYPE=`echo $2 | awk -F. '{print $NF}'`
        fi
    else
        SOFTWARE_NAME=`echo $2 | awk -F/ '{print $NF}'`
        TARBALL_TYPE=`echo $2 | awk -F. '{print $NF}'`
        wget -c -t3 -T3 $2 -P $cur_dir/ || exit
    fi
    EXTRACTED_DIR=`tar tf $cur_dir/$SOFTWARE_NAME | tail -n 1 | awk -F/ '{print $1}'`
    case $TARBALL_TYPE in
        gz|tgz)
            tar zxf $cur_dir/$SOFTWARE_NAME -C $cur_dir/ && cd $cur_dir/$EXTRACTED_DIR || return 1
        ;;
        bz2|tbz)
            tar jxf $cur_dir/$SOFTWARE_NAME -C $cur_dir/ && cd $cur_dir/$EXTRACTED_DIR || return 1
        ;;
        xz)
            tar Jxf $cur_dir/$SOFTWARE_NAME -C $cur_dir/ && cd $cur_dir/$EXTRACTED_DIR || return 1
        ;;
        tar|Z)
            tar xf $cur_dir/$SOFTWARE_NAME -C $cur_dir/ && cd $cur_dir/$EXTRACTED_DIR || return 1
        ;;
        *)
        echo "$SOFTWARE_NAME is wrong tarball type ! "
    esac
}

# phpMyAdmin Update
if [[ "$UPGRADE_PMA" = "y" || "$UPGRADE_PMA" = "Y" ]];then
    echo "===================== phpMyAdmin upgrade start===================="
    if [ -d /data/www/default/phpmyadmin ]; then
        mv /data/www/default/phpmyadmin/config.inc.php $cur_dir/config.inc.php
        rm -rf /data/www/default/phpmyadmin
    else
        echo "===================== phpMyAdmin folder not found! ===================="
    fi
    if [ ! -s phpMyAdmin-$LATEST_PMA-all-languages.tar.gz ]; then
        LATEST_PMA_LINK="http://iweb.dl.sourceforge.net/project/phpmyadmin/phpMyAdmin/${LATEST_PMA}/phpMyAdmin-${LATEST_PMA}-all-languages.tar.gz"
        BACKUP_PMA_LINK="http://lamp.teddysun.com/files/phpMyAdmin-${LATEST_PMA}-all-languages.tar.gz"
        untar $LATEST_PMA_LINK $BACKUP_PMA_LINK
        mkdir -p /data/www/default/phpmyadmin
        mv * /data/www/default/phpmyadmin
    else
        tar -zxf phpMyAdmin-$LATEST_PMA-all-languages.tar.gz -C $cur_dir
        mv $cur_dir/phpMyAdmin-$LATEST_PMA-all-languages /data/www/default/phpmyadmin
    fi
    if [ -s $cur_dir/config.inc.php ]; then
        mv $cur_dir/config.inc.php /data/www/default/phpmyadmin/config.inc.php
    else
        mv /data/www/default/phpmyadmin/config.sample.inc.php /data/www/default/phpmyadmin/config.inc.php
    fi
    mkdir -p /data/www/default/phpmyadmin/upload/
    mkdir -p /data/www/default/phpmyadmin/save/
    cp -f /data/www/default/phpmyadmin/examples/create_tables.sql /data/www/default/phpmyadmin/upload/
    chown -R apache:apache /data/www/default/phpmyadmin
    # clean phpMyAdmin archive
    cd $cur_dir
    rm -rf $cur_dir/pmaversion.txt
    echo -e "phpmyadmin\t${LATEST_PMA}" > $cur_dir/pmaversion.txt
    rm -rf $cur_dir/phpMyAdmin-$LATEST_PMA-all-languages
    # Reload httpd service
    service httpd restart
    echo "===================== phpMyAdmin update completed! ===================="
else
    echo "phpMyAdmin upgrade cancelled, nothing to do..."
    echo ""
fi
