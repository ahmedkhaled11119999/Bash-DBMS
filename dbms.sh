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


# Create global variable of current script directory to facilitate creating files and folders on differen locations
SCRIPT_PARENT_DIR=$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")

# ------------------------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------------------------

#Takes 3 parameters :
# $1 -> the column value we want to check for its type , $2 -> the column number which we will save the value , $3 -> table file path
# returns true if the value is num or string and matches its column type and returns false in any other case. 
function isValueMatchingColumn {
	supposed_type=`sed -n 2p $3 | cut -d: -f$2`
	num_regexp="^[+-]?[0-9]+([.][0-9]+)?$"
	if [[ $1 =~ $num_regexp && $supposed_type == num ]] || [[ ! $1 =~ $num_regexp && $supposed_type == string ]]; then
	echo true
	else
	echo false
	fi
}

#Takes 1 parameter :
# $1 -> the data type to be validated
# return true if the data type is num or string , returns false in other cases.
function isTypeValid {
		if [[ $1 == num ]] || [[ $1 == string ]]; then
		echo true
		else
		echo false
		fi
}

#$1-> condition
#$2-> table file
function whereClause {
	IFS="=" read -a cols <<< "$1";
	col_name=${cols[0]};
	col_value=${cols[1]};
	grep -n "$col_value" | while IFS="" read -r p || [ -n "$p" ]
	do 
	printf '%s\n' "$p" | cut -f1 -d:
	done < $2 | while IFS="" read -r p || [ -n "$p" ]
	do
	#delete where
	sed -i "$p d" $2
  # printf '%s\n' "$p"
	done
}

#Takes 1 parameter :
# $1 -> the database row
# returns the pk column position if exists, 0 in other cases.
function findPrimaryKey {
	IFS=':' read -a splitted_inputs <<< "$1";
	for ((k=0; k<${#splitted_inputs[@]}; k++)) do
	if echo ${splitted_inputs[k]} | grep -q "^^"; then
  return $((k+1))
	else
  if [[ $(( ${#splitted_inputs[@]}-1 )) == $k ]]; then
	return 0
	fi
	fi
	done
}

#Takes 2 parameters :
# $1 -> line 1 of table file , $2 -> user input
# returns 1 if the pk column in the user input isn't null, 0 in other cases
function validateDataPrimaryKey {
	findPrimaryKey $1
	line_one_pk_index=$?
	IFS=':' read -a splitted_inputs <<< "$2";
	if [[ -z ${splitted_inputs[ $((line_one_pk_index-1)) ]} ]];then
	return 0
	else
	return 1
	fi
}

#Takes 1 parameter :
# $1 -> user row input
# returns 0 if any column in row violates the type, 1 in other cases.
function validateRowTypes {
	IFS=':' read -a splitted_inputs <<< "$1";
	for ((i=0; i<${#splitted_inputs[@]}; i++)) do
	output=$(isTypeValid ${splitted_inputs[i]})
	if  [[ $output == false ]]; then
	return 0
	else
	if [[ $(( ${#splitted_inputs[@]}-1 )) == $i ]]; then
	return 1
	fi
	fi
	done
}

# ------------------------------------------------------------------------------
# Functions specialized in operations on tables (after connecting to a database)
# ------------------------------------------------------------------------------

# Create a new table in selected database
function createTable {
	# To create table file
	echo "Type table name:"
	read table_name
	table_file=$1/$table_name
	if [ -f $table_file ]; then
	printf 'This table already exists, if you wish to insert into it choose option 4\n'
	else
	touch $table_file
	# To create table head
	while true
	do
	printf 'Enter your columns seperated by ':', and the primary key perceded by ^ ex => ^col1:col2:col3\n'
	read table_columns
	num_of_cols=`awk -F":" '{print NF}' <<< "${table_columns}"`
	findPrimaryKey $table_columns
	fpk_return_val=$?
	if  [[ $fpk_return_val == 0 ]]; then
	printf "\nError: couldn't find pk. Please try again and add a primary key.\n"
	else
	echo $table_columns > $table_file
	break;
	fi
	done
	while true
	do
	printf 'Enter your columns data types in the same format.\navailable data types: num , string\n'
	read table_types
	num_of_types=`awk -F":" '{print NF}' <<< "${table_types}"`
	if [[ $num_of_types != $num_of_cols ]]; then
	printf "Error: Your datatypes count is '$num_of_types' \nwhich is not equal to your columns count '$num_of_cols' \n"
	continue
	fi
	validateRowTypes $table_types
	vrt_return_val=$?
	if  [[ $vrt_return_val == 0 ]]; then
	printf "Error: a datatype you entered is not num neither string, please try again with the correct data types.\n"
	else
	echo $table_types >> $table_file;
	printf "Table $table_name created successfully\n";
	break;
	fi
	done
	fi
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

#Inserting into a certain table
function insertToTable {
	printf "Enter table name:"
	read table_name
	table_file=$1/$table_name
	if [ -f  $table_file ]; then
	printf 'Enter the number of the record you wish to enter:'
	records_num_regex='^[0-9]+$'
	while true 
	do
	read records_num
	if ! [[ $records_num =~ $records_num_regex ]]; then
	printf 'Please enter a valid number:'
	else
	break;
	fi
	done
	printf 'Enter your columns seperated by ":", ex => col1:col2:col3\n'
	printf "this is your columns names: `sed -n 1p $table_file` \n"
	printf "this is your columns datatypes: `sed -n 2p $table_file` \n"
	for ((i=1;i<=$records_num;i++)) do
	while true
	do
	printf "\nRecord number $i : \n"
	read record
	first_line=`sed -n 1p $table_file`
	validateDataPrimaryKey $first_line $record
	is_data_pk_valid=$?
	if [[ $is_data_pk_valid == 1 ]]; then
	IFS=':' read -a splitted_record <<< "$record"
	for ((j=0; j<${#splitted_record[@]}; j++)) do
	column_index=$((j+1))
	if [[ $( isValueMatchingColumn ${splitted_record[j]} $column_index $table_file ) == true ]]; then
	if [[ $j -eq  $((${#splitted_record[@]}-1)) ]]; then
	echo $record >> $table_file ;
	break 2
	fi
	else
	echo "Error: Your entry datatype at `sed -n 1p $table_file | cut -d: -f$column_index` column doesn't match the column data type. please re-enter this record correctly."
	break
	fi
  done
	else
	printf 'Error: Primary Key cannot be null. \nPlease enter this record again correctly. \n'
	fi
	done
	done
	else
	printf "$table_name doesn't exist. if you wish to create it choose option 1"
	fi
}

function selectFromTable {
	while true
	do
		echo "Enter a table to select from"
		read table_name

		table_dir=$1
		table_file=$table_dir/$table_name
		if [ -f $table_file ]
		then
			echo "What do you want to select? (* For all columns or enter column name)"
			read selection

			# echo "Do you have any conditions for this selection?"
			# read conditions

			table_head=`sed -n '1p' $table_file`
			table_data=`sed -n '3,$p' $table_file | sed -n "/$selection/p"`

			# Manage selection (equiv to SELECT clause in sql)
			if [ "$selection" == "*" ]
			then
				# Display full table (equiv to SELECT * clause in sql)
				cat $table_file
				break;
			else
				IFS=":" read -a cols <<< "$table_head"
				IFS=', ' read -r -a selected_cols <<< "$selection"
				selected=""

				declare -i col_exists
				declare -i keep_decline
				for ((c=0; c<${#selected_cols[@]}; c++))
				do
					search_line=`echo $table_head | grep "${selected_cols[c]}"`

					if [[ -n $search_line ]]
					then
						# If one of the columns does not exist return 0 anyway
						if [[ $keep_decline -ne 1 ]]
						then
							col_exists=1
						fi
					else
						col_exists=0
						keep_decline=1
					fi
				done

				if [[ -n $selection  && -n $col_exists && $col_exists -eq 1 ]]
				then
					for ((i=0; i<${#selected_cols[@]}; i++))
					do
						for ((j=0; j<${#cols[@]}; j++))
						do
							if [ ${cols[j]} == ${selected_cols[i]} ]
							then
								col_num=$((j+1));
								if [[ -n $selected ]]
								then
									selected="$selected,$col_num"
								else
									selected=$col_num
								fi
							fi
						done
					done
					sed  '1,2d' $table_file | cut -d: -f$selected
					break;
				else
					echo "There is no such column"
				fi

				# whereClause $conditions
			fi
		else
			echo "There is no such table"
		fi
	done
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
	if [ -d $SCRIPT_PARENT_DIR/database ]; then
	mkdir $SCRIPT_PARENT_DIR/database/$database_name
	else
	mkdir $SCRIPT_PARENT_DIR/database
	mkdir $SCRIPT_PARENT_DIR/database/$database_name
	fi
}
# List all available databases
function listdb {
	if [ -d $SCRIPT_PARENT_DIR/database ]; then
	echo "List of all databases you have:"
	ls $SCRIPT_PARENT_DIR/database/
	else
	echo "You have never created a database, please choose option 1 to create one"
	fi
}

# Connect to a database (switch to a directory within the database directory)
function connectdb {
	echo "Type database name you would like to connect to:"
	read database_name
	selected_database=$SCRIPT_PARENT_DIR/database/$database_name
	if [ -d $selected_database ]; then
	cd $selected_database
	echo "You are now connected to $database_name database at $PWD"
	tablesOperationsMenu $selected_database
	else
	echo "There is no such database called $database_name to connect to it"
	fi
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
function mainMenu {
	echo "Choose the number for the action you want to take"

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
}

# Initialize script
mainMenu