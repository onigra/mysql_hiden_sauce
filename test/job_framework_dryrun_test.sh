#!/bin/bash

oneTimeSetUp() {
  # setup
  root_path=`echo $(cd .. $(dirname $0); pwd)`
  . ${root_path}/lib/job_framework/export.sh develop

  # create test data
  p="${root_path}/batch_example/data/example_table"
  touch ${p}/test_data1.csv
  touch ${p}/test_data2.csv
  touch ${p}/test_data3.csv

  for i in {1..11};
  do
    echo "hoge" >> ${p}/test_data1.csv
  done
}

oneTimeTearDown() {
  rm -f ${p}/*
}

testDryrunSplitBigFile(){
  messages=`split_big_file -t example_table -j test_data -l 5 -b 50 -n`
  asserts="split -l 5 ${p}/test_data1.csv ${p}/splited.test_data1.csv."

  assertEquals "${asserts}" "${messages}"
}

testDryrunRemoveOldSplitedCsvFiles() {
  split -l 5 ${p}/test_data1.csv ${p}/splited.test_data1.csv.

  messages=`remove_old_splited_csv_files -t example_table -j test_data -n`
  asserts="rm -f ${p}/splited.test_data*"

  assertEquals "${asserts}" "${messages}"
}

testDryrunRemoveOldCsvFiles() {
  messages=`remove_old_csv_files -t example_table -j test_data -n`
  asserts="rm -f ${p}/test_data*"

  assertEquals "${asserts}" "${messages}"
}

# load shunit2
. ./shunit2-2.1.6/src/shunit2

