#!/bin/bash

echo "Choose the number for the action you want to take"

# Create global variable of current script directory to facilitate creating files and folders on differen locations
parentDir=$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")

# -----------------------------------------------
# Functions specialized in operations on database
# -----------------------------------------------

# Create a new databae
function createdb {
	echo "Type database name:"
	read database_name

	mkdir $parentDir/database/$database_name
}

# List all available databases
function listdb {
	echo "List of all databases you have:"

	ls $parentDir/database/
}

# Connect to a database (switch to a directory within the database directory)
function connectdb {
	echo "Type database name you would like to connect to:"
	read database_name

	cd $parentDir/database/$database_name
	echo "You are now connected to $database_name database at $PWD"
}

# Drop a database by removing the refering directory
function dropdb {
	echo "Enter database name:"
	read database_name

	echo "Are you sure you want to drop this database? (y/yes) if you are sure or (n/no) to cancel"
	read consent

	case $consent in
		y | yes) rm -r $parentDir/database/$database_name
			;;
		n | no)
			;;
		*) echo "Please enter a valid answer"
			;;
	esac
}

# ----------------
# Script main menu
# ----------------
select choice in "Create Database" "List Databases" "Connect To Databases" "Drop Database"
do
case $REPLY in
	1) createdb
		break;;
	2) listdb
		break;;
	3) connectdb
		break;;
    4) dropdb
        break;;
	*) echo "Not a valid option you entered $REPLY, please enter a valid value"
		;;
esac
done
