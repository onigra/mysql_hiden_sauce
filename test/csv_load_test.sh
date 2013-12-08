#!/usr/local/bin/bash

oneTimeSetUp() {
  # setup
  schema="test"
  table="sequences"
  root_path=`echo $(cd .. $(dirname $0); pwd)`
  . ${root_path}/lib/exec_sql.sh develop

  # create test table
  execute_sql -s ${root_path}/test/ddl/test_table.sql
}

oneTimeTearDown() {
  execute -s "drop database ${schema};"
}

## test code 
testReplaceLoad() {
  ${root_path}/lib/csv_load.sh -s ${schema} -t ${table} -c ${root_path}/test/data/${schema}.${table}.truncate.csv -m truncate
  val=`execute -s "use test; select count(*) from sequences;"`

  assertEquals 4 ${val}
}

testInsertLoad() {
  ${root_path}/lib/csv_load.sh -s ${schema} -t ${table} -c ${root_path}/test/data/${schema}.${table}.insert.csv -m insert
  val=`execute -s "select count(*) from test.sequences;"`

  assertEquals 8 ${val}
}

testDiffLoad() {
  ${root_path}/lib/csv_load.sh -s ${schema} -t ${table} -c ${root_path}/test/data/${schema}.${table}.diff.csv -m diff -w 'id >= 3'
  val=`execute -s "select count(*) from test.sequences;"`

  assertEquals 6 ${val}
}

testInsertError() {
  ${root_path}/lib/csv_load.sh -s ${schema} -t ${table} -c ${root_path}/test/data/${schema}.${table}.truncate.csv -m insert

  assertFalse $?
}

testInsertIgnore() {
  ${root_path}/lib/csv_load.sh -s ${schema} -t ${table} -c ${root_path}/test/data/${schema}.${table}.ignore.csv -m insert -i ignore
  val=`execute -s "select count(*) from test.sequences;"`

  assertEquals 7 ${val}
}

testInsertReplace() {
  ${root_path}/lib/csv_load.sh -s ${schema} -t ${table} -c ${root_path}/test/data/${schema}.${table}.replace.csv -m insert -i replace
  val=`execute -s "select name from test.sequences where id = 7;"`

  assertEquals "777" ${val}
}

testTruncateDryrun() {
  message=`${root_path}/lib/csv_load.sh -s ${schema} -t ${table} -c ${root_path}/test/data/${schema}.${table}.truncate.csv -m truncate -n`

  # insert type を指定しない場合、load data infileの後に半角スペースが一つ入るので注意
  assert="*********** dry run ************
mysql --defaults-file=<( printf '[client]\npassword=%s\n' [DBPASS] ) -N -u develop -e\"USE test; TRUNCATE TABLE sequences;\"
mysql --defaults-file=<( printf '[client]\npassword=%s\n' [DBPASS] ) -N -u develop -e\"USE test;

LOAD DATA INFILE '${root_path}/test/data/test.sequences.truncate.csv' 
INTO TABLE sequences
FIELDS TERMINATED BY ','
ENCLOSED BY '\"';\"
*********** dry run ************"

  assertEquals "${assert}" "${message}"
}

# load shunit2
. ./shunit2-2.1.6/src/shunit2

