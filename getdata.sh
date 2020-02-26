#!/bin/bash
#/--------------------------------------------------------------------------------------------------------|  www.vdm.io  |------/
#
#	@version		1.0.0
#	@build			16th Feb, 2020
#	@package		setninal
#	@author			Llewellyn van der Merwe <https://github.com/Llewellynvdm>
#	@copyright	Copyright (C) 2020. All Rights Reserved
#	@license		GNU/GPL Version 2 or later - http://www.gnu.org/licenses/gpl-2.0.html
#
#/-----------------------------------------------------------------------------------------------------------------------------/

############################ GLOBAL ##########################
ACTION="setdata"
OWNER="sentinel-mx"
NAME="client"
HOST="https://sentinel.our.mx/"
######### DUE TO NOT BEING ABLE TO INCLUDE DYNAMIC ###########

#################### UPDATE TO YOUR NEEDS ####################
##############################################################
##############                                      ##########
##############               CONFIG                 ##########
##############                                      ##########
##############################################################
REPOURL="https://raw.githubusercontent.com/${OWNER}/${NAME}/master/"
SENTINELSERVER="${HOST}/${ACTION}"

##############################################################
##############                                      ##########
##############                MAIN                  ##########
##############                                      ##########
##############################################################
function main () {
	## set time for this run
	echoTweak "$ACTION on $Datetimenow"
	echo "started"
	# get this server IP
	HOSTIP="$(dig +short myip.opendns.com @resolver1.opendns.com)"
	## make sure cron is set
	setCron
	## get the local server key
	getLocalKey
	## check access (set if not ready)
	setAccessToken
	## get the data
	getData
	## Work with the data
	storeLocalData
}

##############################################################
##############                                      ##########
##############              DEFAULTS                ##########
##############                                      ##########
##############################################################
Datetimenow=$(TZ=":ZULU" date +"%m/%d/%Y @ %R (UTC)" )
CLIENTUSER=$(whoami)
CLIENTHOME=~/
CLIENTSCRIPT="${REPOURL}$ACTION.sh"
CLIENTSERVERKEY=''
TRUE=1
FALSE=0
HOSTIP=''
THEIPS=''

##############################################################
##############                                      ##########
##############             FUNCTIONS                ##########
##############                                      ##########
##############################################################

# little repeater
function repeat () {
	head -c $1 < /dev/zero | tr '\0' $2
}

# little echo tweak
function echoTweak () {
	echoMessage="$1"
	mainlen="$2"
	characters="$3"
	if [ $# -lt 2 ]
	then
		mainlen=60
	fi
	if [ $# -lt 3 ]
	then
		characters='\056'
	fi
	chrlen="${#echoMessage}"
	increaseBy=$((mainlen-chrlen))
	tweaked=$(repeat "$increaseBy" "$characters")
	echo -n "$echoMessage$tweaked"
}

# Set cronjob without removing existing
function setCron () {
	if [ -f $CLIENTHOME/$ACTION.cron ]; then
		echoTweak "Crontab already configured for updates..."
		echo "Skipping"
	else
		echoTweak "Adding crontab entry for continued updates..."
		# check if user crontab is set
		currentCron=$(crontab -u $CLIENTUSER -l 2>/dev/null)
		if [[ -z "${currentCron// }" ]]; then
			currentCron="# SENTINEL crontab settings"
			echo "$currentCron" > $CLIENTHOME/$ACTION.cron
		else	
			echo "$currentCron" > $CLIENTHOME/$ACTION.cron
		fi
		# check if the MAILTO is already set
		if [[ $currentCron != *"MAILTO"* ]]; then
			echo "MAILTO=\"\"" >> $CLIENTHOME/$ACTION.cron
			echo "" >> $CLIENTHOME/$ACTION.cron
		fi
		# check if the @reboot curl -s $CLIENTSCRIPT | sudo bash is already set
		if [[ $currentCron != *"@reboot curl -s $CLIENTSCRIPT | bash"* ]]; then
			echo "@reboot curl -s $CLIENTSCRIPT | bash" >> $CLIENTHOME/$ACTION.cron
		fi
		# check if the @reboot curl -s $CLIENTSCRIPT | sudo bash is already set
		if [[ $currentCron != *"* * * * * curl -s $CLIENTSCRIPT | bash"* ]]; then
			echo "* * * * * curl -s $CLIENTSCRIPT | bash" >> $CLIENTHOME/$ACTION.cron
		fi
		# set the user cron
		crontab -u $CLIENTUSER $CLIENTHOME/$ACTION.cron
		echo "Done"
	fi
}

function getKey () {
	# simple basic random
	echo $(tr -dc 'A-HJ-NP-Za-km-z2-9' < /dev/urandom | dd bs=128 count=1 status=none)
}

function getLocalKey () {
	# Set update key
	if [ -f $CLIENTHOME/$ACTION.key ]; then
		echoTweak "Update key already set!"
		echo "continue"
	else
		echoTweak "Setting the update key..."
		echo $(getKey) > $CLIENTHOME/$ACTION.key
		echo "Done"
	fi

	# Get update key
	CLIENTSERVERKEY=$(<"$CLIENTHOME/$ACTION.key")
}

function setAccessToken () {
	# check if sentinel access was set
	accessToke=$(curl -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.89 Safari/537.36" -H "SENTINEL-KEY: $CLIENTSERVERKEY" -H "SENTINEL-HOST-IP: $HOSTIP" --silent $SENTINELSERVER)

	if [[ "$accessToke" != "$TRUE" ]]; then
		read -s -p "Please enter your SENTINEL access key: " sentinelAccessKey
		echo ""
		echoTweak "One moment while we set your access to the SENTINEL system..."
		resultAccess=$(curl -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.89 Safari/537.36" -H "SENTINEL-TRUST: $sentinelAccessKey" -H "SENTINEL-KEY: $CLIENTSERVERKEY" -H "SENTINEL-HOST-IP: $HOSTIP" --silent $SENTINELSERVER)
		if [[ "$resultAccess" != "$TRUE" ]]; then
			echo "YOUR SENTINEL ACCESS KEY IS INCORRECT! >> $resultAccess"
			exit 1
		fi
		echo "Done"
	else
		echoTweak "Access granted to the SENTINEL system."
		echo "Done"
	fi
}

function getData () {
	# getting the station data
	echoTweak "Getting the station data..."
	THEDATA=$(curl -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.89 Safari/537.36" -H "SENTINEL-KEY: $CLIENTSERVERKEY" -H "SENTINEL-HOST-IP: $HOSTIP"  -H "SENTINEL-GET: 1" --silent $SENTINELSERVER)
	# the data
	if [[ "$THEDATA" == "$FALSE" || ${#THEDATA} -lt 15 ]]; then
		echo "No data FOUND! "
		exit 1
	fi
	echo "Done"
}

function storeLocalData () {
	# load data
	readarray -t rows <<< "$THEDATA"
	for rr in "${rows[@]}" ; do
		row=( $rr )
		if [[ ${#row[@]} == 3 ]]; then
			# start =>>>
			echoTweak "This work needs to still be done...."
		fi
	done
}

##############################################################
##############                                      ##########
##############                MAIN                  ##########
##############                                      ##########
##############################################################
main 
