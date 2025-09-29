#!/usr/bin/bash

DB_NAME="serviciosmetal"
DB_USER="serviciosmetal"
USER=$DB_NAME
FILESTORE_DATA="/opt/$DB_NAME/data/filestore"
BACKUP_DIR="/opt/$DB_NAME/backup"
BASE_DIR="/opt/$DB_NAME/"
DATE=$(date +"%Y-%m-%d_%HH-%MM-%SS-%4N")
# FILE_NAME_BACKUP=${DB_NAME}_db_${DATE}.dump
FILE_NAME_BACKUP="dump.sql"
ZIP_NAME_BACKUP=${DB_NAME}_backup_${DATE}.zip

mkdir -p $BACKUP_DIR
chown -R $USER:$USER $BACKUP_DIR

echo "${DATE} - Realizando backup de la base de datos..."
pg_dump -U $DB_USER -F p -f $BACKUP_DIR/$FILE_NAME_BACKUP $DB_NAME

echo "${DATE} - Realizando backup del FileStore..."
cp -r $FILESTORE_DATA/$DB_NAME $BACKUP_DIR/filestore

echo "${DATE} - Comprimiendo backup en ZIP..."
cd $BACKUP_DIR
zip -rq $ZIP_NAME_BACKUP $FILE_NAME_BACKUP filestore

echo "${DATE} - ✅ Backup comprimido en: $BACKUP_DIR/$ZIP_NAME_BACKUP"

rm -f $FILE_NAME_BACKUP
rm -rf filestore

echo "${DATE} - ✅ Limpieza completada. Backup listo."

find "$BACKUP_DIR" -name "*.zip" -type f -mtime +30 -exec rm -f {} \;

echo "${DATE} -🧹 Backups de más de 30 días eliminados."
echo ""
