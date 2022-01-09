#!/bin/bash

echo "Choose the number for the action you want to take"

# Create global variable of current script directory to facilitate creating files and folders on differen locations
export parentDir=$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")

select choice in "Create Database" "List Databases" "Connect To Databases" "Drop Database"
do
case $REPLY in
	1) createdb.sh
		break;;
	2) listdb.sh
		break;;
	3) connectdb.sh
		break;;
    4) dropdb.sh
        break;;
	*) echo "Not a valid option you entered $REPLY, please enter a valid value"
		;;
esac
done
