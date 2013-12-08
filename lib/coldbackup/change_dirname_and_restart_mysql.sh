#!/bin/bash
/etc/init.d/mysql stop
sleep 2

cd /var/lib
mv mysql backup_mysql
mv bu_mysql mysql

sleep 2
/etc/init.d/mysql start

