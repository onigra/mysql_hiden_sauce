#!/usr/local/bin/bash

oneTimeSetUp() {
  # setup
  schema="test"
  table="sequences"
  root_path=`echo $(cd .. $(dirname $0); pwd)`
  . ${root_path}/lib/exec_sql.sh develop
  . ${root_path}/lib/remote_exec_sql.sh 192.168.50.99 develop

  # create master db
  execute_sql -s ${root_path}/test/ddl/test_table.sql
  execute_sql -s ${root_path}/test/data/test.members.sql

  # create slave db
  remote_execute_sql -s ${root_path}/test/ddl/test_table.sql
  remote_execute_sql -s ${root_path}/test/data/test.members.sql
}

oneTimeTearDown() {
  execute -s "stop slave; reset slave;"
  execute -s "drop database ${schema};"
  remote_execute -s "drop database ${schema};"
}

testSetSlave() {
  ${root_path}/lib/set_slave.sh -i 192.168.50.99 -h 192.168.50.99 -u develop

  assertEquals 0 $?
}

testReplication() {
  remote_execute_sql -s ${root_path}/test/data/test.add_members.sql
  master=`remote_execute -s "select count(*) from test.members;"`

  sleep 1
  slave=`execute -s "select count(*) from test.members;"`

  assertEquals ${master} ${slave}
}

. ./shunit2-2.1.6/src/shunit2

