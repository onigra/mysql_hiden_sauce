#!/bin/bash

# パスの末尾に/をつけてもつけなくても大丈夫なようにsedする
from_dir=`echo $1 | sed -e "s|/$||"`
to_host_user=$2
to_host=$3
to_dir=`echo $4 | sed -e "s|/$||"`

# 引数チェック
if [ "$from_dir" == "" ]; then
  echo "usage $0 from_directory_path to_host_user_name to_host_ip to_directory_path"
  exit -1
elif [ "$to_host_user" == "" ]; then
  echo "usage $0 from_directory_path to_host_user_name to_host_ip to_directory_path"
  exit -1
elif [ "$to_host" == "" ]; then
  echo "usage $0 from_directory_path to_host_user_name to_host_ip to_directory_path"
  exit -1
elif [ "$to_dir" == "" ]; then
  echo "usage $0 from_directory_path to_host_user_name to_host_ip to_directory_path"
  exit -1
fi

# ディレクトリ構造を先にコピーしておかないとこける
rsync -a --include "*/" --exclude "*" ${from_dir}/ ${to_host_user}@${to_host}:${to_dir}/

# findでディレクトリ配下のファイルを再起的に取得し、それを引数にrsyncを実行する
# つまり、ファイルが100万個あればプロセスが100万起動することになるので注意
cd ${from_dir}
for f in `find . -type f`
do
  f=${f:2}
  /usr/bin/rsync -avz --bwlimit=0 --whole-file --sockopts=TCP_NODELAY --delay-updates ${from_dir}/$f ${to_host_user}@${to_host}:${to_dir}/$f &

  usleep 500000
done

