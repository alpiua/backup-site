#!/bin/bash

##  Backup to External Drive via sshfs/rsync
##  Author: Oleksii Pylypchuk 
##  github: https://github.com/alpi-ua/backup-site/
##  require packages: bsd-mailx, sshfs

site=
email=alpi@keemail.me

BACKUPS_NUM=3
USER=

# LOCAL SERVER VARS
WORKDIR="/var/backups/local"
SITEDIR="/var/www/campdavid_ch/app/src"
BACKUP_DIR=${WORKDIR}/${site}_$(date '+%d-%m-%Y')
SCRIPT_DIR="/var/backups"

# MYSQL DB VARS
MYSQLDB=""
MYSQLUSER=""
MYSQLPASS=""

# REMOTE SERVER VARS
RSERVER=""
RUSER=""
RDIR=/var/backups/${RSERVER}

files=${BACKUP_DIR}/${site}_files.zip
images=${BACKUP_DIR}/${site}_images.zip
database=${BACKUP_DIR}/${site}_database.zip
backuplog=${BACKUP_DIR}/${site}_backup.log

FREE_SPACE=$(df -k --output=avail ${PWD} | tail -n1)
SITE_SIZE=$(du -s ${SITEDIR} | cut -f 1)
ATTACHMENT="-f $backuplog"        # Ubuntu : bsd-mailx 8
#ATTACHMENT="-a $backuplog"        # RHEL   : mailx 12+


### FUNCTIONS
function log() {
echo "$(date '+[%d-%m-%Y] %H:%M:%S') | $1" >> $backuplog
rm -f ${WORKDIR}/error_output
}

function checkjob() {
returncode=$?
if [ ${returncode} -ne 0 ]
  then
    log "!! Failed to create a "$2" backup. Return code is ${returncode}. Original message: $(cat ${WORKDIR}/error_output | tr -d '\n')"
    echo "Error backuping ${site} "$2". Program returned code ${returncode}" | mail -s "Error backuping ${site} $2" ${ATTACHMENT} ${email}
    [[ -n $3 ]] && rm -rf "$3" && log "!! deleting unfinished part"
  else
    log "|_ New $2 backup created"
fi
}

function delete_old() {
OLD_BKP="$(cd $1; ls -1 | sed 's/^\([^0-9]*\)\([0-9]\+\.txt\)/\2\1/g' | sort -n | head -1 | sed 's/^\([0-9]\+\.txt\)\(.*\)/\2\1/g')"
rm -rf $1/${OLD_BKP} && log "|_ Removing backup ${OLD_BKP}"
}

function check_rdir() {
RDIR_BACKUP="$1/${site}_backup"
[ -d ${RDIR_BACKUP} ] || mkdir -p ${RDIR_BACKUP}
find ${RDIR_BACKUP} -type d -mtime +$((${BACKUPS_NUM} - 1)) | xargs rm -rf && log "Removing backups older than ${BACKUPS_NUM} days from external share"
}

function upload() {
rsync -re "ssh -p 23" ${BACKUP_DIR} ${RUSER}@${RSERVER}:${site}_backup/ &>${WORKDIR}/error_output
returncode=$?
if [ ${returncode} -ne 0 ]
  then
    log "-- Error occured. Upload unsuccessful. Return code is ${returncode}. Original message: $(cat ${WORKDIR}/error_output | tr -d '\n')"
    echo "Error occured while uploading "$1" to external share" | mail -s "Error uploading ${site} backup" ${ATTACHMENT}" $email"
  else
    log "|_Upload finished"
  fi
}


### Installing sudo and sshfs mount script

if [[ `whoami` == 'root' ]]
  then
    [[ ! -f /etc/sudoers.d/${USER} ]] && \
    echo "${USER}       ALL=NOPASSWD: /usr/bin/fusermount -u ${RDIR}" > /etc/sudoers.d/${USER} && \
    echo "Installing sudo for user ${USER}"

    [[ ! -f ${SCRIPT_DIR}/sshfs.sh ]] && \
    echo "Installing sshfs mount script" && cat > ${SCRIPT_DIR}/sshfs.sh <<EOF
#!/bin/bash
[[ \$1 == 'unmount' ]] && sudo /usr/bin/fusermount -u ${RDIR} && exit 0
[[ \$1 == 'mount' ]] && /usr/bin/sshfs -p 23 ${RUSER}@${RSERVER}: ${RDIR}
EOF
    chmod +x ${SCRIPT_DIR}/sshfs.sh
    chown ${USER}:${USER} ${RDIR}
    echo "You should generate and install ssh keys from user to remote server"

    [[ ! -f /etc/cron.d/backup-${SITE} ]] && \
    echo "Installing cron task for backup in /etc/cron.d" && cat > /etc/cron.d/backup-${USER} <<EOF
0 5 * * * ${USER} $(realpath $0)
EOF
  else
    [[ ! -f /etc/sudoers.d/${USER} ]] && [[ ! -f ${SCRIPT_DIR}/sshfs.sh ]] && \
    echo "First run of this script should happen as 'root'" && exit 0
fi


### SCRIPT STARTS

echo "=================================================================" >> $backuplog

log "Starting backup to ${site}"

if grep -qs ${RDIR} /proc/mounts
  then
    log "external storage is mounted."
    check_rdir ${RDIR}
  else
    log "mounting external storage"
    ${SCRIPT_DIR}/sshfs.sh mount
    check_rdir ${RDIR}
    ${SCRIPT_DIR}/sshfs.sh unmount
fi

[[ `whoami` == 'root' ]] && [[ -d ${RDIR} ]] || mkdir -p ${RDIR}
[[ -d ${BACKUP_DIR} ]] || mkdir -p ${BACKUP_DIR}
[[ -f ${backuplog} ]] || touch ${backuplog} && chown ${USER}:${USER} ${backuplog}

[ ${FREE_SPACE} -lt ${SITE_SIZE} ] && log "Not enough free space on local host. Removing old backup" && delete_old ${WORKDIR}

log "Backuping database"
mysqldump -u ${MYSQLUSER} -p${MYSQLPASS} ${MYSQLDB} > ${BACKUP_DIR}/${site}.sql

cd ${BACKUP_DIR} ; zip -rq "$database" ${site}.sql &>${WORKDIR}/error_output
checkjob "$?" "database" "$database" && rm -rf ${site}.sql

log "Archiving files"
cd ${SITEDIR} ; zip -x=cache/smarty/\* -x=img/p/\* -x=upload/\* -x=var/cache/\* -rq "$files" . &>${WORKDIR}/error_output
checkjob "$?" "files" "$files"

log "Archiving images"
cd ${SITEDIR} ; zip -rq "$images" img/p/ &>${WORKDIR}/error_output
checkjob "$?" "images" "$images"

log "Archiving system settings"
zip -rq ${BACKUP_DIR}/etc.zip /etc /var/spool/crontabs /var/backups/backup.sh &>/dev/null

log "Uploading backup"
upload ${BACKUP_DIR}

### IN CASE WE ARE UNDER ROOT
[ `whoami` == 'root' ] && chown -R ${USER}:${USER} ${WORKDIR}
