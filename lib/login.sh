#!/bin/bash
_APP_ROOT="/usr/local/lib/mysql_hiden_sauce"

audit_logger() {
  _audit="y"
  _logdir="${_APP_ROOT}/log/"
  _wdate=`date +%Y%m%d`
  
  if [ ! -a ${_logdir}/login.${_wdate}.log ]; then
    touch ${_logdir}/login.${_wdate}.log
    chmod -Rf 777 ${_logdir}/login.${_wdate}.log
  fi

  if [ "$_audit" == "y" ]; then
    if [ "$_suser" != "sysopr" ]; then
      _wtime=`date +"%Y-%m-%d-%H:%M:%S"`
      _who=`who am i`
      _hostname=`hostname -s`
      echo "$_wtime $_hostname $_shost $_suser $_who" >> ${_logdir}/login.${_wdate}.log
    fi
  fi
}

get_password() {
  _shost=$1
  _suser=$2

  audit_logger

  . ${_APP_ROOT}/config/account.info
  
  for (( I = 0; I < ${#_userinfo[@]}; ++I ))
  do
    _host=`echo ${_userinfo[$I]} | awk -F: '{print $1}';`
    _user=`echo ${_userinfo[$I]} | awk -F: '{print $2}';`
    _pass=`echo ${_userinfo[$I]} | awk -F: '{print $3}';`

    if [ "$_host" = "${_shost}" ]; then
      if [ "$_user" = "${_suser}" ]; then
        echo ${_pass}
        exit 0 
      else
        _flg="1"
      fi
    else
        _flg="1"
    fi

  done

  if [ "$_flg" = "1" ]; then
    echo "Password Not Found"
    exit 1
  fi 
}

