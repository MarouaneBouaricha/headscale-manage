#!/bin/bash

plain='\033[0m'
red='\033[0;31m'
blue='\033[1;34m'
pink='\033[1;35m'
green='\033[0;32m'
yellow='\033[0;33m'

declare -r STATUS_RUNNING=1
declare -r STATUS_NOT_RUNNING=0
declare -r STATUS_NOT_INSTALL=255

function LOGE() {
  echo -e "${red}[ERR] $* ${plain}"
}

function LOGI() {
  echo -e "${green}[INF] $* ${plain}"
}

function LOGD() {
  echo -e "${yellow}[DEG] $* ${plain}"
}

status_check() {
  if [[ ! -f "${SERVICE_FILE_PATH}" ]]; then
    return ${STATUS_NOT_INSTALL}
  fi
  temp=$(systemctl status headscale | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
  if [[ x"${temp}" == x"running" ]]; then
    return ${STATUS_RUNNING}
  else
    return ${STATUS_NOT_RUNNING}
  fi
}

start_headscale() {
  if [ -f "${SERVICE_FILE_PATH}" ]; then
    systemctl start headscale
    sleep 1s
    status_check
    if [ $? == ${STATUS_NOT_RUNNING} ]; then
      LOGE "start headscale service failed,exit"
      exit 1
    elif [ $? == ${STATUS_RUNNING} ]; then
      LOGI "start headscale service success"
    fi
  else
    LOGE "${SERVICE_FILE_PATH} does not exist,can not start service"
    exit 1
  fi
}

restart_headscale() {
  if [ -f "${SERVICE_FILE_PATH}" ]; then
    systemctl restart headscale
    sleep 1s
    status_check
    if [ $? == 0 ]; then
      LOGE "restart headscale service failed,exit"
      exit 1
    elif [ $? == 1 ]; then
      LOGI "restart headscale service success"
    fi
  else
    LOGE "${SERVICE_FILE_PATH} does not exist,can not restart service"
    exit 1
  fi
}

stop_headscale() {
  LOGD "Stopping the headscale service..."
  status_check
  if [ $? == ${STATUS_NOT_INSTALL} ]; then
    LOGE "headscale not found."
    exit 1
  elif [ $? == ${STATUS_NOT_RUNNING} ]; then
    LOGI "headscale already stopped."
    exit 1
  elif [ $? == ${STATUS_RUNNING} ]; then
    if ! systemctl stop headscale; then
      LOGE "Stopping headscale service failed,please check the logs"
      exit 1
    fi
  fi
  LOGD "headscale service stopped."
}

show_status() {
  status_check
  case $? in
  0)
    echo -e "[INF] headscale status: ${yellow} is not running ${plain}"
    ;;
  1)
    echo -e "[INF] headscale status: ${green} is running ${plain}"
    ;;
  255)
    echo -e "[INF] headscale status: ${red} not installed ${plain}"
    ;;
  esac
}

show_menu() {
  echo -e "
    ${green}Headscale management script${plain}
    ${green}0.${plain} Exit script
    ${green}1.${plain} Install service
    ${green}2.${plain} Uninstall service
    ${green}3.${plain} Start service
    ${green}4.${plain} Stop service
    ${green}5.${plain} Restart the service
    ${green}6.${plain} View nodes
"
  show_status
  echo && read -p "Please enter selection [0-6]:" num
  case "${num}" in
  0)
    exit 0
    ;;
  1)
    install_headscale && show_menu
    ;;
  2)
    uninstall_headscale && show_menu
    ;;
  3)
    start_headscale && show_menu
    ;;
  4)
    stop_headscale && show_menu
    ;;
  5)
    restart_headscale && show_menu
    ;;   
  6)
    headscale nodes list && show_menu
  ;; 
  *)
    LOGE "Please enter the correct option [0-6]"
    ;;
  esac
}


main() {
  clear
  show_menu
}

main