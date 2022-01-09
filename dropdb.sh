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

