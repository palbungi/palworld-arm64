#!/bin/sh

RCON_PORT=25575
ADMIN_PASSWORD=
REBOOT_MSG="Server_is_going_to_reboot_in_"

# RCON 명령어 실행 함수
rcon() {
    echo "$1" | ./ARRCON -P $RCON_PORT -p $ADMIN_PASSWORD
}

# 초기 저장 및 종료 예약
rcon "shutdown 300 ${REBOOT_MSG}5_min"

# 3분, 2분, 1분 알림
sleep 120
rcon "broadcast ${REBOOT_MSG}3_min"

sleep 60
rcon "broadcast ${REBOOT_MSG}2_min"

sleep 60
rcon "broadcast ${REBOOT_MSG}60_sec"
rcon "save"

# 10초 알림
sleep 50
rcon "broadcast ${REBOOT_MSG}10_sec"
rcon "save"

# 5초부터 카운트다운
sleep 5
for i in {5..1}; do
    rcon "broadcast ${REBOOT_MSG}${i}_sec"
    sleep 1
done
