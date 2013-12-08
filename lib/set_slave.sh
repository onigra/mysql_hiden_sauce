#!/bin/bash
# ------------------------------------------
# slaveからmasterのログポジションを取得し、
# レプリケーションの設定を行うスクリプト
# slaveから実行することを想定しています
# ------------------------------------------
while getopts "i:h:u:n" opts
do
  case $opts in
    i) _MASTER_IP=$OPTARG ;;
    h) _MASTER_HOSTNAME=$OPTARG ;;
    u) _MASTER_USER=$OPTARG ;;
    n) _DRYRUN="TRUE" ;;
  esac
done

###
# setup
#
_APP_ROOT=`echo $(cd .. $(dirname $0); pwd)`
. $_APP_ROOT/lib/login.sh

_USER="develop"
. $_APP_ROOT/lib/exec_sql.sh $_USER
. $_APP_ROOT/lib/remote_exec_sql.sh $_MASTER_HOSTNAME $_USER

###
# masterのhostのログファイルとポジションをとってくる関数
#
get_master_info() {
  # File or Pos
  _INFO_TYPE=$1
  if [ "$_INFO_TYPE" = "File" ]; then
    echo $(remote_execute -s 'show master status;' | grep -i mysql-bin | echo `awk '{print $1}'`)
  elif [ "$_INFO_TYPE" = "Pos" ]; then
    echo $(remote_execute -s 'show master status;' | grep -i mysql-bin | echo `awk '{print $2}'`)
  else
    :
  fi
}

###
# slave設定の取得。取得できなければ中断
#
_MASTER_PASS=`get_password ${_MASTER_HOSTNAME} ${_MASTER_USER}`
_MASTER_LOG_FILE=`get_master_info File`
_MASTER_LOG_POS=`get_master_info Pos`

echo $_MASTER_LOG_FILE
echo $_MASTER_LOG_POS

if [ "$_MASTER_LOG_FILE" = "" ]; then
  echo "error: Coudn't get master log file"
  exit 1
fi

if [ "$_MASTER_LOG_POS" = "" ]; then
  echo "error: Coudn't get master log position"
  exit 1
fi

###
# SQL作成
#
sql=`cat << _EOT_
stop slave;
reset slave;
 
CHANGE MASTER TO 
  MASTER_HOST='${_MASTER_IP}', 
  MASTER_USER='${_MASTER_USER}', 
  MASTER_PASSWORD='${_MASTER_PASS}',
  MASTER_LOG_FILE='${_MASTER_LOG_FILE}', 
  MASTER_LOG_POS=${_MASTER_LOG_POS}
;

start slave;
show slave status\G
_EOT_`

###
# main
#
if [ "$_DRYRUN" = "TRUE" ]; then
  echo "============dry run============"
  echo "${sql}"
  echo "============dry run============"
else
  echo "============execute============"
  echo "${sql}"
  echo "============execute============"

  execute_normal -s "${sql}"
fi

exit 0

