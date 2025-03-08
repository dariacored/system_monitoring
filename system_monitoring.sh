#!/bin/bash

# Copyright (c) 2025 dariacored. MIT License.

# Пороги для алертов
CPU_THRESHOLD=80
MEM_THRESHOLD=85
DISK_THRESHOLD=90

# Настройки логов
LOG_FILE="/var/log/system_monitoring.log"

# Настройки сети
NET_INTERFACE="eth0"              # Укажите свой интерфейс (ip link show)
MIN_NET_SPEED=1000                # Минимальная скорость в Mbps (для проверки линка)

# Настройки Telegram
TG_TOKEN="bot_token"              # @BotFather
TG_CHAT_ID="chat_id"
TG_API="https://api.telegram.org/bot${TG_TOKEN}/sendMessage"

# Функция отправки алерта в Telegram
send_telegram() {
    local message="$1"
    curl -s -X POST $TG_API \
        -d chat_id=$TG_CHAT_ID \
        -d text="$message" \
        -d parse_mode="Markdown" >/dev/null
}

# Получение метрик
current_cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
current_mem=$(free | grep Mem | awk '{print $3/$2 * 100.0}' | cut -d'.' -f1)
current_disk=$(df / | awk 'NR==2 {print $5}' | tr -d '%')

# Мониторинг сети
net_status=$(cat /sys/class/net/$NET_INTERFACE/operstate 2>/dev/null)
net_speed=$(ethtool $NET_INTERFACE 2>/dev/null | grep "Speed:" | awk '{print $2}' | tr -d 'Mb/s')

# Запись в лог
echo "$(date '+%Y-%m-%d %H:%M:%S') CPU: ${current_cpu}%, Memory: ${current_mem}%, Disk: ${current_disk}%, Network: ${net_status} (${net_speed}Mbps)" >> $LOG_FILE

# Проверка порогов
alert_message=""

# CPU
if (( $(echo "$current_cpu >= $CPU_THRESHOLD" | bc -l) )); then
    alert_message+="ALERT! CPU usage: ${current_cpu}%\n"
fi

# Mem
if (( $(echo "$current_mem >= $MEM_THRESHOLD" | bc -l) )); then
    alert_message+="ALERT! Memory usage: ${current_mem}%\n"
fi

# Disk
if (( current_disk >= DISK_THRESHOLD )); then
    alert_message+="ALERT! Disk usage: ${current_disk}%\n"
fi

# Network
if [ "$net_status" != "up" ]; then
    alert_message+="ALERT! Network interface $NET_INTERFACE is DOWN!\n"
elif [ -n "$net_speed" ] && [ "$net_speed" -lt "$MIN_NET_SPEED" ]; then
    alert_message+="ALERT! Network speed is low: ${net_speed}Mbps\n"
fi

# Отправка алертов
if [ -n "$alert_message" ]; then
    echo -e "Subject: System Alert\n\n$alert_message" | sendmail your-email@example.com
    
    send_telegram "System Alert: $(echo -e $alert_message)"
fi