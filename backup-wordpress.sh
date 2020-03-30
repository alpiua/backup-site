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

echo `date` "Починаю працювати"
echo `date` "Створюю дамп бази даних"

    mysqldump -u $mysqluser -p$mysqlpass $mysqldb > $workdir/$site/$site.sql

    [ -f "$workdir/$site.sql" ] &&
	du -h $workdir/$site.sql &&
        echo `date` "Файл SQL бази створено" || echo `date` "ПОМИЛКА СТВОРЕННЯ БАЗИ SQL"

echo ""
echo `date` "Переміщую старий архів"
    mv $workdir/$site/$site.zip $workdir/$site/$site.zip.old

echo ""
echo `date` "Архівую файли магазину і базу MySQL"

zip -rq $workdir/$site/$site.zip -x=$sitedir/wp-content/cache/min/1/\* -x=$sitedir/wp-content/cache/wp-rocket/\* $sitedir/ $workdir/$site.sql
    
    returncode=$?    
    if [ $returncode -ne 0 ]; then
	echo "Error when creating $site archieve. ZIP returned code $returncode" | mail -s 'Error creating backup [MAXMI]' -a /home/maxmi/backup/backup-mi92.log $email
	echo `date` "Помилка створення архіву. Старий архів $workdir/$site/$site.zip.old збережено"       
	rm -rf $workdir/$site/$site.zip
    else
    [ -f "$workdir/$site/$site.zip" ] &&
        du -h $workdir/$site/$site.zip &&
	rm -rf $workdir/$site/$site.sql &&
	rm -rf $workdir/$site/$site.zip.old && 
	echo `date` "Файли сайту заархівовано. Старий архів видалено" || echo `date` "ПОМИЛКА СТВОРЕННЯ ФАЙЛІВ САЙТУ"
    fi

echo ""
echo `date` "Починаю завантаження на гугл диск"

$workdir/drive push -ignore-conflict -ignore-name-clashes -quiet $workdir/$site/$site.zip

echo "Завантаження завершено"
echo "`date`"
