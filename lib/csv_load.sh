#!/bin/bash

# ********************************************************************
#  オプションi（_INSERT_TYPE）にはLOAD INFILEの際にキーが一致した時の
#  振る舞いを指定できます。_LOAD_MODEがinsertかdiffの際に有効です。
#
#  -i ignore  : キーが一致した行はロードをスキップします
#  -i replace : キーが一致した行は既存行を置き換えます
#  指定しない : キーが一致した場合エラーが発生し、処理が中断します
#
#  参考
#  http://dev.mysql.com/doc/refman/5.1/ja/load-data.html
# ********************************************************************
while getopts "s:t:c:i:m:w:n" opts
do
  case $opts in
    s) _SCHEMA=$OPTARG ;;
    t) _TABLE=$OPTARG ;;
    c) _CSVFILE=$OPTARG ;;
    i) _INSERT_TYPE=$OPTARG ;;
    m) _LOAD_MODE=$OPTARG ;;
    w) _WHERE=$OPTARG ;;
    n) _DRYRUN="TRUE" ;;
  esac
done

if [ "$_SCHEMA" = "" ]; then
  echo "usage $0 -s [_SCHEMA] -t [_TABLE] -c [_CSVFILE] -m LOAD_MODE[insert|truncate|diff]"
  exit -1
fi

if [ "$_TABLE" = "" ]; then
  echo "usage $0 -s [_SCHEMA] -t [_TABLE] -c [_CSVFILE] -m LOAD_MODE[insert|truncate|diff]"
  exit -1
fi

if [ "$_CSVFILE" = "" ]; then
  echo "usage $0 -s [_SCHEMA] -t [_TABLE] -c [_CSVFILE] -m LOAD_MODE[insert|truncate|diff]"
  exit -1
fi

if [ "$_LOAD_MODE" = "" ]; then
  echo "usage $0 -s [_SCHEMA] -t [_TABLE] -c [_CSVFILE] -m LOAD_MODE[insert|truncate|diff]"
  exit -1
fi

# ********************************************************************
#  setting
# ********************************************************************
. ../lib/exec_sql.sh develop

# ********************************************************************
#  load sql
# ********************************************************************
_QUERY=`cat <<EOS
USE ${_SCHEMA};

LOAD DATA INFILE '${_CSVFILE}' ${_INSERT_TYPE}
INTO TABLE ${_TABLE}
FIELDS TERMINATED BY ','
ENCLOSED BY '"';
EOS`

# ********************************************************************
#  function
# ********************************************************************
truncate_table() {
  if [ "$1" = "-n" ]; then
    execute -s "USE ${_SCHEMA}; TRUNCATE TABLE ${_TABLE};" -n
  else
    echo "USE ${_SCHEMA}; TRUNCATE TABLE ${_TABLE};"
    execute -s "USE ${_SCHEMA}; TRUNCATE TABLE ${_TABLE};"
  fi
}

delete_table() {
  if [ "$1" = "-n" ]; then
    execute -s "USE ${_SCHEMA}; DELETE FROM ${_TABLE} WHERE ${_WHERE};" -n
  else
    echo "USE ${_SCHEMA}; DELETE FROM ${_TABLE} WHERE ${_WHERE};"
    execute -s "USE ${_SCHEMA}; DELETE FROM ${_TABLE} WHERE ${_WHERE};"
  fi
}

# ********************************************************************
#  main
# ********************************************************************
if [ "$_DRYRUN" = "TRUE" ]; then
  echo "*********** dry run ************"
  if [ "$_LOAD_MODE" == "truncate" ]; then
    truncate_table -n
  fi

  if [ "$_LOAD_MODE" = "diff" ]; then
    delete_table -n
  fi

  execute -s "${_QUERY}" -n
  echo "*********** dry run ************"
else
  echo "********** load start **********"
  # truncate table
  if [ "$_LOAD_MODE" = "truncate" ]; then
    truncate_table

    if [ $? -ne 0 ]; then
      echo "*** truncate error *** ${_SCHEMA}.${_TABLE} $0"
      exit 1
    fi
  fi
  
  # delete table
  if [ "$_LOAD_MODE" = "diff" ]; then
    delete_table

    if [ $? -ne 0 ]; then
      echo "*** delete error *** ${_SCHEMA}.${_TABLE} $0"
      exit 1
    fi
  fi

  echo "${_QUERY}"

  # csv load
  execute -s "${_QUERY}"

  if [ $? -ne 0 ]; then
    echo "*** load error *** ${_SCHEMA}.${_TABLE} $0"
    exit 1
  fi

  echo "********** load end ***********"
  echo ""
fi

exit  0

