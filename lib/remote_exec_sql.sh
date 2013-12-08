#!/bin/bash

###
# setup
#
_HOSTNAME=$1
_DBUSER=$2
_APP_ROOT="/usr/local/lib/mysql_hiden_sauce"
. $_APP_ROOT/lib/login.sh
_DBPASS=`get_password $_HOSTNAME $_DBUSER`

# -------------------------------------------------------
#  外部ファイルに置いてるsqlを実行する
#  サイレントモードにしてるのはテストしやすくするため
# -------------------------------------------------------
remote_execute_sql() {
  _DRYRUN=""
  OPTIND_OLD=$OPTIND
  OPTIND=1
  while getopts "s:n" opts
  do
    case $opts in
      s) _SQL=$OPTARG ;;
      n) _DRYRUN="TRUE" ;;
    esac
  done

  if [ "$_DRYRUN" = "TRUE" ]; then
    echo "mysql --defaults-file=<( printf '[client]\npassword=%s\n' [DBPASS] ) -N -h ${_HOSTNAME} -u ${_DBUSER} < ${_SQL}"
  else
    mysql --defaults-file=<( printf '[client]\npassword=%s\n' ${_DBPASS} ) -N -h ${_HOSTNAME} -u ${_DBUSER} < ${_SQL}
  fi
}

# -------------------------------------------------------
#  SQLを変数で渡すとコマンドラインから実行する
#  検索条件を動的に指定したい時に使う
#  SQLの引数はダブルクォートで囲まないときちんと動作しないので注意
#  例: remote_execute_variable -s "${_SQL}"
# -------------------------------------------------------
remote_execute() {
  _DRYRUN=""
  OPTIND_OLD=$OPTIND
  OPTIND=1
  while getopts "s:n" opts
  do
    case $opts in
      s) _SQL=$OPTARG ;;
      n) _DRYRUN="TRUE" ;;
    esac
  done

  if [ "$_DRYRUN" = "TRUE" ]; then
    echo "mysql --defaults-file=<( printf '[client]\npassword=%s\n' [DBPASS] ) -N -h ${_HOSTNAME} -u ${_DBUSER} -e\"${_SQL}\""
  else
    mysql --defaults-file=<( printf '[client]\npassword=%s\n' ${_DBPASS} ) -N -h ${_HOSTNAME} -u ${_DBUSER} -e"${_SQL}"
  fi
}

remote_execute_normal() {
  _DRYRUN=""
  OPTIND_OLD=$OPTIND
  OPTIND=1
  while getopts "s:n" opts
  do
    case $opts in
      s) _SQL=$OPTARG ;;
      n) _DRYRUN="TRUE" ;;
    esac
  done

  if [ "$_DRYRUN" = "TRUE" ]; then
    echo "mysql --defaults-file=<( printf '[client]\npassword=%s\n' [DBPASS] ) -h ${_HOSTNAME} -u ${_DBUSER} -e\"${_SQL}\""
  else
    mysql --defaults-file=<( printf '[client]\npassword=%s\n' ${_DBPASS} ) -h ${_HOSTNAME} -u ${_DBUSER} -e"${_SQL}"
  fi
}

