#!/bin/bash

###
# setup
#
_DBUSER=$1
_HOSTNAME=`hostname -s`
_APP_ROOT="/usr/local/lib/mysql_hiden_sauce"
. $_APP_ROOT/lib/login.sh
_DBPASS=`get_password $_HOSTNAME $_DBUSER`

# -------------------------------------------------------
#  外部ファイルに置いてるsqlを実行する
#  サイレントモードにしてるのはテストしやすくするため
# -------------------------------------------------------
execute_sql() {
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
    echo "mysql --defaults-file=<( printf '[client]\npassword=%s\n' [DBPASS] ) -N -u ${_DBUSER} < ${_SQL}"
  else
    mysql --defaults-file=<( printf '[client]\npassword=%s\n' ${_DBPASS} ) -N -u ${_DBUSER} < ${_SQL}
  fi
}

# -------------------------------------------------------
#  SQLを変数で渡すとコマンドラインから実行する
#  検索条件を動的に指定したい時に使う
#  SQLの引数はダブルクォートで囲まないときちんと動作しないので注意
#  例: execute_variable -s "${_SQL}"
# -------------------------------------------------------
execute() {
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
    echo "mysql --defaults-file=<( printf '[client]\npassword=%s\n' [DBPASS] ) -N -u ${_DBUSER} -e\"${_SQL}\""
  else
    mysql --defaults-file=<( printf '[client]\npassword=%s\n' ${_DBPASS} ) -N -u ${_DBUSER} -e"${_SQL}"
  fi
}

execute_normal() {
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
    echo "mysql --defaults-file=<( printf '[client]\npassword=%s\n' [DBPASS] ) -u ${_DBUSER} -e\"${_SQL}\""
  else
    mysql --defaults-file=<( printf '[client]\npassword=%s\n' ${_DBPASS} ) -u ${_DBUSER} -e"${_SQL}"
  fi
}

