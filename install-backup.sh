#!/bin/bash

set -e

if [ -z "$1" ]; then
    echo "Error: Debes proporcionar el nombre del usuario."
    echo "Uso: ./install-backup.sh <nombre de usuario>"
    exit 1
fi

USER_NAME="$1"
BACKUP_ROOT="/opt/backup/$USER_NAME"
BACKUP_FILE_DIR="$BACKUP_ROOT/backup.sh"
LOG_FILE="$BACKUP_ROOT/backup.log"

mkdir -p "$BACKUP_ROOT"

cat >"$BACKUP_FILE_DIR" <<EOL
#!/usr/bin/bash

DB_NAME="$USER_NAME"
DB_USER="$USER_NAME"
# Escapamos el signo \$ para que se evalúe cuando se ejecute el backup, no ahora
USER_EXEC=\$DB_NAME 
FILESTORE_DATA="/opt/\$DB_NAME/data/filestore"
BACKUP_DIR="/opt/\$DB_NAME/backup/$USER_NAME"
DATE=\$(date +"%Y-%m-%d_%HH-%MM-%SS")

FILE_NAME_BACKUP="dump.sql"
ZIP_NAME_BACKUP=\${DB_NAME}_backup_\${DATE}.zip

mkdir -p \$BACKUP_DIR
# El usuario de Odoo suele ser el dueño
chown -R \$DB_USER:\$DB_USER \$BACKUP_DIR

echo "\${DATE} - Realizando backup de la base de datos..."
pg_dump -U \$DB_USER -F p -f \$BACKUP_DIR/\$FILE_NAME_BACKUP \$DB_NAME

echo "\${DATE} - Realizando backup del FileStore..."
cp -r \$FILESTORE_DATA/\$DB_NAME \$BACKUP_DIR/filestore

echo "\${DATE} - Comprimiendo backup en ZIP..."
cd \$BACKUP_DIR
zip -rq \$ZIP_NAME_BACKUP \$FILE_NAME_BACKUP filestore

echo "\${DATE} - ✅ Backup comprimido en: \$BACKUP_DIR/\$ZIP_NAME_BACKUP"

rm -f \$FILE_NAME_BACKUP
rm -rf filestore

find "\$BACKUP_DIR" -name "*.zip" -type f -mtime +30 -exec rm -f {} \;
echo "\${DATE} - 🧹 Backups antiguos eliminados."
EOL

chown -R "$USER_NAME:$USER_NAME" "$BACKUP_ROOT"
#chmod +x "$BACKUP_FILE_DIR"

CRON_JOB="0 0 * * 0 /usr/bin/bash $BACKUP_FILE_DIR >> $LOG_FILE 2>&1"

echo "Programando tarea en el crontab del usuario: $USER_NAME..."
(crontab -u "$USER_NAME" -l 2>/dev/null | grep -Fv "$BACKUP_FILE_DIR" ; echo "$CRON_JOB") | crontab -u "$USER_NAME" -

echo "----------------------------------------------------------------------"
echo "✅ Backup configurado exitosamente para el usuario: $USER_NAME"
echo "📅 El cron se ejecutará como '$USER_NAME' y no como root."
echo "----------------------------------------------------------------------"