#!/bin/bash

/etc/init.d/mysql stop
sleep 2

cd /var/lib
rm -rf bu_mysql

cp -rap /var/lib/mysql /var/lib/bu_mysql

sleep 2
/etc/init.d/mysql start

