#!/bin/bash

oneTimeSetUp() {
  # setup
  root_path=`echo $(cd .. $(dirname $0); pwd)`
  . ${root_path}/lib/job_framework/remote_export.sh 192.168.50.99 develop

  # create test data
  p="${root_path}/batch_example/data/example_table"
  ssh 192.168.50.99 "touch ${p}/test_data1.csv"
  ssh 192.168.50.99 "touch ${p}/test_data2.csv"
  ssh 192.168.50.99 "touch ${p}/test_data3.csv"

  for i in {1..11};
  do
    ssh 192.168.50.99 "echo 'hoge' >> ${p}/test_data1.csv"
  done
}

oneTimeTearDown() {
  rm -f ${p}/*
}

testDryrunSplitBigFile(){
  messages=`remote_split_big_file -t example_table -j test_data -l 5 -b 50 -n`
  asserts="ssh 192.168.50.99 \"split -l 5 ${p}/test_data1.csv ${p}/splited.test_data1.csv.\""

  assertEquals "${asserts}" "${messages}"
}

testTransportCsvFiles() {
  messages=`remote_transport_csv_files -t example_table -j test_data -n`
  asserts="rsync -avz 192.168.50.99:${p}/test_data* ${p}/"
  
  assertEquals "${asserts}" "${messages}"
}

testDryrunRemoveOldSplitedCsvFiles() {
  ssh 192.168.50.99 "split -l 5 ${p}/test_data1.csv ${p}/splited.test_data1.csv."

  messages=`remote_remove_old_splited_csv_files -t example_table -j test_data -n`
  asserts="ssh 192.168.50.99 \"rm -f ${p}/splited.test_data*\""

  assertEquals "${asserts}" "${messages}"
}

testTransportSplitedCsvFiles() {
  messages=`remote_transport_csv_files -t example_table -j test_data -n`
  asserts="rsync -avz 192.168.50.99:${p}/splited.test_data* ${p}/"
  
  assertEquals "${asserts}" "${messages}"
}

testDryrunRemoveOldCsvFiles() {
  messages=`remote_remove_old_csv_files -t example_table -j test_data -n`
  asserts="ssh 192.168.50.99 \"rm -f ${p}/test_data*\""

  assertEquals "${asserts}" "${messages}"
}

# load shunit2
. ./shunit2-2.1.6/src/shunit2

