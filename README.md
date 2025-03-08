# system_monitoring
Простые bash-скрипты для мониторинга состояния системы

## Системный мониторинг сервера

- Настройте права доступа и установите утилиту `mailutils` для отправки сообщений на email:
```
chmod +x system_monitor.sh
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