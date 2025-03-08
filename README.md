# system_monitoring
Простые bash-скрипты для мониторинга состояния системы

## Системный мониторинг сервера

- Настройте права доступа и установите утилиту `mailutils` для отправки сообщений на email:
```
chmod +x system_monitoring.sh
sudo apt install curl mailutils
```

- Добавьте задание в Cron:
```
crontab -e
*/5 * * * * /path/system_monitoring.sh
```

- Настройте отправку уведомлений в Telegram:
```
TG_TOKEN="123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11"
TG_CHAT_ID="123456789"
```

- Для корректной работы проверьте:
  - Имя сетевого интерфейса (используйте команду `ip link show`)
  - Работоспособность Telegram API
  - Права на запись в `/var/log/system_monitoring.log`

## Бекап каталогов с отправкой на удаленный сервер

- Настройте права доступа и установите `rsync` и `openssh-client`:
```
chmod +x dir_backup.sh
sudo apt install rsync openssh-client
```

- Сгенерируйте SSH-ключ для аутентификации:
```
ssh-keygen
ssh-copy-id $REMOTE_USER@$REMOTE_HOST
```

- Задайте переменные. Если нужно, добавьте токен телеграм-бота и айди чата, в который будут отправляться уведомления.

- Проверьте подключение:
`ssh $REMOTE_USER@$REMOTE_HOST "mkdir -p $REMOTE_PATH"`

- Добавьте задание в Cron:
```
crontab -e
0 4 * * * /path/dir_backup.sh
```