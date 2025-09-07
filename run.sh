#!/bin/bash

# 색상 정의
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
PURPLE='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# 설정
PAL_SERVER_SCRIPT="/home/ubuntu/palworld-arm64/palworld/PalServer.sh"
LOG_FILE="/dev/null"
PID_FILE="/tmp/palworld_server.pid"

# 함수: 색상 출력
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# 함수: 서버 상태 확인
check_server_status() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "RUNNING"
        else
            echo "STOPPED"
        fi
    else
        echo "STOPPED"
    fi
}

# 함수: 서버 종료
stop_server() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            print_color "${YELLOW}" "서버를 종료합니다 (PID: $pid)..."
            kill "$pid"
            sleep 3
            if kill -0 "$pid" 2>/dev/null; then
                print_color "${RED}" "강제 종료를 시도합니다..."
                kill -9 "$pid"
            fi
            rm -f "$PID_FILE"
            print_color "${GREEN}" "✅ 서버가 종료되었습니다."
        else
            print_color "${YELLOW}" "서버가 이미 종료된 상태입니다."
            rm -f "$PID_FILE"
        fi
    else
        print_color "${YELLOW}" "서버가 실행 중이 아닙니다."
    fi
}

# 함수: 서버 재시작
restart_server() {
    stop_server
    sleep 2
    print_color "${CYAN}" "서버를 시작합니다..."
    nohup "$PAL_SERVER_SCRIPT" > "$LOG_FILE" 2>&1 &
    local pid=$!
    echo $pid > "$PID_FILE"
    print_color "${GREEN}" "✅ 서버가 재시작되었습니다. PID: $pid"
}

# 함수: 사용자 선택
ask_user() {
    echo -e "${PURPLE}"
    echo "╔════════════════════════════════════╗"
    echo "║        ${WHITE}Palworld 서버 관리 스크립트${PURPLE}       ║"
    echo "╠════════════════════════════════════╣"
    echo -e "║  ${YELLOW}🚀 서버가 이미 실행 중입니다${PURPLE}           ║"
    echo -e "║  ${CYAN}PID: $(cat "$PID_FILE")${PURPLE}                          ║"
    echo "╠════════════════════════════════════╣"
    echo -e "║  ${WHITE}1. ${RED}서버 종료${PURPLE}                           ║"
    echo -e "║  ${WHITE}2. ${GREEN}서버 재시작${PURPLE}                         ║"
    echo -e "║  ${WHITE}3. ${YELLOW}취소${PURPLE}                               ║"
    echo "╚════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${BOLD}${CYAN}"
    read -p "선택해주세요 (1-3): " choice
    echo -e "${NC}"
    
    case $choice in
        1)
            stop_server
            ;;
        2)
            restart_server
            ;;
        3)
            print_color "${YELLOW}" "⚠️  작업을 취소합니다."
            exit 0
            ;;
        *)
            print_color "${RED}" "❌ 잘못된 선택입니다. 1-3 사이의 숫자를 입력해주세요."
            echo ""
            ask_user
            ;;
    esac
}

# 메인 실행
main() {
    # Clear screen
    clear
    
    # Print header
    echo -e "${BLUE}"
    echo "██████╗  █████╗ ██╗     ██╗    ██╗    ██╗ ██████╗ ██████╗ ██╗     ██████╗ "
    echo "██╔══██╗██╔══██╗██║     ██║    ██║    ██║██╔═══██╗██╔══██╗██║     ██╔══██╗"
    echo "██████╔╝███████║██║     ██║    ██║ █╗ ██║██║   ██║██████╔╝██║     ██║  ██║"
    echo "██╔═══╝ ██╔══██║██║     ██║    ██║███╗██║██║   ██║██╔══██╗██║     ██║  ██║"
    echo "██║     ██║  ██║███████╗███████║╚███╔███╔╝╚██████╔╝██║  ██║███████╗██████╔╝"
    echo "╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝ ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═════╝ "
    echo -e "${NC}"
    echo ""
    
    status=$(check_server_status)
    
    if [ "$status" = "RUNNING" ]; then
        print_color "${GREEN}" "✅ 서버가 실행 중입니다 (PID: $(cat "$PID_FILE"))"
        echo ""
        ask_user
    else
        print_color "${YELLOW}" "⚠️  서버가 실행 중이 아닙니다."
        echo ""
        echo -e "${BOLD}${CYAN}"
        read -p "서버를 시작하시겠습니까? (y/N): " start_choice
        echo -e "${NC}"
        
        if [[ "$start_choice" =~ ^[Yy]$ ]]; then
            print_color "${CYAN}" "🚀 서버를 시작합니다..."
            nohup "$PAL_SERVER_SCRIPT" > "$LOG_FILE" 2>&1 &
            local pid=$!
            echo $pid > "$PID_FILE"
            print_color "${GREEN}" "✅ 서버가 시작되었습니다. PID: $pid"
        else
            print_color "${YELLOW}" "⚠️  작업을 취소합니다."
            exit 0
        fi
    fi
}

# 실행
main
