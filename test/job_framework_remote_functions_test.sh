#!/bin/bash

oneTimeSetUp() {
  # setup
  root_path=`echo $(cd .. $(dirname $0); pwd)`
  . ${root_path}/lib/job_framework/remote_export.sh 192.168.50.99 develop

  # create test table
  remote_execute_sql -s ${root_path}/test/ddl/test_table.sql

  # create test data
  p="${root_path}/batch_example/data/example_table"
  ssh 192.168.50.99 "touch ${p}/test_data1.csv"
  ssh 192.168.50.99 "touch ${p}/test_data2.csv"
  ssh 192.168.50.99 "touch ${p}/test_data3.csv"

  for i in {1..11};
  do
    echo "hoge" >> ${p}/test_data1.csv
    echo "hoge" >> ${p}/test_data2.csv
  done
}

oneTimeTearDown() {
  remote_execute -s "drop database test;"
  rm -f ${p}/test_data*
  ssh 192.168.50.99 "rm -f ${p}/test_data*"
}

testGetPath() {
  target=`remote_get_path example_table`
  assertEquals "${root_path}/batch_example/data/example_table" "$target"
}

testGetCsvFileNames() {
  files=(`remote_get_csv_file_names -t example_table -j test_data`)
  asserts=("test_data1.csv" "test_data2.csv" "test_data3.csv")

  for (( i = 0; i < ${#files[@]}; i++ ))
  do
    assertEquals ${asserts[$i]} ${files[$i]}
  done
}

testSplitBigFile(){
  remote_split_big_file  -t example_table -j test_data -l 5 -b 50

  files=(`ls ${p} | grep splited.test_data`)
  asserts=(
    "splited.test_data1.csv.aa"
    "splited.test_data1.csv.ab"
    "splited.test_data1.csv.ac"
    "splited.test_data2.csv.aa"
    "splited.test_data2.csv.ab"
    "splited.test_data2.csv.ac"
  )

  for (( i = 0; i < ${#files[@]}; i++ ))
  do
    assertEquals ${asserts[$i]} ${files[$i]}
  done
}

# ローカルに対して転送してるので、ちゃんとテストになってなくて微妙
testTransportSplitedCsvFiles() {
  remote_transport_csv_files -t example_table -j test_data

  files=(`ls ${p} | grep ^splited.test_data*`)
  asserts=(
    "splited.test_data1.csv.aa"
    "splited.test_data1.csv.ab"
    "splited.test_data1.csv.ac"
    "splited.test_data2.csv.aa"
    "splited.test_data2.csv.ab"
    "splited.test_data2.csv.ac"
  )

  for (( i = 0; i < ${#files[@]}; i++ ))
  do
    assertEquals ${asserts[$i]} ${files[$i]}
  done
}

testRemoveOldSplitedCsvFiles() {
  remote_remove_old_splited_csv_files -t example_table -j test_data

  files=(`ssh 192.168.50.99 "ls ${p} | grep splited.test_data"`)
  assertNull "$files"
}

# ローカルに対して転送してるので、ちゃんとテストになってなくて微妙
testTransportCsvFiles() {
  remote_transport_csv_files -t example_table -j test_data

  files=(`ls ${p} | grep ^test_data*`)
  asserts=(
    "test_data1.csv"
    "test_data2.csv"
    "test_data3.csv"
  )

  for (( i = 0; i < ${#files[@]}; i++ ))
  do
    assertEquals ${asserts[$i]} ${files[$i]}
  done
}

testRemoveOldCsvFiles() {
  remote_remove_old_csv_files -t example_table -j test_data

  files=(`ssh 192.168.50.99 "ls ${p} | grep test_data"`)
  assertNull "$files"
}

# エクスポート済みのcsvファイルが存在しないケース
testRemoveOldCsvFilesAgain() {
  message=`remote_remove_old_csv_files -t example_table -j test_data`

  assertEquals "old csv files are nothing" "$message"
}

# 分割済みcsvファイルが存在しないケース
testRemoveOldSplitedCsvFilesAgain() {
  message=`remote_remove_old_splited_csv_files -t example_table -j test_data`

  assertEquals "old splited csv files are nothing" "$message"
}

testExecuteSql() {
  count=`remote_execute_sql -s ${root_path}/test/sql/count_sequences.sql`

  assertEquals 0 $count
}

testExecuteVariable() {
  sql=`cat <<_EOT_

select count(*) from test.sequences
;
_EOT_`
  count=`remote_execute -s "$sql"`

  assertEquals 0 $count
}

# load shunit2
. ./shunit2-2.1.6/src/shunit2

