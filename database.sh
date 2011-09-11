#!/bin/bash   
# By Alexander Zub
# The script gets 2 parameters
# 
# b [m|s|t], backup [master|staging|testing]				Backup a database
# cp [m-s|m-t], copy [master-to-staging|master-to-testing]	Backup both databases, then copy
#
# examples:
## ./database.sh backup staging
# will create a file with staging database
#
## ./database.sh cp m-t
# will create files with master and testing databases and then will copy master database to testing

source database.config


#used in case user make an error in syntax or use 'help' parameter
function showhelp {
	echo "Usage: $0 [COMMAND]"
	printf "  b [m|s|t], backup [master|staging|testing]\t\t\tBackup a database\n"
	printf "  cp [m-s|m-t], copy [master-to-staging|master-to-testing]\tBackup both databases, then copy"
	
	echo
	exit 1
}

#dump function
#first and only parameter may be 'MASTER', 'STAGING' or 'TESTING'
function backup_db {
	
	#getting variables from constants initialized in config file
	DB=`eval echo "$\`echo $1\`_DB"`
	USR=`eval echo "$\`echo $1\`_USR"`
	PASS=`eval echo "$\`echo $1\`_PASS"`
	
	
	DB_FILENAME="${DB}_`date +%Y%m%d%H%M%S`.sql"
	
	#do the magic
	mysqldump -u $USR -p${PASS} --add-drop-table $DB > $DB_FILENAME
	
	if [ $? -eq 0 ]; then
		#returns filename of database dump
		echo "$DB_FILENAME"
		exit 0
	else
		exit 1
	fi
}
 
# the script have to get 2 parameters. Otherwise show help.
if [ -z "$1" ] || [ "$1" == "help" ] || [ -z "$2" ] || [ "$2" == "help" ]; then 
	showhelp
fi

case "$1" in
	
	"b" | "backup" )
	
	case "$2" in
		"m" | "master" )
		STAGE="MASTER"
		;;
		"s" | "staging" )
		STAGE="STAGING"
		;;
		"t" | "testing" )
		STAGE="TESTING"
		;;
		* )
		showhelp
	esac
	
	#filename variable will be empty if backup_db function doesn't return anything (that happens when there is an error)
	FILENAME=`backup_db $STAGE`
	#check if $filename variable is empty
	if [ -z $FILENAME ]; then
		echo "A problem happened writing $STAGE DB to the file $MASTER_DB_FILENAME"
		exit 1
	else
		echo "Successfully wrote $STAGE DB to the file $FILENAME"
		exit 0
	fi
	
	;;
	
	"cp" | "copy" )
	
	case "$2" in
		"m-s" | "master-to-staging" )
		
		#create 2 dumps
		M_DB_FILENAME=`backup_db MASTER`
		if [ -z $M_DB_FILENAME ]; then
			exit 2
		fi
		S_DB_FILENAME=`backup_db STAGING`
		if [ -z $S_DB_FILENAME ]; then
			exit 2
		fi
		
		#do the magic
		mysql -u $STAGING_USR -p${STAGING_PASS} $STAGING_DB < $M_DB_FILENAME
		if [ $? -eq 0 ]; then
			echo "Database successfully copied"
			exit 0
		else
			echo "An problem happened copying db"
			exit 1
		fi
		;;
		"m-t" | "master-to-testing" )
		
		#create 2 dumps
		M_DB_FILENAME=`backup_db MASTER`
		if [ -z $M_DB_FILENAME ]; then
			exit 2
		fi
		T_DB_FILENAME=`backup_db TESTING`
		if [ -z $T_DB_FILENAME ]; then
			exit 2
		fi
		
		#do the magic
		mysql -u $TESTING_USR -p${TESTING_PASS} $TESTING_DB < $M_DB_FILENAME
		if [ $? -eq 0 ]; then
			echo "Database successfully copied"
			exit 0
		else
			echo "An problem happened copying db"
			exit 1
		fi
		;;
		* )
		showhelp
	esac
	;;
esac

exit 0
