#!/bin/bash
#/--------------------------------------------------------------------------------------------------------|  www.vdm.io  |------/
#
#	@version		1.0.0
#	@build			6th Marh, 2020
#	@package		sync websites
#	@author			Llewellyn van der Merwe <https://github.com/Llewellynvdm>
#	@copyright	Copyright (C) 2020. All Rights Reserved
#	@license		GNU/GPL Version 2 or later - http://www.gnu.org/licenses/gpl-2.0.html
#
#/-----------------------------------------------------------------------------------------------------------------------------/

############################ GLOBAL ##########################
ACTION="sync"
OWNER="namibia"
REPONAME="demo-sync"
######### DUE TONOT BEING ABLE TO INCLUDE DYNAMIC ###########

#################### UPDATE TO YOUR NEEDS ####################
##############################################################
##############                                      ##########
##############               CONFIG                 ##########
##############                                      ##########
##############################################################
REPOURL="https://raw.githubusercontent.com/${OWNER}/${REPONAME}/master/"

##############################################################
##############                                      ##########
##############              DEFAULTS                ##########
##############                                      ##########
##############################################################
Datetimenow=$(TZ=":ZULU" date +"%m/%d/%Y @ %R (UTC)" )
SCRIPTURL="${REPOURL}$ACTION.sh"
HOMEPATH=~/
NAME=".${ACTION}_${OWNER}"
# set paths
BASEPATH="${HOMEPATH}/${NAME}"
FOLDERPATH="${BASEPATH}_folders"
DBPATH="${BASEPATH}_dbs"
CRONPATH="${BASEPATH}.cron"

##############################################################
##############                                      ##########
##############                MAIN                  ##########
##############                                      ##########
##############################################################
function main () {
	## set time for this run
	echoTweak "$ACTION on $Datetimenow"
	echo "started"
	## make sure cron is set
	setCron
	## check if sync databases are setup
	runSetup 1 "${DBPATH}"
	## check if sync folders are setup
	runSetup 2 "${FOLDERPATH}"
}

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
	if [ -f "${CRONPATH}" ]; then
		echoTweak "Crontab already configured for updates..."
		echo "Skipping"
	else
		echoTweak "Adding crontab entry for continued updates..."
		# check if user crontab is set
		currentCron=$(crontab -u $CLIENTUSER -l 2>/dev/null)
		if [[ -z "${currentCron// }" ]]; then
			currentCron="# SENTINEL crontab settings"
			echo "$currentCron" > "${CRONPATH}"
		else	
			echo "$currentCron" > "${CRONPATH}"
		fi
		# check if the MAILTO is already set
		if [[ $currentCron != *"MAILTO"* ]]; then
			echo "MAILTO=\"\"" >> "${CRONPATH}"
			echo "" >> "${CRONPATH}"
		fi
		# check if the @reboot curl -s $SCRIPTURL | sudo bash is already set
		if [[ $currentCron != *"0 4 * * * curl -s $SCRIPTURL | bash"* ]]; then
			echo "0 4 * * * curl -s $SCRIPTURL | bash" >> "${CRONPATH}"
		fi
		# set the user cron
		crontab -u $CLIENTUSER "${CRONPATH}"
		echo "Done"
	fi
}

### run the sync websites method ###
function syncWebsites () {
  echo -ne "\n  soon..................\n"
}

### setup sync databases file ###
function getSyncDBs () {
	# start building the database details
	echo "# SOURCE_DBSERVER	SOURCE_DATABASE	SOURCE_USER	SOURCE_PASS	TARGET_DBSERVER	TARGET_DATABASE	TARGET_USER	TARGET_PASS" > "$1"
	# default it no to run setup
	GETTING=0
  echo ""
  echo -ne "\n Would you like to add a set of sync databases? [y/N]: "
  read -r answer
  if [[ $answer == "y" ]]; then
    # start Database tutorial
    echo -ne "\n  RUNNING DATABASE SETUP\n"
    # set checker to get more
    GETTING=1
  fi
	# start setup
	while [ "$GETTING" -eq "1" ]
	do
		# get the Source Database IP/Domain
		echo -ne "\n  Set the Source Database IP/Domain\n"
		read -e -p " # Example (127.0.0.1 | localhost): " -i "127.0.0.1" INPUT_SOURCE_DBSERVER
		# check that we have a string
		if [ ! ${#INPUT_SOURCE_DBSERVER} -ge 2 ]; then
			echo -ne "\n YOU MUST ADD A SOURCE DATABASE IP/DOMAIN!\n\n" ;
			# remove the file
			rm "$1"
			# start again
			exit 1
		fi
		# get the Source Database Name
		echo -ne "\n  Set the Source Database Name\n"
		echo -ne " # Example (database_name): "
		read -r INPUT_SOURCE_DATABASE
		# check that we have a string
		if [ ! ${#INPUT_SOURCE_DATABASE} -ge 2 ]; then
			echo -ne "\n YOU MUST ADD A SOURCE DATABASE NAME!\n\n" ;
			# remove the file
			rm "$1"
			# start again
			exit 1
		fi
		# get the Source Database User Name
		echo -ne "\n  Set the Source Database User Name\n"
		echo -ne " # Example (database_user): "
		read -r INPUT_SOURCE_USER
		# check that we have a string
		if [ ! ${#INPUT_SOURCE_USER} -ge 2 ]; then
			echo -ne "\n YOU MUST ADD A SOURCE DATABASE USER NAME!\n\n" ;
			# remove the file
			rm "$1"
			# start again
			exit 1
		fi
		# get the Source Database User Password
		echo -ne "\n  Set the Source Database User Password\n"
		echo -ne " # Example (realy..): "
		read -s INPUT_SOURCE_PASSWORD
		# check that we have a string
		if [ ! ${#INPUT_SOURCE_PASSWORD} -ge 2 ]; then
			echo -ne "\n YOU MUST ADD A SOURCE DATABASE USER PASSWORD!\n\n" ;
			# remove the file
			rm "$1"
			# start again
			exit 1
		fi
		# get the Target Database IP/Domain
		echo -ne "\n  Set the Target Database IP/Domain\n"
		read -e -p " # Example (127.0.0.1 | localhost): " -i "127.0.0.1" INPUT_TARGET_DBSERVER
		# check that we have a string
		if [ ! ${#INPUT_TARGET_DBSERVER} -ge 2 ]; then
			echo -ne "\n YOU MUST ADD A TARGET DATABASE IP/DOMAIN!\n\n" ;
			# remove the file
			rm "$1"
			# start again
			exit 1
		fi
		# get the Target Database Name
		echo -ne "\n  Set the Target Database Name\n"
		echo -ne " # Example (database_name): "
		read -r INPUT_TARGET_DATABASE
		# check that we have a string
		if [ ! ${#INPUT_TARGET_DATABASE} -ge 2 ]; then
			echo -ne "\n YOU MUST ADD A TARGET DATABASE NAME!\n\n" ;
			# remove the file
			rm "$1"
			# start again
			exit 1
		fi
		# get the Target Database User Name
		echo -ne "\n  Set the Target Database User Name\n"
		echo -ne " # Example (database_user): "
		read -r INPUT_TARGET_USER
		# check that we have a string
		if [ ! ${#INPUT_TARGET_USER} -ge 2 ]; then
			echo -ne "\n YOU MUST ADD A TARGET DATABASE USER NAME!\n\n" ;
			# remove the file
			rm "$1"
			# start again
			exit 1
		fi
		# get the Target Database User Password
		echo -ne "\n  Set the Target Database User Password\n"
		echo -ne " # Example (realy..): "
		read -s INPUT_TARGET_PASSWORD
		# check that we have a string
		if [ ! ${#INPUT_TARGET_PASSWORD} -ge 2 ]; then
			echo -ne "\n YOU MUST ADD A TARGET DATABASE USER PASSWORD!\n\n" ;
			# remove the file
			rm "$1"
			# start again
			exit 1
		fi
		# add to the file
		echo "${INPUT_SOURCE_DBSERVER}	${INPUT_SOURCE_DATABASE}	${INPUT_SOURCE_USER}	${INPUT_SOURCE_PASSWORD}	${INPUT_TARGET_DBSERVER}	${INPUT_TARGET_DATABASE}	${INPUT_TARGET_USER}	${INPUT_TARGET_PASSWORD}" >> "$1"
		# check if another should be added
		echo ""
		echo -ne "\n Would you like to add another set of sync databases? [y/N]: "
		read -r answer
		if [[ $answer != "y" ]]; then
			# end the loop
			GETTING=0
		fi
	done
}

### setup sync folders file ###
function getSyncFolders () {
	# start building the website folder details
	echo "# SOURCE_PATH	TARGET_PATH" > "$1"
	# default it no to run setup
	GETTING=0
  echo ""
  echo -ne "\n Would you like to add a set of sync folders? [y/N]: "
  read -r answer
  if [[ $answer == "y" ]]; then
    # start Folder tutorial
    echo -ne "\n  RUNNING FOLDER SETUP\n"
    # set checker to get more
    GETTING=1
  fi
	# start setup
	while [ "$GETTING" -eq "1" ]
	do
		# get source folder path path
		echo -ne "\n  Set the Source Folder Path\n"
		echo -ne " # Example (/home/username_a/): "
		read -r INPUT_SOURCE_PATH
		# check that we have a source path
		if [ ! -d "$INPUT_SOURCE_PATH" ]; then
			echo -ne "\n YOU MUST ADD A SOURCE PATH!\n\n" ;
			# remove the file
			rm "$1"
			# start again
			exit 1
		fi
		# get target folder path path
		echo -ne "\n  Set the Target Folder Path\n"
		echo -ne " # Example (/home/username_b/): "
		read -r INPUT_TARGET_PATH
		# check that we have a target path
		if [ ! -d "$INPUT_TARGET_PATH" ]; then
			echo -ne "\n YOU MUST ADD A TARGET PATH!\n\n" ;
			# remove the file
			rm "$1"
			# start again
			exit 1
		fi
		# add to the file
		echo "${INPUT_SOURCE_PATH}	${INPUT_TARGET_PATH}" >> "$1"
		# check if another should be added
		echo ""
		echo -ne "\n Would you like to add another set of sync folders? [y/N]: "
		read -r answer
		if [[ $answer != "y" ]]; then
			# end the loop
			GETTING=0
		fi
	done
}

### MAIN SETUP ###
function runSetup () {
  # check if already set
  if [ ! -f "$2" ]; then
    # if setup database
    if [ "$1" -eq "1" ]; then
      getSyncDBs "$2"
    # if setup folders
    elif [ "$1" -eq "2" ]; then
      getSyncFolders "$2"
    fi
  fi
}

##############################################################
##############                                      ##########
##############                MAIN                  ##########
##############                                      ##########
##############################################################
main 
