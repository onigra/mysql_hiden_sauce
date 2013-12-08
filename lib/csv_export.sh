#!/bin/bash
while getopts "s:t:c:w:n" opts
do
  case $opts in
    s) _SCHEMA=$OPTARG ;;
    t) _TABLE=$OPTARG ;;
    c) _CSVPATH=$OPTARG ;;
    w) _WHERE=$OPTARG ;;
    n) _DRYRUN="TRUE" ;;
  esac
done

if [ "$_SCHEMA" == "" ]; then
  echo "usage $0 -s [_SCHEMA] -t [_TABLE] -c [_CSVPATH] -w [_WHERE]"
  exit -1
fi

if [ "$_TABLE" == "" ]; then
  echo "usage $0 -s [_SCHEMA] -t [_TABLE] -c [_CSVPATH] -w [_WHERE]"
  exit -1
fi

if [ "$_CSVPATH" == "" ]; then
  echo "usage $0 -s [_SCHEMA] -t [_TABLE] -c [_CSVPATH] -w [_WHERE]"
  exit -1
fi

if [ "$_WHERE" == "" ]; then
  _WHERE=""
else
  _WHERE=" WHERE $_WHERE"
fi

# ********************************************************************
#  export sql
#
#  set sql_modeの記述は一見無駄に見えるが
#  基幹DBのみNO_BACKSLASH_ESCAPESを設定していないため、
#  基幹に合わせてexport/loadの設定を変更する必要を無くすために行っている
# ********************************************************************
_SQL=`cat <<EOS
SET sql_log_bin=OFF;
SET sql_mode='IGNORE_SPACE,PIPES_AS_CONCAT,NO_BACKSLASH_ESCAPES' ;

SELECT *
INTO OUTFILE '${_CSVPATH}/${_SCHEMA}.${_TABLE}.csv'
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '\\'
FROM ${_SCHEMA}.${_TABLE}
${_WHERE};
`

# ********************************************************************
#  main
# ********************************************************************
. ../lib/login.sh

_HOSTNAME=`hostname -s`
_DBUSER=develop
_DBPASSWD=`get_password ${_HOSTNAME} ${_DBUSER}`

if [ "$_DRYRUN" == "TRUE" ]; then
  echo "*********** dry run ************"
  echo "mysql -u ${_DBUSER} -p${_DBPASSWD} -e\"${_SQL}\""
  echo "*********** dry run ************"
else
  rm -f ${_CSVPATH}/${_SCHEMA}.${_TABLE}.csv

  echo "********* export start *********"
  echo "${_SQL}"

  mysql -u ${_DBUSER} -p${_DBPASSWD} -e"${_SQL}"

  echo "export to: ${_CSVPATH}/${_SCHEMA}.${_TABLE}.csv "
  echo "********* export end ***********"
  echo ""
fi

exit 0

