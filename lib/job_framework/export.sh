#!/bin/bash

###
# setup
#
_USER=$1
application_root="/usr/local/lib/mysql_hiden_sauce"
. ${application_root}/lib/exec_sql.sh $_USER

# -------------------------------------------------------
#  csvファイルのエクスポート先のパスを取得する
# -------------------------------------------------------
get_path() {
  csv_path="${application_root}/batch_example/data"
  echo ${csv_path}/$1
}

# -------------------------------------------------------
#  エクスポート済みのcsvファイル名を取得する
# -------------------------------------------------------
get_csv_file_names() {
  p=`get_path $1`
  ls ${p} | grep ^$2
}

# -------------------------------------------------------
#  エクスポートしたファイルのサイズが大きい場合splitする
#
#  OPTINDについて
#  http://d.hatena.ne.jp/hirose31/20101217/1292581425
# -------------------------------------------------------
split_big_file() {
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

  _FILE_PATH=`get_path ${_TABLE_NAME}`
  _TARGET_FILES=(`get_csv_file_names ${_TABLE_NAME} ${_JOB_TYPE}`)

  for (( i = 0; i < ${#_TARGET_FILES[@]}; i++ ))
  do
    target_filesize=`wc -c ${_FILE_PATH}/${_TARGET_FILES[$i]} | awk '{print $1}'`

    if [ $_BYTES -lt $target_filesize ]; then
      if [ "$_DRYRUN" = "TRUE" ]; then
        echo "split -l ${_LINES} ${_FILE_PATH}/${_TARGET_FILES[$i]} ${_FILE_PATH}/splited.${_TARGET_FILES[$i]}."
      else
        split -l ${_LINES} ${_FILE_PATH}/${_TARGET_FILES[$i]} ${_FILE_PATH}/splited.${_TARGET_FILES[$i]}.
      fi
    fi
  done
}

# -------------------------------------------------------
#  エクスポート済みの古いcsvファイルを削除する
#  存在しない場合はメッセージを返す
# -------------------------------------------------------
remove_old_csv_files() {
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

  _FILE_PATH=`get_path ${_TABLE_NAME}`
  _TARGET_FILES=(`get_csv_file_names ${_TABLE_NAME} ${_JOB_TYPE}`)

  if [ ${#_TARGET_FILES[*]} -gt 0 ]; then
    if [ "$_DRYRUN" = "TRUE" ]; then
      echo "rm -f ${_FILE_PATH}/${_JOB_TYPE}*"
    else
      rm -f ${_FILE_PATH}/${_JOB_TYPE}*
    fi
  else
    echo "old csv files are nothing"
  fi
}

# -------------------------------------------------------
#  エクスポート済みの古い分割済みcsvファイルを削除する
#  存在しない場合はメッセージを返す
# -------------------------------------------------------
remove_old_splited_csv_files() {
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

  _FILE_PATH=`get_path ${_TABLE_NAME}`
  _TARGET_FILES=(`get_csv_file_names ${_TABLE_NAME} splited.${_JOB_TYPE}`)

  if [ ${#_TARGET_FILES[*]} -gt 0 ]; then
    if [ "$_DRYRUN" = "TRUE" ]; then
      echo "rm -f ${_FILE_PATH}/splited.${_JOB_TYPE}*"
    else
      rm -f ${_FILE_PATH}/splited.${_JOB_TYPE}*
    fi
  else
    echo "old splited csv files are nothing"
  fi
}

# -------------------------------------------------------
#  remove_old_splited_csv_filesとremove_old_csv_filesを
#  よんでるだけ。テスト必要無いと思ったから書いてない
# -------------------------------------------------------
remove_exported_files() {
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
    remove_old_csv_files -t ${_TABLE_NAME} -j ${_JOB_TYPE} -n
    remove_old_splited_csv_files -t ${_TABLE_NAME} -j ${_JOB_TYPE} -n
  else
    remove_old_csv_files -t ${_TABLE_NAME} -j ${_JOB_TYPE}
    remove_old_splited_csv_files -t ${_TABLE_NAME} -j ${_JOB_TYPE}
  fi
}

