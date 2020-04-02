
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
echo $(date "$DATE_FORMAT") "| Backuping database"

mysqldump -u "$mysqluser" -p"$mysqlpass" "$mysqldb" > "$workdir"/"$site"/"$site".sql

    returncode=$?

    if [ $returncode -ne 0 ] 
    then
	echo $(date "$DATE_FORMAT") "| Failed to create a database backup. Return code is "$returncode""
	echo "Error backuping "$site" database. mysqldump returned code $returncode" | mail -s "Error backuping DB "$site"" -a "$backuplog" "$email"
    else
        echo $(date "$DATE_FORMAT") "| Database backup created" 
    fi

[ -f ""$workdir"/"$site"/"$site".zip" ] && [ -f ""$workdir"/"$site"/"$site"-img.zip" ] && 
    echo $(date "$DATE_FORMAT") "| Moving the old backup" &&
    mv "$workdir"/"$site"/"$site".zip "$workdir"/"$site"/"$site".zip.old &&
    mv "$workdir"/"$site"/"$site"-img.zip "$workdir"/"$site"/"$site"-img.zip.old

echo $(date "$DATE_FORMAT") "| Archiving files and database"

zip -rq -x="$sitedir"/cache/smarty/\* -x="$sitedir"/img/p/\* -x="$sitedir"/upload/\* -x="$sitedir"/modules/expresscache/cache/\* "$workdir"/"$site"/"$site".zip "$sitedir"/ "$sitedir"/"$site".sql

    returncode=$?

    if [ $returncode -ne 0 ] 
    then
 	echo $(date "$DATE_FORMAT") "| Error creating zip file. "$workdir"/"$site"/"$site".zip.old will stay. Return code is "$returncode""       
	echo "Error when creating "$site" archieve. ZIP returned code $returncode" | mail -s "Error creating backup "$site"" -a "$backuplog" "$email" 
	rm -rf "$workdir"/"$site"/"$site".zip
    else
	rm -rf "$workdir"/"$site"/"$site".sql 
	rm -rf "$workdir"/"$site"/"$site".zip.old  
	echo $(date "$DATE_FORMAT") "| Archive created. Old archive deleted"
    fi

echo $(date "$DATE_FORMAT") "| Archiving images"
                                                                                                                                                      
zip -rq $workdir/$site/$site-img.zip $sitedir/img/p/                                                                                              
 
   returncode=$?

    if [ $returncode -ne 0 ] 
    then
 	echo $(date "$DATE_FORMAT") "| Error creating images archive. Return code "$returncode"" 
	echo "Error when creating "$site" archieve. ZIP returned code $returncode" | mail -s "Error creating backup "$site"" -a "$backuplog" "$email" 
	rm -rf "$workdir"/"$site"/"$site"-img.zip
    else
	rm -rf "$workdir"/"$site"/"$site"-img.zip.old && 
	echo $(date "$DATE_FORMAT") "| Images archive created. Old archive deleted"
    fi
                                                                                                                                                     
echo $(date "$DATE_FORMAT") "| Starting upload to the google disk"

[ -f ""$workdir"/"$site"/"$site".zip" ] && [ -f ""$workdir"/"$site"/"$site"-img.zip" ] &&                                                                     "$workdir"/drive push -ignore-conflict -ignore-name-clashes -quiet "$workdir"/"$site"/"$site".zip "$workdir"/"$site"/"$site"-img.zip > /dev/null || echo $(date "$DATE_FORMAT") "| No files to upload, cancelling" 
    
    returncode=$?
    
    if [ $returncode -ne 0 ]
    then
	echo $(date "$DATE_FORMAT") "| Error occured. Upload NOT complete. Return code is "$returncode""
    	echo "Error occured while uploading archive to google" | mail -s "Error while uploading "$site" backup" -a "$backuplog" "$email"
    else
	echo $(date "$DATE_FORMAT") "| Task complete"
    fi
