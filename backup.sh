##########################################################
#  Backup to Google Drive Script For Prestashop by alpi  #
##########################################################

site= site.com
workdir= /var/backupdir
sitedir= /var/www/sitedir
mysqldb    = db_name
mysqluser  = db_user
mysqlpass  = db_password

echo "Роблю дамп бази даних" `date`

    mysqldump -u $mysqluser -p$mysqlpass $mysqldb > $workdir/$site.sql
    zip -rq $workdir/$site/$site.sql.zip $workdir/$site.sql

    [ -f "$workdir/$site.sql" ] &&
        echo "Файл SQL бази створено" `date` &&
        du -h $workdir/$site.sql || echo "ПОМИЛКА СТВОРЕННЯ БАЗИ SQL" `date`

    rm -rf $workdir/$site.sql


echo "Архівую файли магазину (без картинок)" `date`

    zip -rq -x=$sitedir/cache/smarty/\* -x=$sitedir/img/p/\* -x=$sitedir/newpresta/\* $workdir/$site/$site.zip $sitedir/

    [ -f "$workdir/$site/$site.zip" ] &&
        echo "Файли сайту заархівовано" `date` &&
        du -h $workdir/$site/$site.zip || echo "ПОМИЛКА СТВОРЕННЯ ФАЙЛІВ САЙТУ" `date`


echo "Архівую файли зображень" `date`

    zip -rq $workdir/$site/$site-img.zip $sitedir/img/p/

    [ -f "$workdir/$site/$site-img.zip" ] &&
        echo "Файлы зображень заархівовано" `date` &&
        du -h $workdir/$site/$site-img.zip || echo "ПОМИЛКА СТВОРЕННЯ ЗОБРАЖЕНЬ" `date`


echo "Починаю завантаження на гугл диск" `date`

$workdir/drive push -ignore-conflict -quiet $workdir/$site

echo "Завантаження завершено" `date`
