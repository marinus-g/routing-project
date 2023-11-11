#!/bin/bash

primary_interface=""
internal_interface=""
interfaces=($(ls /sys/class/net))

REQUIRED_PACKAGE="dialog"
PKG_OK="TEMP"

function remove_dialog_package() {
  if [ "" = "$PKG_OK" ]; then
    apt remove $REQURED_PACAKGE
  fi
}

function check_root() {
  if [ "$USER" != "root" ];
  then
    echo "Please execute this script as root!"
    exit
  fi
}


function choose_primary_interface() {
  doptions=()
  for ((i=0; i <${#interfaces[@]}; i++)) do
    doptions+=("$i" "${interfaces[i]}")
  done
  dialog --menu "Select the primary network interface" 15 40 10 "${doptions[@]}" 2>tempfile
  clear
  selection=$(cat tempfile)
  echo "$selection"
  dialog --msgbox "You selected $selection" 10 40
  rm -f tempfile
  if [[ "$selection" =~ ^[0-9]+$ && selection -ge 0 && selection -lt ${#interfaces[@]} ]]; then
    primary_interface=${interfaces[selection]}
  else
    dialog --msgbox "Invalid selection, exiting.." 10 40
    remove_dialog_package
    clear
    exit	
  fi
}


function choose_internal_interface() {
  doptions=();
  for ((i=0; i <${#interfaces[@]}; i++)) do
    doptions+=("$i" "${interfaces[i]}")
  done
  dialog --menu "Select the internal network interface" 15 40 10 "${doptions[@]}" 2>tempfile
  clear
  selection=$(cat tempfile)
  echo "§selection"
  rm -f tempfile
  if [[ "$selection" =~ ^[0-9]+$ && selection -ge 0 && selection -lt ${#interfaces[@]} ]]; then
    internal_interface=${interfaces[selection]}
  else
    dialog --msgbox "Invalid selection, exiting.." 10 40
    remove_dialog_package
    clear
    exit
  fi
}


function check_if_interfaces_are_equal() {
  if [ "$primary_interface" == "$internal_interface" ];
  then
    dialog --msgbox "You cannot use the same interfaces for both the primary and the internal connection!" 19 40
    remove_dialog_package
    clear
    exit
  fi
}


function insert_ip_tables() {
  $1 -t nat -A POSTROUTING -o "$primary_interface" -j MASQUERADE
  $1 -A FORWARD -i "$primary_interface" -o "$internal_interface" -m state --state RELATED,ESTABLISHED -j ACCEPT
  $1 -A FORWARD -i "$internal_interface" -o "$primary_interface" -j ACCEPT
}

check_root
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PACKAGE|grep "install ok installed")
if [ "" = "$PKG_OK" ]; then
  apt --yes install $REQUIRED_PACKAGE
  sleep 3
fi
choose_primary_interface
clear
choose_internal_interface
clear
check_if_interfaces_are_equal
# ipv4 tables
insert_ip_tables "iptable"
remove_dialog_package
clear
echo "Applied iptable rules!"
#iptables -t nat -A POSTROUTING -o "$primary_interface" -j MASQUERADE
#iptables -A FORWARD -i "$primary_interface" -o "$internal_interface" -m state --state RELATED,ESTABLISHED -j ACCEPT
#iptables -A FORWARD -i "$internal_interface" -o "$primary_interface" -j ACCEPT
