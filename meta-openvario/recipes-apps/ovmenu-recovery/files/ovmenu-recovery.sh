#!/bin/bash

DIALOGRC=/opt/bin/openvario.rc

# Config
TIMEOUT=3
INPUT=/tmp/menu.sh.$$
DIRNAME=/mnt/openvario

DEBUG_LOG=/mnt/debug.log

# Target device (typically /dev/mmcblk0):
TARGET=/dev/mmcblk0

# Image file search string:
# images=$DIRNAME/images/OpenVario-linux*.gz
# old: images=$DIRNAME/images/OpenVario-linux*.gz
images=$DIRNAME/images/O*V*-*.gz

####################################################################
echo "Upgrade start"  > %DEBUG_LOG%
date  >> %DEBUG_LOG%
time  >> %DEBUG_LOG%
date; time  >> %DEBUG_LOG%

# trap and delete temp files
trap "rm $INPUT;rm /tmp/tail.$$; exit" SIGHUP SIGINT SIGTERM

main_menu () {
while true
do
	### display main menu ###
	dialog --clear --nocancel --backtitle "OpenVario Recovery Tool" \
	--title "[ M A I N - M E N U ]" \
	--menu "You can use the UP/DOWN arrow keys" 15 50 6 \
	Flash_SDCard   "Write image to SD Card" \
	Backup-Image   "Backup complete Image" \
	Reboot   "Reboot" \
	Exit "Exit to shell" \
	ShutDown "ShutDown... " \
    2>"${INPUT}"
	 
	menuitem=$(<"${INPUT}")
 
	# make decsion 
case $menuitem in
	Flash_SDCard) select_image;;
	Backup-Image) backup_image;;
	Reboot) /opt/bin/reboot.sh;;
	Exit) /bin/bash;;
	ShutDown) shutdown -h now;;
esac

done
}

	
function backup_image(){
  datestring=$(date +%F)
  mkdir -p /$DIRNAME/backup
  # backup 1GB
  # dd if=/dev/mmcblk0 bs=1M count=1024 | gzip > /$DIRNAME/backup/$datestring.img.gz
  
  # test backup 50MB (Boot areal + 10 MB)
  dd if=/dev/mmcblk0 bs=1M count=50 | gzip > /$DIRNAME/backup/$datestring.img.gz | dialog --gauge "Writing Image ... " 10 50 0
  
  echo "Backup finished"
}


function select_image(){
	let i=0 # define counting variable
	declare -a files=() # define working array
	declare -a files_nice=()
	for line in $images; do
		let i=$i+1
		files+=($i "$line")
		filename=$(basename "$line") 
		files_nice+=($i "$filename")
	done

	if [ -n "$files" ]; then
		# Search for images
		FILE=$(dialog --backtitle "${TITLE}" \
		--title "Select image" \
		--menu "Use [UP/DOWN] keys to move, ENTER to select" \
		18 60 12 \
		"${files_nice[@]}" 3>&2 2>&1 1>&3) 
	else
		dialog --backtitle "${TITLE}" \
		--title "Select image" \
		--msgbox "\n\nNo image file found with \n'$images'!!" 10 40
		return
	fi
	IMAGEFILE=$(readlink -f $(ls -1 $images |sed -n "$FILE p"))
	
	# Show Image write options
	dialog --backtitle "${TITLE}" \
	--title "Select update method" \
	--menu "Use [UP/DOWN] keys to move, ENTER to select" \
	18 60 12 \
	"UpdateAll"	 "Update complete SD Card" \
	"UpdateuBoot"	 "Update Bootloader only" \
	2>"${INPUT}"
	
	menuitem=$(<"${INPUT}")
 
	# make decsion 
	case $menuitem in
		UpdateuBoot) updateuboot;;
		UpdateAll) updateall;;
	esac
	
}

#update rootfs on mmcblk0
function updaterootfs(){
		
	(pv -n ${IMAGEFILE} | gunzip -c | dd bs=1024 skip=1024 | dd of=$TARGET bs=1024 seek=1024) 2>&1 | dialog --gauge "Writing Image ... " 10 50 0
		
}

function notimplemented(){

	dialog --backtitle "${TITLE}" \
			--msgbox "Not implemented yet !!" 10 60
}

#update uboot
function updateuboot(){
		
	#gunzip -c $(cat selected_image.$$) | dd of=$TARGET bs=1024 count=1024	
	(pv -n ${IMAGEFILE} | gunzip -c | dd of=$TARGET bs=1024 count=1024) 2>&1 | dialog --gauge "Writing Image ... " 10 50 0
		
}

#update updateall
function updateall(){
    sync
    echo "Upgrade with '${IMAGEFILE}'"  >> %DEBUG_LOG%
    IMAGE_NAME="$(basename $IMAGEFILE .gz)"
    (pv -n ${IMAGEFILE} | gunzip -c | dd of=$TARGET bs=16M) 2>&1 | \
    dialog --gauge "Writing Image ...\nfile = ${IMAGE_NAME}  " 10 50 0
    #########################################
    # remove the recovery file:
    echo "Upgrade '${IMAGEFILE}' finished"  >> %DEBUG_LOG%
    rm -f $DIRNAME/ov-recovery.itb
    # recover XCSoarData:
    if [ -d "${DIRNAME}/sdcard" ]; then
        mkdir -p /mnt/sd
        if [ -e "${DIRNAME}/sdcard/part1/config.uEnv" ]; then
            mount ${TARGET}p1  /mnt/sd
            source ${DIRNAME}/sdcard/part1/config.uEnv
            echo "sdcard/part1/config.uEnv"      >> %DEBUG_LOG%
            echo "------------------------"      >> %DEBUG_LOG%
            echo "rotation      = $rotation"     >> %DEBUG_LOG%
            echo "brightness    = $brightness"   >> %DEBUG_LOG%
            echo "font          = $font"         >> %DEBUG_LOG%
            echo "fdt           = $fdtfile"      >> %DEBUG_LOG%
            echo "========================"      >> %DEBUG_LOG%
            if [ -n rotation ]; then
                echo "Set rotaton '$rotation'"  >> %DEBUG_LOG%
                sed -i 's/^rotation=.*/rotation='$rotation'/' /mnt/sd/config.uEnv
            fi
            if [ -n $font ]; then
                sed -i 's/^font=.*/font='$font'/' /mnt/sd/config.uEnv
                echo "Set font '$font'"  >> %DEBUG_LOG%
            fi
            if [ -n $brightness ]; then
              count=$(grep -c "brightness" /mnt/sd/config.uEnv)
              if [ "$count" = "0" ]; then 
                echo "brightness=$brightness" >> /mnt/sd/config.uEnv
                echo "Set brightness (1) '$brightness' NEW"  >> %DEBUG_LOG%
              else
                sed -i 's/^brightness=.*/brightness='$brightness'/' /mnt/sd/config.uEnv
                echo "Set brightness (2) '$brightness' UPDATE"  >> %DEBUG_LOG%
              fi
            fi
            
           source ${DIRNAME}/sdcard/config.uSys
            echo "sdcard/config.uSys"           >> %DEBUG_LOG%
            echo "------------------"           >> %DEBUG_LOG%
            echo "ROTATION      = $ROTATION"    >> %DEBUG_LOG%
            echo "BRIGHTNESS    = $BRIGHTNESS"  >> %DEBUG_LOG%
            echo "FONT          = $FONT"        >> %DEBUG_LOG%
            echo "SSH           = $SSH"         >> %DEBUG_LOG%
            echo "========================"     >> %DEBUG_LOG%
            if [ -n $ROTATION ]; then
                sed -i 's/^rotation=.*/rotation='$ROTATION'/' /mnt/sd/config.uEnv
            fi
            if [ -n font ]; then
                sed -i 's/^font=.*/font='$font'/' /mnt/sd/config.uEnv
            fi
            # TODO(August2111): check, if this correct
            if [ -n $BRIGHTNESS ]; then
                  count=$(grep -c "brightness" /mnt/sd/config.uEnv)
                  if [ "$count" = "0" ]; then 
                    echo "brightness=$BRIGHTNESS" >> /mnt/sd/config.uEnv
                    echo "Set BRIGHTNESS (3) '$BRIGHTNESS' NEW"  >> %DEBUG_LOG%
                  else
                    sed -i 's/^brightness=.*/brightness='$BRIGHTNESS'/' /mnt/sd/config.uEnv
                    echo "Set BRIGHTNESS (4) '$BRIGHTNESS' UPDATE"  >> %DEBUG_LOG%
                  fi
            fi
            
            
            umount /mnt/sd
        fi

        mount ${TARGET}p2  /mnt/sd
        if [ "$Upgrade" = "OldSystem" ]; then 
            # removing '/mnt/sd/home/root/ov-recovery.itb' not necessary because after
            # overwriting image this file/link isn't available anymore 
            # rm -f /mnt/sd/home/root/ov-recovery.itb
            ls -l /mnt/sd/home/root/.xcsoar
            
            rm -rf /mnt/sd/home/root/.xcsoar/*
            cp -frv ${DIRNAME}/sdcard/part2/xcsoar/* /mnt/sd/home/root/.xcsoar/
            if [ -d "${DIRNAME}/sdcard/part2/glider_club" ]; then
              mkdir -p /mnt/sd/home/root/.glider_club
              cp -frv ${DIRNAME}/sdcard/part2/glider_club/* /mnt/sd/home/root/.glider_club/
            fi
        fi
        # restore the bash history:
        cp -fv  ${DIRNAME}/sdcard/part2/.bash_history /mnt/sd/home/root/

        
        if [ -e "${DIRNAME}/sdcard/config.uSys" ]; then
          cp ${DIRNAME}/sdcard/config.uSys /mnt/sd/home/root/config.uSys
        fi
        
        ls -l /mnt/sd/home/root/.xcsoar
        echo "ready OV upgrade!"
        echo "ready OV upgrade!"  >> %DEBUG_LOG%
    else
        echo "' ${DIRNAME}/sdcard/part2/xcsoar' doesn't exist!"
        echo "' ${DIRNAME}/sdcard/part2/xcsoar' doesn't exist!"  >> %DEBUG_LOG%
    fi


    echo "UPGRADE_LEVEL = '$UPGRADE_LEVEL'"  >> %DEBUG_LOG%
    if [ -z $UPGRADE_LEVEL ]; then 
       echo "UPGRADE_LEVEL is set to '0000'"  >> %DEBUG_LOG%
       UPGRADE_LEVEL=0;
    fi
    
    case "$UPGRADE_LEVEL" in
    0|1) echo "create 3rd partition 'ov-data'"
         echo "------------------------------"
         read -p "Press enter to continue"
         source /mnt/sd/usr/bin/create_datapart.sh
         ;;
    *)   echo "unknown UPGRADE_LEVEL '$UPGRADE_LEVEL'"  >> %DEBUG_LOG% ;;
    esac
    
    
    echo "Upgrade ready"  >> %DEBUG_LOG%
    # set dmesg kernel level back to the highest:
    dmesg -n 8
    dmesg > /mnt/dmesg.txt
    #############################################################
    # only for debug-test
    read -p "Press enter to continue"
    # /bin/bash
    #############################################################
    
    # reboot:
    /opt/bin/reboot.sh
}

function update_system() {
	echo "Updating System ..." > /tmp/tail.$$
	/usr/bin/update-system.sh >> /tmp/tail.$$ &
	dialog --backtitle "OpenVario" --title "Result" --tailbox /tmp/tail.$$ 30 50
}

# ??? setfont cp866-8x14.psf.gz

if [ -e $DIRNAME/upgrade.file ]; then
  read IMAGEFILE < $DIRNAME/upgrade.file
else
  IMAGEFILE="Not available!"
fi
echo "UpdateFile: $IMAGEFILE "

# image file name with path!
IMAGEFILE="$DIRNAME/images/$IMAGEFILE"
echo "Detected image file: '$IMAGEFILE'!"  >> %DEBUG_LOG%

# set dmesg minimum kernel level:
dmesg -n 1

if [ -e "$IMAGEFILE" ];
then
	echo "Update $IMAGEFILE !!!!"
	updateall
else
	main_menu
fi

#=====================================================================================
#=====================================================================================
#=====================================================================================
