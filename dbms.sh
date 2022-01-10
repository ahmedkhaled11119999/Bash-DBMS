#!/bin/bash

echo "Choose the number for the action you want to take"

# Create global variable of current script directory to facilitate creating files and folders on differen locations
SCRIPT_PARENT_DIR=$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")

# -----------------------------------------------
# Functions specialized in operations on tables (after connecting to a database)
# -----------------------------------------------

# ----------------
# Script database menu (controlling tables in databa)
# ----------------
function tables_operations_menu {
	select choice in "Create Table" "List Tables" "Drop Table" "Insert into Table" "Select From Table" "Delete From Table" "Update Table"
	do
	case $REPLY in
		1) create_table $1
			break;;
		2) list_tables $1
			break;;
		3) drop_table $1
			break;;
		4) insert_to_table $1
			break;;
		5) select_from_table $1
			break;;
		6) delete_from_table $1
			break;;
		7) update_table $1
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
	tables_operations_menu $selected_database
}

# Drop a database by removing the refering directory
function dropdb {
	echo "Enter database name:"
	read database_name

	echo "Are you sure you want to drop this database? (y/yes) if you are sure or (n/no) to cancel"
	read consent

	case $consent in
		y | yes) rm -r $SCRIPT_PARENT_DIR/database/$database_name; echo "Database dropped successfully"
			;;
		n | no) echo "dropping process terminated"
			;;
		*) echo "Please enter a valid answer"
			;;
	esac
}

# ----------------
# Script main menu (controlling databases)
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
