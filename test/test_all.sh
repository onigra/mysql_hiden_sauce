#!/bin/bash

current_path=`echo $(cd $(dirname $0); pwd)`
find ${current_path} -name "*_test.sh" -print -exec /bin/bash {} \;

