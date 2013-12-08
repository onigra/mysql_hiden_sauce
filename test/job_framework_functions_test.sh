#!/bin/bash

oneTimeSetUp() {
  # setup
  root_path=`echo $(cd .. $(dirname $0); pwd)`
  . ${root_path}/lib/job_framework/export.sh develop

  # create test table
  execute_sql -s ${root_path}/test/ddl/test_table.sql

  # create test data
  p="${root_path}/batch_example/data/example_table"
  touch ${p}/test_data1.csv
  touch ${p}/test_data2.csv
  touch ${p}/test_data3.csv

  for i in {1..11};
  do
    echo "hoge" >> ${p}/test_data1.csv
    echo "hoge" >> ${p}/test_data2.csv
  done
}

oneTimeTearDown() {
  execute -s "drop database test;"
}

testGetPath() {
  target=`get_path example_table`
  assertEquals "${root_path}/batch_example/data/example_table" "$target"
}

testGetCsvFileNames() {
  files=(`get_csv_file_names example_table test_data`)
  asserts=("test_data1.csv" "test_data2.csv" "test_data3.csv")

  for (( i = 0; i < ${#files[@]}; i++ ))
  do
    assertEquals ${asserts[$i]} ${files[$i]}
  done
}

testSplitBigFile(){
  split_big_file -t example_table -j test_data -l 5 -b 50

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

testRemoveOldSplitedCsvFiles() {
  remove_old_splited_csv_files -t example_table -j test_data

  files=(`ls ${root_path}/batch_example/data/example_table | grep splited.test_data`)
  assertNull "$files"
}

testRemoveOldCsvFiles() {
  remove_old_csv_files -t example_table -j test_data

  files=(`ls ${root_path}/batch_example/data/example_table | grep test_data`)
  assertNull "$files"
}

# エクスポート済みのcsvファイルが存在しないケース
testRemoveOldCsvFilesAgain() {
  message=`remove_old_csv_files -t example_table -j test_data`

  assertEquals "old csv files are nothing" "$message"
}

# 分割済みcsvファイルが存在しないケース
testRemoveOldSplitedCsvFilesAgain() {
  message=`remove_old_splited_csv_files -t example_table -j test_data`

  assertEquals "old splited csv files are nothing" "$message"
}

testExecuteSql() {
  count=`execute_sql -s ${root_path}/test/sql/count_sequences.sql`

  assertEquals 0 $count
}

testExecuteVariable() {
  sql=`cat <<_EOT_

select count(*) from test.sequences
;
_EOT_`
  count=`execute -s "$sql"`

  assertEquals 0 $count
}

# load shunit2
. ./shunit2-2.1.6/src/shunit2

