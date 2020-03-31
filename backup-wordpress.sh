#!/bin/sh
##  Backup to Google Drive. Author: Oleksii Pylypchuk 
##  github: https://github.com/alpi-ua/backup-site/ 

site=site.name
workdir=/path/to/backup_dir
sitedir=/path/to/$site
mysqldb=dbname
mysqluser=username
mysqlpass=dbpassword
email=error_report@email.com
backuplog=/path/to/backup.log

echo `date` "Starting..."
echo `date` "Backuping database"

    mysqldump -u "$mysqluser" -p"$mysqlpass" "$mysqldb" > "$workdir"/"$site"/"$site.sql"

    [ -f "$workdir"/"$site.sql" ] &&
	du -h "$workdir"/"$site".sql &&
        echo `date` "Database backup created" || echo `date` "Failed to create a database backup"

echo ""
echo `date` "Moving the old backup"
    mv "$workdir"/"$site"/"$site".zip "$workdir"/"$site"/"$site".zip.old

echo ""
echo `date` "Archiving files and database"

zip -rq "$workdir"/"$site"/"$site".zip -x="$sitedir"/wp-content/cache/min/1/\* -x="$sitedir"/wp-content/cache/wp-rocket/\* "$sitedir"/ "$workdir"/"$site"/"$site".sql
    
    returncode=$?    
    if [ "$returncode" -ne 0 ]; then
	echo "Error when creating "$site" archieve. ZIP returned code $returncode" | mail -s "Error creating backup "$site"" -a "$backuplog" "$email" 
 	echo `date` "Error creating zip file. Oldone "$workdir"/"$site"/"$site".zip.old will stay"       
	rm -rf "$workdir"/"$site"/"$site".zip
    else
    [ -f ""$workdir"/"$site"/"$site".zip" ] &&
        du -h "$workdir"/"$site"/"$site".zip &&
	rm -rf "$workdir"/"$site"/"$site".sql &&
	rm -rf "$workdir"/"$site"/"$site".zip.old && 
	echo `date` "Archive created. Old archive deleted" || echo `date` "ERROR CREATING ARCHIVE"
    fi

echo ""
echo `date` "Starting download to the google disk"

"$workdir"/drive push -ignore-conflict -ignore-name-clashes -quiet "$workdir"/"$site"/"$site".zip

echo "Download complete"
echo "`date`"
