#!/bin/bash

# -------------------------------------------------------------
#  $1: レプリケーション先のスキーマ名
#  $2: レプリケーション元のスキーマ名
#  $3: レプリケーション元のIP
#
#  ./table_count_check.sh wodndtlive wsales 192.168.40.241
# -------------------------------------------------------------
# 引数チェック
_SCHEMA_NAME=$1
_DIFF_SCHEMA_NAME=$2
_DIFF_IP=$3

if [ $# -ne 3 ]; then
  echo "引数は必ず3つ指定してください"
  exit 1
fi

# DBパスワード取得
. /usr/local/shell/include/mysql_common_functions.sh
_HOSTNAME=`hostname -s`
_DBUSER=sysadm
_DBPASSWD=`get_password ${_HOSTNAME} ${_DBUSER}`

_TABLE_LIST=`mysql -u ${_DBUSER} -p${_DBPASSWD} -s -N -e "select table_name from information_schema.tables where table_schema = '${_SCHEMA_NAME}'"`
_LIST_ARRAY=(${_TABLE_LIST})

for item in ${_LIST_ARRAY[@]}
do
  local_count=`mysql -u ${_DBUSER} -p${_DBPASSWD} -s -N -e "select count(*) from ${_SCHEMA_NAME}.${item}"`
  diff_count=`mysql -h ${_DIFF_IP} -u ${_DBUSER} -p${_DBPASSWD} -s -N -e "select count(*) from ${_DIFF_SCHEMA_NAME}.${item}"`

  test $local_count -eq $diff_count ; echo $? ${item} $local_count $diff_count
  i=`expr $i + 1`
done

exit 0

