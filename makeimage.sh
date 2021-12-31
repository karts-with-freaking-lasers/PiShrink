#!/bin/bash

# This script asks the questions needed to clone the image using defaults
# or override as necessary. Script must be executed with `sudo` in order
# to successfully operate


ROOT_UID=0
E_NOTROOT=87
## Prevent the execution of the script if the user has no root privileges
if [ "${UID:-$(id -u)}" -ne "$ROOT_UID" ]; then
    echo 'Error: root privileges are needed to run this script'
    exit $E_NOTROOT
fi

# clear the screen so our text doesn't get lost.
clear

# Ensure the drive selected is the full "path" (for lack of a better word)
normalizeDrive() {
  if [[ "$1" =~ ^/dev ]]; then
    echo "$1"
  else
    echo "/dev/$1"
  fi
}

# Print instructions to help the user operate
help() {
        local help
        read -r -d '' help <<-EOM
Usage: $0 [-v] [device & imagefile.img]
  -i            Inspect to find the devices available
  -v            Be verbose
  -h            Show this help screen
EOM
        echo "$help"
        exit 1
}

# Clone the drive
begin_clone() {
  local drive="$1"
  local path="$2"
  $(/usr/bin/dd if="$drive" of="$path" bs=4M status=progress)
}

# Ask a yes or no question
yesno() {
  local q="$1"
  read -p "$q"$'\n'"yes or no > " choice
  case "$choice" in
    yes|Yes ) echo true;;
    no|No   ) echo false;;
    *       ) echo "You must enter 'yes' or 'no' to continue"; yesno "$q";;
  esac
}

# Begin the process of an interactive session
interact() {
  lsblk -e7,11
  local defaultFile="/nas/disk-images/$(date +%F).base.img"
  read -p "Which disk are we cloning, here?`echo $'\n> '`" DRIVE
  DRIVE=$(normalizeDrive "$DRIVE")
  echo $'\n\nIs this the correct drive?'
  lsblk "$DRIVE"
  if [[ true == $(yesno "`echo $'\n'`") ]]; then
    echo $'\n\n'"Use this default? $defaultFile"
    if [[ true == $(yesno "`echo $'\n'`") ]]; then
      PATH="$defaultFile"
    else
      read -p "Alright, if my default's not good enough for you...what should it be?"$'\n' PATH
    fi
    # start the cloning process
    begin_clone "$DRIVE" "$PATH"
  else
    # restart this function
    clear
    echo "Ok. Let's try again!"
    interact
  fi
}

verbose=false

if [ $# -eq 0 ]; then
  help
  exit 1
fi
while getopts ":hiv" opt; do
  case "${opt}" in
    h) help;;
    v) verbose=true;;
    i) interact;;
    *) help;;
  esac
done
