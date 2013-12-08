#!/bin/bash

DRYRUN=""
OPTIND_OLD=$OPTIND
OPTIND=1
while getopts "n" opts
do
  case $opts in
    n) DRYRUN="TRUE" ;;
  esac
done

###
# setting
#
_APP_ROOT=`echo $(cd ../../.. $(dirname $0); pwd)`
. $_APP_ROOT/lib/job_framework/remote_export.sh 192.168.50.99 develop

_SCRIPT_PATH=`echo $(cd $(dirname $0); pwd)`
sql_files=(`ls -dF $_SCRIPT_PATH/sql/*`)

###
# main
#
if [ "$DRYRUN" = "TRUE" ]; then
  remote_remove_exported_files -t example_table -j members -n

  for (( i = 0; i < ${#sql_files[@]}; i++ ))
  do
    remote_execute_sql -s ${sql_files[$i]} -n
  done

  remote_split_big_file  -t example_table -j members -l 5 -b 50 -n
  remote_transport_csv_files -t example_table -j members -n
else
  remote_remove_exported_files -t example_table -j members

  for (( i = 0; i < ${#sql_files[@]}; i++ ))
  do
    remote_execute_sql -s ${sql_files[$i]}
  done

  remote_split_big_file  -t example_table -j members -l 5 -b 50
  remote_transport_csv_files -t example_table -j members
fi

