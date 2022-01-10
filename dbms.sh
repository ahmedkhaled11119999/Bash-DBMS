#!/bin/bash

# --------------------------------------
# General working instructions (mutable)
# --------------------------------------
#
# NAMING 
# ------
# Global vriables are typed in all-cabs in snake_case style, ex: $SCRIPT_PARENT_DIR
# local vriables are typed in all-lowercase in snake_case style, ex: $table_name
# Function names are types in camelCase style, ex: createTable
# 
# PROJECT FILE STRUCTURE
# ----------------------
# 1. First, global variable are declared on the beginning of the file
# 2. Then, comes table operations section (createTable, listTables, dropTable,..)
#	a. Starting with operatoins functions. (Done: createTable, listTables, dropTable)
#	b. At the end of the section comes tablesOperationsMenu function, which is responsible for displaying available operations on a table for a user (triggered on connecting to database)
# 3. At last, comes database operations section (createdb, listbd, connectdb, dropdb)
#	a. Starting with operatoins functions. (Done(all): createdb, listbd, connectdb, dropdb)
#	b. At the end of the section comes mainMenu function, which is responsible for displaying available operations on a database for a user (triggered on initializing the script)


echo "Choose the number for the action you want to take"

# Create global variable of current script directory to facilitate creating files and folders on differen locations
SCRIPT_PARENT_DIR=$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")

# ------------------------------------------------------------------------------
# Functions specialized in operations on tables (after connecting to a database)
# ------------------------------------------------------------------------------

# Create a new table in selected database
function createTable {
	# To create table file
	echo "Type table name:"
	read table_name
	table_file=$1/$table_name
	touch $table_file

	# To create table head
	echo "Enter your columns sparated by ':', ex => col1:col2:col3"
	read table_head
	echo $table_head > $table_file
}

# List all available tables in selected databases
function listTables {
	echo "List of all tables in this database:"
	ls $1
}

# Drop a table by removing the refering file
function dropTable {
	echo "Enter table name:"
	read table_name

	table_file=$1/$table_name
	if [ -f  $table_file ]
	then
		echo "Are you sure you want to drop this table? (y/yes) if you are sure or (n/no) to cancel"
		read consent

		case $consent in
			y | Y | yes | Yes | YES) rm $table_file; echo "Table was dropped successfully"
				;;
			n | N | no | No | NO) echo "dropping process terminated"
				;;
			*) echo "Please enter a valid answer"
				;;
		esac
	else
		echo "No such table"
	fi

}

# ---------------------------------------------------
# Script database menu (controlling tables in databa)
# ---------------------------------------------------
function tablesOperationsMenu {
	select choice in "Create Table" "List Tables" "Drop Table" "Insert into Table" "Select From Table" "Delete From Table" "Update Table"
	do
	case $REPLY in
		1) createTable $1
			break;;
		2) listTables $1
			break;;
		3) dropTable $1
			break;;
		4) insertToTable $1
			break;;
		5) selectFromTable $1
			break;;
		6) deleteFromTable $1
			break;;
		7) updateTable $1
			break;;
		*) echo "Not a valid option you entered $REPLY, please enter a valid value"
			;;
	esac
	done
}

# -----------------------------------------------
# Functions specialized in operations on database
# -----------------------------------------------

# Create a new databae
function createdb {
	echo "Type database name:"
	read database_name

	mkdir $SCRIPT_PARENT_DIR/database/$database_name
}

# List all available databases
function listdb {
	echo "List of all databases you have:"

	ls $SCRIPT_PARENT_DIR/database/
}

# Connect to a database (switch to a directory within the database directory)
function connectdb {
	echo "Type database name you would like to connect to:"
	read database_name

	selected_database=$SCRIPT_PARENT_DIR/database/$database_name
	cd $selected_database
	echo "You are now connected to $database_name database at $PWD"
	tablesOperationsMenu $selected_database
}

# Drop a database by removing the refering directory
function dropdb {
	echo "Enter database name:"
	read database_name

	database_dir=$SCRIPT_PARENT_DIR/database/$database_name
	if [ -d  $database_dir ]
	then
		echo "Are you sure you want to drop this database? (y/yes) if you are sure or (n/no) to cancel"
		read consent

		case $consent in
			y | Y | yes | Yes | YES) rm -r $database_dir; echo "Database dropped successfully"
				;;
			n | N | no | No | NO) echo "dropping process terminated"
				;;
			*) echo "Please enter a valid answer"
				;;
		esac
	else
		echo "No such database"
	fi
}

# ----------------------------------------
# Script main menu (controlling databases)
# ----------------------------------------
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
