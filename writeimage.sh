#!/bin/bash

# This script asks the questions needed to write an image to multiple
# drives. Script must be executed with `sudo` in order to successfully operate


ROOT_UID=0
E_NOTROOT=87
## Prevent the execution of the script if the user has no root privileges
if [ "${UID:-$(id -u)}" -ne "$ROOT_UID" ]; then
    echo 'Error: root privileges are needed to run this script'
    exit $E_NOTROOT
fi

# microdrive letters (e.g., /dev/sda => a, /dev/sdc - /dev/sdf => c-f)
md=$1
imagePath=$2

obtainMicroDriveLetters() {
	if [[ $md =~ '-' ]]; then
		regex="([$1]+)"
		if [[ "abcdefghijklmnopqrstuvwxyz" =~ $regex ]]; then
			microDrives="${BASH_REMATCH[0]}"
		fi
	fi
}

if [[ ! -z $md ]]; then
	obtainMicroDriveLetters $md
fi

if [[ -z $imagePath ]]; then
	echo "which file?"
	IFS=$'\n'; select file in $(find /nas/disk-images/*.gz -printf "%f\n"); do
		imagePath=/nas/disk-images/$file
		break
	done
fi

writeImageTo() {
	SUB_START_DATE=`date`
	drive=$1
	cmd="/usr/bin/gunzip -c $imagePath | sudo /usr/bin/dd of=$drive status=progress &&"
	echo $cmd
	# echo "Executing: $cmd"
	# $($cmd)
}

expandDrive() {
	driveLetter=$1
	echo "/dev/sd$driveLetter"
}

# Each letter provided is expanded into the appropriate drive representation.
# (e.g., $1=="c" => "/dev/sdc")
expandMicroDrives() {
	DRIVES=$1
	while read -n 1 driveLetter; do 
		# This while loop executes length + 1 times; the last of which is empty.
		[ -z $driveLetter ] && continue

		drive=`expandDrive "$driveLetter"`
		writeImageTo "$drive"
	done <<< "$DRIVES"
}

if [[ -z $microDrives ]]; then
	lsblk -e7,11
	read -p "Type the letters representing each drive (e.g., cde, c-l):`echo $'\n> '`" md
	obtainMicroDriveLetters $md
fi

START_DATE=`date`

expandMicroDrives $microDrives

END_DATE=`date`

echo "Started at: $START_DATE"
echo "Completed: $END_DATE"

START_TIME=`date -d "$START_DATE" +%s`
END_TIME=`date -d "$END_DATE" +%s`
DIFF=$((END_TIME - START_TIME))
printf "It took %.2f hours to complete.\n" $(( ($DIFF)/60/60 ))

