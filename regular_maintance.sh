#!/bin/bash

# 설정
PAL_SERVER_SCRIPT="/home/ubuntu/palworld-arm64/palworld/PalServer.sh"
LOG_DIR="/home/ubuntu/palworld-arm64/log"
DAILY_LOG_FILE="$LOG_DIR/palworld-server-$(date +%Y-%m-%d).log"
PID_FILE="/tmp/palworld_server.pid"

# RCON 설정
RCON_PORT=25575
ADMIN_PASSWORD="palbungi1126#"
REBOOT_MSG="Server_is_going_to_reboot_in_"

# 로그 디렉토리 생성
mkdir -p "$LOG_DIR"

# 함수: 로그 기록
log_message() {
    local message=$1
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$DAILY_LOG_FILE"
}

# 함수: PalServer-Linux-Shipping 프로세스 확인
check_pal_binary_process() {
    if ps aux | grep -v grep | grep -q "PalServer-Linux-Shipping"; then
        echo "RUNNING"
    else
        echo "STOPPED"
    fi
}

# 함수: RCON 명령어 실행
rcon() {
    local command="$1"
    echo "$command" | /usr/games/arcon -P $RCON_PORT -p "$ADMIN_PASSWORD" 2>/dev/null
}

# 함수: 서버 시작
start_server() {
    echo "PalWorld 서버를 시작합니다..."
    log_message "서버 시작 시도"
    
    # 백그라운드에서 실행
    nohup "$PAL_SERVER_SCRIPT" >> "$DAILY_LOG_FILE" 2>&1 &
    local pid=$!
    echo $pid > "$PID_FILE"
    
    log_message "서버가 시작되었습니다. PID: $pid"
    echo "서버가 시작되었습니다. PID: $pid"
    echo "로그 파일: $DAILY_LOG_FILE"
    sleep 2
}

# 함수: 서버 재시작
restart_server() {
    echo "PalWorld 서버를 재시작합니다..."
    echo "================================================"
    
    log_message "서버 재시작 시도"
    
    # 초기 저장 및 5분 알림
    echo "초기 저장 및 5분 알림을 보냅니다..."
    rcon "save"
    rcon "shutdown 300 ${REBOOT_MSG}5_min"
    
    # 3분 알림
    echo "3분 후 재시작..."
    sleep 120
    rcon "broadcast ${REBOOT_MSG}3_min"
    
    # 2분 알림
    echo "2분 후 재시작..."
    sleep 60
    rcon "broadcast ${REBOOT_MSG}2_min"
    
    # 1분 알림 및 저장
    echo "1분 후 재시작..."
    sleep 60
    rcon "broadcast ${REBOOT_MSG}60_sec"
    rcon "save"
    
    # 10초 알림
    echo "10초 후 재시작..."
    sleep 50
    rcon "broadcast ${REBOOT_MSG}10_sec"
    
    # 5초 카운트다운
    echo "최종 카운트다운 시작..."
    sleep 5
    for i in {5..1}; do
        echo "$i초 남음!"
        rcon "broadcast ${REBOOT_MSG}${i}_sec"
        sleep 1
    done
    
    # 최종 대기
    sleep 1
    
    # 잠시 대기
    sleep 3
    
    # 서버 시작
    start_server
    
    log_message "서버 재시작 완료"
    echo "서버 재시작이 완료되었습니다."
    echo ""
    echo "로그 파일: $DAILY_LOG_FILE"
    echo "================================================"
}

echo "[ 서버 재시작 전용 스크립트 ]"
echo "================================================"

# 서버 상태 확인
if [ "$(check_pal_binary_process)" = "RUNNING" ]; then
    echo "서버가 실행 중입니다. 재시작을 시작합니다."
    echo ""
    restart_server
else
    echo "서버가 실행 중이 아닙니다. 시작 후 재시작을 시도합니다."
    echo ""
    start_server
    sleep 10
    echo "서버가 시작되었습니다. 재시작을 시작합니다."
    echo ""
    restart_server
fi

# 완료 메시지
echo ""
echo "서버 재시작 프로세스가 완료되었습니다!"
echo "$(date)"
