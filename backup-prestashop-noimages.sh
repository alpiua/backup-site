#!/bin/sh

##  Backup to Google Drive. Author: Oleksii Pylypchuk 
##  github: https://github.com/alpi-ua/backup-site/
##  
##  This script is designed to upload daily backup of the wordpress site to the google drive
##  In case of fail email is sending to admin via mailx with log attached
##  You should download https://github.com/odeke-em/drive and specify backup.log, email for using this script
##
##  The crontab record is
##  10 5 * * * /path/to/script/backup-wordpress.sh > /path/to/backup.log 2>&1
##  Make sure the owner of the backup.log is the same who is running cron job

DATE_FORMAT='+[%d-%m-%Y] %H:%M:%S'

site= site.com
workdir= /var/backupdir
sitedir= /var/www/sitedir

mysqldb    = db_name
mysqluser  = db_user
mysqlpass  = db_password

backuplog=/path/to/backup.log
email=send@email.com

echo $(date "$DATE_FORMAT") "| Starting..."

[ -f ""$workdir"/"$site"/database.zip" ] && mv "$workdir"/"$site"/database.zip "$workdir"/"$site"/database.zip.old
[ -f ""$workdir"/"$site"/files.zip" ] && mv "$workdir"/"$site"/files.zip "$workdir"/"$site"/files.zip.old &&
echo $(date "$DATE_FORMAT") "| Moving the old backup"
    
echo $(date "$DATE_FORMAT") "| Backuping database"

mysqldump -u "$mysqluser" -p"$mysqlpass" "$mysqldb" > "$workdir"/"$site"/"$site".sql &&
zip -rq $workdir/$site/database.zip "$workdir"/"$site"/"$site".sql                                                                                              
    returncode=$?

    if [ $returncode -ne 0 ] 
    then
	echo $(date "$DATE_FORMAT") "| Failed to create a database backup. Return code is "$returncode""
	echo "Error backuping "$site" database. Operation returned code $returncode" | mail -s "Error backuping DB "$site"" -a "$backuplog" "$email"
    else
        echo $(date "$DATE_FORMAT") "| Database backup created" 
    fi
                                                                                                                                                      
echo $(date "$DATE_FORMAT") "| Archiving files"

zip -rq "$workdir"/"$site"/files.zip -x="$sitedir"/cache/smarty/\* -x="$sitedir"/img/p/\* -x="$sitedir"/var/cache/\* -x="$sitedir"/upload/\* -x="$sitedir"/modules/expresscache/cache/\* "$workdir"/"$site"/"$site".zip "$sitedir"/

    returncode=$?

    if [ $returncode -ne 0 ] 
    then
 	echo $(date "$DATE_FORMAT") "| Error creating zip file. "$workdir"/"$site"/"$site".zip.old will stay. Return code is "$returncode""       
	echo "Error when creating "$site" archieve. ZIP returned code $returncode" | mail -s "Error creating backup "$site"" -a "$backuplog" "$email" 
	rm -rf "$workdir"/"$site"/files.zip
    else
	rm -rf "$workdir"/"$site"/"$site".sql 
	rm -rf "$workdir"/"$site"/database.zip.old  
	rm -rf "$workdir"/"$site"/files.zip.old  
	echo $(date "$DATE_FORMAT") "| Archive created. Old archive deleted"
    fi
                                                                                                                                                    
echo $(date "$DATE_FORMAT") "| Starting upload to the google disk"

[ -f ""$workdir"/"$site"/files.zip" ] && 
"$workdir"/drive push -ignore-conflict -ignore-name-clashes -quiet "$workdir"/"$site"/files.zip  > /dev/null ||
echo $(date "$DATE_FORMAT") "| Files not found, canceling upload"
    	
	returncode_files=$?

[ -f ""$workdir"/"$site"/database.zip" ] &&   
"$workdir"/drive push -ignore-conflict -ignore-name-clashes -quiet "$workdir"/"$site"/database.zip > /dev/null ||
echo $(date "$DATE_FORMAT") "| Database not found, canceling upload"
    
	returncode_database=$?
    
    if [ $returncode_files -ne 0 ] && [ $returncode_database -ne 0 ] 
    then
	echo $(date "$DATE_FORMAT") "| Error, upload not complete. Return code Files: "$returncode_files", Database: "$returncode_database""
    	echo "Error occured while uploading archive to google" | mail -s "Error while uploading "$site" backup" -a "$backuplog" "$email"
    else
	echo $(date "$DATE_FORMAT") "| Task complete"
    fi
