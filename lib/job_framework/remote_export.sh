#!/bin/bash

###
# setup
#
_REMOTE_HOST=$1
_USER=$2
application_root="/usr/local/lib/mysql_hiden_sauce"
. ${application_root}/lib/remote_exec_sql.sh $_REMOTE_HOST $_USER

# -------------------------------------------------------
#  csvファイルのエクスポート先のパスを取得する
# -------------------------------------------------------
remote_get_path() {
  csv_path="${application_root}/batch_example/data"
  echo ${csv_path}/$1
}

# -------------------------------------------------------
#  エクスポート済みのcsvファイル名を取得する
# -------------------------------------------------------
remote_get_csv_file_names() {
  OPTIND_OLD=$OPTIND
  OPTIND=1
  while getopts "t:j:" opts
  do
    case $opts in
      t) _TABLE_NAME=$OPTARG ;;
      j) _JOB_TYPE=$OPTARG ;;
    esac
  done

  path=`remote_get_path ${_TABLE_NAME}`
  ssh ${_REMOTE_HOST} "ls ${path} | grep ^${_JOB_TYPE}"
}

# -------------------------------------------------------
#  エクスポートしたファイルのサイズが大きい場合splitする
#
#  OPTINDについて
#  http://d.hatena.ne.jp/hirose31/20101217/1292581425
# -------------------------------------------------------
remote_split_big_file() {
  _LINES=5000000
  _BYTES=5000000000

  _DRYRUN=""
  OPTIND_OLD=$OPTIND
  OPTIND=1
  while getopts "t:j:l:b:n" opts
  do
    case $opts in
      t) _TABLE_NAME=$OPTARG ;;
      j) _JOB_TYPE=$OPTARG ;;
      l) _LINES=$OPTARG ;;
      b) _BYTES=$OPTARG ;;
      n) _DRYRUN="TRUE" ;;
    esac
  done

  _FILE_PATH=`remote_get_path ${_TABLE_NAME}`
  _TARGET_FILES=(`remote_get_csv_file_names -t ${_TABLE_NAME} -j ${_JOB_TYPE}`)

  for (( i = 0; i < ${#_TARGET_FILES[@]}; i++ ))
  do
    target_filesize=`ssh ${_REMOTE_HOST} "wc -c ${_FILE_PATH}/${_TARGET_FILES[$i]}" | awk '{print $1}'`

    if [ $_BYTES -lt $target_filesize ]; then
      if [ "$_DRYRUN" = "TRUE" ]; then
        echo "ssh ${_REMOTE_HOST} \"split -l ${_LINES} ${_FILE_PATH}/${_TARGET_FILES[$i]} ${_FILE_PATH}/splited.${_TARGET_FILES[$i]}.\""
      else
        ssh ${_REMOTE_HOST} "split -l ${_LINES} ${_FILE_PATH}/${_TARGET_FILES[$i]} ${_FILE_PATH}/splited.${_TARGET_FILES[$i]}."
      fi
    fi
  done
}

# -------------------------------------------------------
#  エクスポート済みの古いcsvファイルを削除する
#  存在しない場合はメッセージを返す
# -------------------------------------------------------
remote_remove_old_csv_files() {
  _DRYRUN=""
  OPTIND_OLD=$OPTIND
  OPTIND=1
  while getopts "t:j:n" opts
  do
    case $opts in
      t) _TABLE_NAME=$OPTARG ;;
      j) _JOB_TYPE=$OPTARG ;;
      n) _DRYRUN="TRUE" ;;
    esac
  done

  _FILE_PATH=`remote_get_path ${_TABLE_NAME}`
  _TARGET_FILES=(`remote_get_csv_file_names -t ${_TABLE_NAME} -j ${_JOB_TYPE}`)

  if [ ${#_TARGET_FILES[*]} -gt 0 ]; then
    if [ "$_DRYRUN" = "TRUE" ]; then
      echo "ssh ${_REMOTE_HOST} \"rm -f ${_FILE_PATH}/${_JOB_TYPE}*\""
    else
      ssh ${_REMOTE_HOST} "rm -f ${_FILE_PATH}/${_JOB_TYPE}*"
    fi
  else
    echo "old csv files are nothing"
  fi
}

# -------------------------------------------------------
#  エクスポート済みの古い分割済みcsvファイルを削除する
#  存在しない場合はメッセージを返す
# -------------------------------------------------------
remote_remove_old_splited_csv_files() {
  _DRYRUN=""
  OPTIND_OLD=$OPTIND
  OPTIND=1
  while getopts "t:j:n" opts
  do
    case $opts in
      t) _TABLE_NAME=$OPTARG ;;
      j) _JOB_TYPE=$OPTARG ;;
      n) _DRYRUN="TRUE" ;;
    esac
  done

  _FILE_PATH=`remote_get_path ${_TABLE_NAME}`
  _TARGET_FILES=(`remote_get_csv_file_names -t ${_TABLE_NAME} -j splited.${_JOB_TYPE}`)

  if [ ${#_TARGET_FILES[*]} -gt 0 ]; then
    if [ "$_DRYRUN" = "TRUE" ]; then
      echo "ssh ${_REMOTE_HOST} \"rm -f ${_FILE_PATH}/splited.${_JOB_TYPE}*\""
    else
      ssh ${_REMOTE_HOST} "rm -f ${_FILE_PATH}/splited.${_JOB_TYPE}*"
    fi
  else
    echo "old splited csv files are nothing"
  fi
}

# -------------------------------------------------------
#  remote_remove_old_splited_csv_filesとremote_remove_old_csv_filesを
#  よんでるだけ
# -------------------------------------------------------
remote_remove_exported_files() {
  _DRYRUN=""
  OPTIND_OLD=$OPTIND
  OPTIND=1
  while getopts "t:j:n" opts
  do
    case $opts in
      t) _TABLE_NAME=$OPTARG ;;
      j) _JOB_TYPE=$OPTARG ;;
      n) _DRYRUN="TRUE" ;;
    esac
  done

  if [ "$_DRYRUN" = "TRUE" ]; then
    remote_remove_old_csv_files -t ${_TABLE_NAME} -j ${_JOB_TYPE} -n
    remote_remove_old_splited_csv_files -t ${_TABLE_NAME} -j ${_JOB_TYPE} -n
  else
    remote_remove_old_csv_files -t ${_TABLE_NAME} -j ${_JOB_TYPE}
    remote_remove_old_splited_csv_files -t ${_TABLE_NAME} -j ${_JOB_TYPE}
  fi
}

remote_transport_csv_files() {
  _DRYRUN=""
  OPTIND_OLD=$OPTIND
  OPTIND=1
  while getopts "t:j:n" opts
  do
    case $opts in
      t) _TABLE_NAME=$OPTARG ;;
      j) _JOB_TYPE=$OPTARG ;;
      n) _DRYRUN="TRUE" ;;
    esac
  done

  _FILE_PATH=`remote_get_path ${_TABLE_NAME}`
  _TARGET_FILES=(`remote_get_csv_file_names -t ${_TABLE_NAME} -j splited.${_JOB_TYPE}`)

  if [ "$_DRYRUN" = "TRUE" ]; then
    if [ ${#_TARGET_FILES[*]} -gt 0 ]; then
      echo "rsync -avz ${_REMOTE_HOST}:${_FILE_PATH}/splited.${_JOB_TYPE}* ${_FILE_PATH}/"
    else
      echo "rsync -avz ${_REMOTE_HOST}:${_FILE_PATH}/${_JOB_TYPE}* ${_FILE_PATH}/"
    fi
  else
    if [ ${#_TARGET_FILES[*]} -gt 0 ]; then
      rsync -avz ${_REMOTE_HOST}:${_FILE_PATH}/splited.${_JOB_TYPE}* ${_FILE_PATH}/
    else
      rsync -avz ${_REMOTE_HOST}:${_FILE_PATH}/${_JOB_TYPE}* ${_FILE_PATH}/
    fi
  fi
}

