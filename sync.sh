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

##############################################################
##############              CHECK                   ##########
##############################################################
command -v rsync >/dev/null 2>&1 || { echo >&2 "We require rsync for this script to run, but it's not installed.  Aborting."; exit 1; }
command -v crontab >/dev/null 2>&1 || { echo >&2 "We require crontab for this script to run, but it's not installed.  Aborting."; exit 1; }
command -v md5sum >/dev/null 2>&1 || { echo >&2 "We require md5sum for this script to run, but it's not installed.  Aborting."; exit 1; }
command -v awk >/dev/null 2>&1 || { echo >&2 "We require awk for this script to run, but it's not installed.  Aborting."; exit 1; }
command -v realpath >/dev/null 2>&1 || { echo >&2 "We require realpath for this script to run, but it's not installed.  Aborting."; exit 1; }
command -v stat >/dev/null 2>&1 || { echo >&2 "We require stat for this script to run, but it's not installed.  Aborting."; exit 1; }

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
ACTIVEUSER=$(whoami)
HOMEPATH=~/
BASENAME=".${ACTION}_${OWNER}"
# set paths
BASEPATH="${HOMEPATH}${BASENAME}"
FOLDERPATH="${BASEPATH}_folders"
EXCLUDEPATH="${BASEPATH}_ex_"
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
	## sync databases if available
	runSync 1 "${DBPATH}"
	## sync folders if available
	runSync 2 "${FOLDERPATH}"
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

### MAIN SYNC ###
function runSync () {
  # check if already set
  if [ -f "$2" ]; then
    # if setup database
    if [ "$1" -eq "1" ]; then
      syncDBs "$2"
    # if setup folders
    elif [ "$1" -eq "2" ]; then
      syncFolders "$2"
    fi
  fi
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

# simple basic random
function getRandom () {
    echo $(tr -dc 'A-HJ-NP-Za-km-z2-9' < /dev/urandom | dd bs=5 count=1 status=none)
}

# md5 strings
function setMD5() {
  echo -n $1 | md5sum | awk '{print $1}'
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
	if [ ! -f "${CRONPATH}" ]; then
    echo ""
    echo -ne "\n Would you like set the cronjob now? [y/N]: "
    read -r answer
    if [[ $answer == "y" ]]; then
      # check if user crontab is set
      currentCron=$(crontab -u $CLIENTUSER -l 2>/dev/null)
      if [[ -z "${currentCron// }" ]]; then
        currentCron="# SYNC WEBSITES crontab settings"
        echo "$currentCron" > "${CRONPATH}"
      else
        echo "$currentCron" > "${CRONPATH}"
      fi
      # check if the MAILTO is already set
      if [[ $currentCron != *"MAILTO"* ]]; then
        echo "MAILTO=\"\"" >> "${CRONPATH}"
        echo "" >> "${CRONPATH}"
      fi
      # get the Source Database IP/Domain
      echo -e "\n ################################################################################################"
      echo -ne " ##  Add the CRON TIMER here so you sync will run every day at 4am.\n"
      echo -ne " ##  That will look like our example below, see https://crontab.guru/#0_4_*_*_* for more details.\n"
      echo -e " ################################################################################################"
      read -e -p " ##  Example (0 4 * * *): " -i "0 4 * * *" INPUT_CRON_CICLE
      # check if the @reboot curl -s $SCRIPTURL | sudo bash is already set
      if [[ $currentCron != *"${INPUT_CRON_CICLE} curl -s $SCRIPTURL | bash"* ]]; then
        echo "${INPUT_CRON_CICLE} curl -s $SCRIPTURL | bash" >> "${CRONPATH}"
      fi
      # set the user cron
      crontab -u $ACTIVEUSER "${CRONPATH}"
      # close the block
      echo -e "\n ################################################################################################"
    else
      # to avoid asking again
      echo "See ${CRONPATH} for more details!"
      echo '# Do not remove this file!' > "${CRONPATH}"
      echo '# Please set your cronjob manually, with the following details' >> "${CRONPATH}"
      echo "# 0 4 * * * curl -s $SCRIPTURL | bash" >> "${CRONPATH}"
    fi
	fi
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
		echo -ne " # Example (/home/username_b): "
		read -r INPUT_TARGET_PATH
		# check that we have a target path
		if [ ! -d "$INPUT_TARGET_PATH" ]; then
			echo -ne "\n YOU MUST ADD A TARGET PATH!\n\n" ;
			# remove the file
			rm "$1"
			# start again
			exit 1
		fi
		# must set realpath
	  source_folder=$(realpath -s "${INPUT_SOURCE_PATH}")
	  target_folder=$(realpath -s "${INPUT_TARGET_PATH}")
		# add to the file
		echo "${source_folder}	${target_folder}" >> "$1"
    # get hash
    HASH=$(setMD5 "${source_folder}${target_folder}")
    # check if exclusion is needed
		getExcluded "${EXCLUDEPATH}${HASH}"
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

### setup sync folders file ###
function getExcluded () {
	# default it no to run setup
	GETTING=0
  echo ""
  echo -ne "\n Would you like to add excluded files/folders? [y/N]: "
  read -r answer
  if [[ $answer == "y" ]]; then
    # start exclution
    echo -ne "\n See for more details https://linuxize.com/post/how-to-exclude-files-and-directories-with-rsync/\n"
    # set checker to get more
    GETTING=1
  fi
	# start setup
	while [ "$GETTING" -eq "1" ]
	do
		# get source folder path path
		echo -ne "\n  Add file or folder to exclude\n"
		echo -ne " # Example (configuration.php or administrator/*): "
		read -r INPUT_EXCLUDE
		# add to file
		echo "${INPUT_EXCLUDE}" >> "$1"
		# check if another should be added
		echo ""
		echo -ne "\n Would you like to add another exclusion? [y/N]: "
		read -r answer
		if [[ $answer != "y" ]]; then
			# end the loop
			GETTING=0
		fi
	done
}

### sync databases ###
function syncDBs (){
	while IFS=$'\t' read -r -a databases
	do
		[[ "$databases" =~ ^#.*$ ]] && continue
		#  SOURCE_DBSERVER	SOURCE_DATABASE	SOURCE_USER	SOURCE_PASS	TARGET_DBSERVER	TARGET_DATABASE	TARGET_USER	TARGET_PASS
		syncDB "${databases[0]}" "${databases[1]}" "${databases[2]}" "${databases[3]}" "${databases[4]}" "${databases[5]}" "${databases[6]}" "${databases[7]}"
	done < $1
}

### sync database ###
function syncDB (){
  # give the user log data
	echoTweak "Syncing databases of [$2] with [$6]..."
  #	local source_server="$1"
  #	local source_db="$2"
  #	local source_user="$3"
  #	local source_pass="$4"
  #	local target_server="$5"
  #	local target_db="$6"
  #	local target_user="$7"
  #	local target_pass="$8"
  # move tables from one database to the other
	mysqldump --opt -q --host="$1" --user="$3" --password="$4" "$2" | \
  mysql --host="$5" --user="$7" --password="$8" -C "$6"
  # we may want to look at passing the password more securly (TODO)
	# done :)
	echo "done"
}

### sync folders ###
function syncFolders (){
	while IFS=$'\t' read -r -a folders
	do
		[[ "$folders" =~ ^#.*$ ]] && continue
		# SOURCE_PATH	TARGET_PATH
		syncFolder "${folders[0]}" "${folders[1]}"
	done < $1
}

### sync folder ###
function syncFolder (){
	local source_folder="$1"
	local target_folder="$2"
  # get the owners
	local source_owner=$(stat -c '%U' "${source_folder}")
	local target_owner=$(stat -c '%U' "${target_folder}")
  # give the user log data
	echoTweak "Syncing folders of [${source_owner}] with [${target_owner}]..."
	# get hash
	HASH=$(setMD5 "${source_folder}${target_folder}")
	# check if we have exclude file
	local tmpName=$(getRandom)
	local tmpPath="${HOMEPATH}.${tmpName}"
	# local exclude=''
	if [ -f "${EXCLUDEPATH}${HASH}" ]; then

##########################################################################
# I tried doing this exclude with rsync but it just does not work (TODO)
#	  while IFS= read -r line; do
#      exclude+=" --exclude '${line}'"
#    done < "${EXCLUDEPATH}${HASH}"
# IF YOU CAN HELP LET ME KNOW
#########################################################################

    # make tmp dir
    mkdir "$tmpPath"
    # move file/folders out to tmp folder
    for line in $(cat ${EXCLUDEPATH}${HASH}); do mv -f "${target_folder}/${line}" "$tmpPath"; done
	fi
	# we use rsync to do all the sync work (very smart)
  rsync -qrd --delete "${source_folder}/" "${target_folder}"

##########################################################################
# I tried doing this exclude with rsync but it just does not work (TODO)
#	if [ ! ${#exclude} -ge 2 ]; then
#	  rsync -qrd --delete "${source_folder}/" "${target_folder}"
#	else
#	  rsync -qrd $exclude --delete "${source_folder}/" "${target_folder}"
#	fi
# IF YOU CAN HELP LET ME KNOW
#########################################################################

	# move the files back
	if [ -f "${EXCLUDEPATH}${HASH}" ]; then
    # move file/folders out
    for line in $(cat ${EXCLUDEPATH}${HASH}); do mv -f "$tmpPath/$line" "${target_folder}"; done
    # remove tmp dir
    rm -r "$tmpPath"
  fi

	# run chown again (will only work if script run as root)
	chown -R "${target_owner}":"${target_owner}" "${target_folder}/"*
	# done :)
	echo "done"
}

##############################################################
##############                                      ##########
##############                MAIN                  ##########
##############                                      ##########
##############################################################
main 
