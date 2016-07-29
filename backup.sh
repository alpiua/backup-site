##########################################################
#  Backup to Google Drive Script For Prestashop by alpi  #
##########################################################

site=glamourshop.ru
workdir=/home/backup
sitedir=/home/www/glamourshop.ru
mysqldb    = glamour_db
mysqluser  = glamour_db
mysqlpass  = Ro2DCSce

echo "Делаю дамп базы данных" `date`

    mysqldump -u $mysqluser -p$mysqlpass $mysqldb > $workdir/$site.sql
    zip -rq $workdir/$site/$site.sql.zip $workdir/$site.sql

    [ -f "$workdir/$site.sql" ] &&
        echo "Файл SQL базы создан" `date` &&
        du -h $workdir/$site.sql || echo "ОШИБКА СОЗДАНИЯ БАЗЫ SQL" `date`

    rm -rf $workdir/$site.sql


echo "Архивирую файлы магазина (без картинок)" `date`

    zip -rq -x=$sitedir/cache/smarty/\* -x=$sitedir/img/p/\* -x=$sitedir/newpresta/\* $workdir/$site/$site.zip $sitedir/

    [ -f "$workdir/$site/$site.zip" ] &&
        echo "Файлы сайта заархивированы" `date` &&
        du -h $workdir/$site/$site.zip || echo "ОШИБКА СОЗДАНИЯ ФАЙЛОВ САЙТА" `date`


echo "Архивирую файлы изображений" `date`

    zip -rq $workdir/$site/$site-img.zip $sitedir/img/p/

    [ -f "$workdir/$site/$site-img.zip" ] &&
        echo "Файлы изображений заархивированы" `date` &&
        du -h $workdir/$site/$site-img.zip || echo "ОШИБКА СОЗДАНИЯ ИЗОБРАЖЕНИЙ" `date`


$workdir/drive push -ignore-conflict -quiet $workdir/$site
