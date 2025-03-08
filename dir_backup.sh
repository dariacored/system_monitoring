#!/bin/bash

# Copyright (c) 2025 dariacored. MIT License.

# Настройки путей
BACKUP_DIR="/var/backups"          # Локальная папка с бэкапами
SOURCE_DIR="/home/user/documents"  # Source-папка
RETENTION_DAYS=7                   # Хранить бэкапы N дней
LOG_FILE="/var/log/backup.log"     # Лог-файл

# Настройки удаленного сервера
REMOTE_USER="user"                 # Пользователь на удаленном сервере
REMOTE_HOST="backup.example.com"   # IP или домен сервера
REMOTE_PATH="/backups"             # Путь на удаленном сервере
TRANSPORT="rsync"                  # rsync или scp

# Настройки Telegram
TG_TOKEN="bot_token"
TG_CHAT_ID="chat_id"

# Создание имени архива
current_date=$(date '+%Y-%m-%d_%H-%M')
archive_name="backup_${current_date}.tar.gz"

# Проверка директорий
mkdir -p $BACKUP_DIR || { echo "Ошибка создания $BACKUP_DIR" | tee -a $LOG_FILE; exit 1; }
[ -d "$SOURCE_DIR" ] || { echo "Директория $SOURCE_DIR не существует" | tee -a $LOG_FILE; exit 1; }

# Создание бэкапа
echo "[$(date '+%Y-%m-%d %H:%M')] Начало бэкапа: $SOURCE_DIR" | tee -a $LOG_FILE
tar -czf $BACKUP_DIR/$archive_name $SOURCE_DIR 2>> $LOG_FILE

# Проверка успешности архивации
if [ $? -ne 0 ]; then
    echo "[$(date)] Ошибка создания бэкапа!" | tee -a $LOG_FILE
    curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
        -d chat_id=$TG_CHAT_ID -d text="ALERT! Backup FAILED: $SOURCE_DIR"
    exit 1
fi

echo "[$(date)] Бэкап создан: $archive_name" | tee -a $LOG_FILE

# Отправка на удаленный сервер
remote_transfer() {
    case $TRANSPORT in
        "rsync")
            rsync -avz -e "ssh -o StrictHostKeyChecking=no" \
                $BACKUP_DIR/$archive_name \
                $REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/
            ;;
        "scp")
            scp -o StrictHostKeyChecking=no \
                $BACKUP_DIR/$archive_name \
                $REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/
            ;;
        *)
            echo "Неверный метод транспорта" | tee -a $LOG_FILE
            return 1
    esac
}

echo "[$(date)] Начало отправки бэкапа на $REMOTE_HOST" | tee -a $LOG_FILE
if remote_transfer; then
    echo "[$(date)] Бэкап успешно отправлен" | tee -a $LOG_FILE
else
    echo "[$(date)] Ошибка отправки бэкапа!" | tee -a $LOG_FILE
    curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
        -d chat_id=$TG_CHAT_ID -d text="ALERT! Ошибка отправки бэкапа на $REMOTE_HOST"
    exit 1
fi

# Очистка старых бэкапов
find $BACKUP_DIR -name "backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete
echo "[$(date)] Удалены локальные бэкапы старше $RETENTION_DAYS дней" | tee -a $LOG_FILE

# Очистка на удаленном сервере (только для rsync)
if [ "$TRANSPORT" = "rsync" ]; then
    ssh $REMOTE_USER@$REMOTE_HOST "find $REMOTE_PATH -name 'backup_*.tar.gz' -mtime +$RETENTION_DAYS -delete"
    echo "[$(date)] Удалены удаленные бэкапы старше $RETENTION_DAYS дней" | tee -a $LOG_FILE
fi