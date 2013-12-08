#!/usr/local/bin/bash

oneTimeSetUp() {
  . ../lib/login.sh
  _HOSTNAME=`hostname -s`
}

testGetPassword() {
  pass=$(get_password $_HOSTNAME develop)
  assertEquals "password" "${pass}"
}

testPasswordNotFound() {
  msg=$(get_password $_HOSTNAME root)
  assertEquals "Password Not Found" "${msg}"
}

testLogger() {
  assertTrue "[ -a ../log/login.$(date +%Y%m%d).log ]"
}

# load shunit2
. ./shunit2-2.1.6/src/shunit2

