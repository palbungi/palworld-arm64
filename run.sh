#!/bin/bash

# ANSI 색상 정의
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
LOG_DIR="/home/ubuntu/palworld-arm64/log"
DAILY_LOG_FILE="$LOG_DIR/palworld-server-$(date +%Y-%m-%d).log"
PID_FILE="/tmp/palworld_server.pid"
FEX_EMU_PID_FILE="/tmp/palworld_fex_emu.pid"

# 로그 디렉토리 생성
mkdir -p "$LOG_DIR"

# 함수: 색상 출력
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# 함수: 로그 기록
log_message() {
    local message=$1
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$DAILY_LOG_FILE"
}

# 함수: PalServer.sh 프로세스 확인
check_pal_server_process() {
    if ps aux | grep -v grep | grep -q "$PAL_SERVER_SCRIPT"; then
        echo "RUNNING"
    else
        echo "STOPPED"
    fi
}

# 함수: FEX-EMU 프로세스 확인
check_fex_emu_process() {
    if ps aux | grep -v grep | grep -q "FEXInterpreter.*PalServer-Linux-Shipping"; then
        echo "RUNNING"
    else
        echo "STOPPED"
    fi
}

# 함수: PalServer-Linux-Shipping 프로세스 확인
check_pal_binary_process() {
    if ps aux | grep -v grep | grep -q "PalServer-Linux-Shipping"; then
        echo "RUNNING"
    else
        echo "STOPPED"
    fi
}

# 함수: 서버 시작
start_server() {
    print_color "${CYAN}" "🚀 PalWorld 서버를 시작합니다..."
    log_message "서버 시작 시도"
    
    # 백그라운드에서 실행
    nohup "$PAL_SERVER_SCRIPT" >> "$DAILY_LOG_FILE" 2>&1 &
    local pid=$!
    echo $pid > "$PID_FILE"
    
    log_message "서버가 시작되었습니다. PID: $pid"
    print_color "${GREEN}" "✅ 서버가 시작되었습니다. PID: $pid"
    print_color "${CYAN}" "📝 로그 파일: $DAILY_LOG_FILE"
    sleep 2
}

# 함수: 서버 종료
stop_server() {
    print_color "${YELLOW}" "🛑 서버를 종료합니다..."
    log_message "서버 종료 시도"
    
    # 모든 관련 프로세스 종료
    pkill -f "$PAL_SERVER_SCRIPT"
    pkill -f "FEXInterpreter.*PalServer-Linux-Shipping"
    pkill -f "PalServer-Linux-Shipping"
    
    sleep 3
    
    # 강제 종료 시도 (여전히 실행 중인 프로세스가 있는 경우)
    if [ "$(check_pal_server_process)" = "RUNNING" ] || 
       [ "$(check_fex_emu_process)" = "RUNNING" ] || 
       [ "$(check_pal_binary_process)" = "RUNNING" ]; then
        print_color "${RED}" "⚠️  강제 종료를 시도합니다..."
        log_message "강제 종료 시도"
        pkill -9 -f "$PAL_SERVER_SCRIPT"
        pkill -9 -f "FEXInterpreter.*PalServer-Linux-Shipping"
        pkill -9 -f "PalServer-Linux-Shipping"
    fi
    
    # PID 파일 정리
    rm -f "$PID_FILE" "$FEX_EMU_PID_FILE"
    
    log_message "서버가 종료되었습니다."
    print_color "${GREEN}" "✅ 서버가 종료되었습니다."
}

# 함수: 로그 보기
show_logs() {
    print_color "${CYAN}" "📋 최근 서버 로그 20줄:"
    echo -e "${PURPLE}==========================================${NC}"
    if [ -f "$DAILY_LOG_FILE" ]; then
        tail -20 "$DAILY_LOG_FILE"
    else
        print_color "${YELLOW}" "⚠️  로그 파일이 존재하지 않습니다."
    fi
    echo -e "${PURPLE}==========================================${NC}"
    echo ""
}

# 함수: 서버 상태 표시 (간단한 버전)
show_server_status() {
    local pal_status=$(check_pal_server_process)
    local fex_status=$(check_fex_emu_process)
    local binary_status=$(check_pal_binary_process)
    
    echo -e "${BLUE}╔════════════════════════════════════╗"
    echo -e "║           서버 상태 정보           ║"
    echo -e "╠════════════════════════════════════╣"
    
    if [ "$pal_status" = "RUNNING" ]; then
        echo -e "║  ${GREEN}✅ PalServer.sh: 실행 중${BLUE}           ║"
    else
        echo -e "║  ${RED}❌ PalServer.sh: 중지됨${BLUE}            ║"
    fi
    
    if [ "$fex_status" = "RUNNING" ]; then
        echo -e "║  ${GREEN}✅ FEXInterpreter: 실행 중${BLUE}        ║"
    else
        echo -e "║  ${RED}❌ FEXInterpreter: 중지됨${BLUE}         ║"
    fi
    
    if [ "$binary_status" = "RUNNING" ]; then
        echo -e "║  ${GREEN}✅ PalServer: 실행 중${BLUE}             ║"
    else
        echo -e "║  ${RED}❌ PalServer: 중지됨${BLUE}              ║"
    fi
    
    echo -e "╠════════════════════════════════════╣"
    echo -e "║  ${CYAN}📝 로그 파일: ${BLUE}                   ║"
    echo -e "║  ${CYAN}$(echo "$DAILY_LOG_FILE" | cut -c1-30)${BLUE} ║"
    echo -e "╚════════════════════════════════════╝${NC}"
    echo ""
}

# 함수: 서버 실행 중일 때 메뉴
server_running_menu() {
    echo -e "${PURPLE}╔════════════════════════════════════╗"
    echo -e "║     PalWorld 서버 관리 메뉴      ║"
    echo -e "╠════════════════════════════════════╣"
    echo -e "║  ${WHITE}1. ${RED}🔴 서버 중지${PURPLE}                   ║"
    echo -e "║  ${WHITE}2. ${CYAN}📋 로그 보기${PURPLE}                   ║"
    echo -e "║  ${WHITE}3. ${YELLOW}🚫 스크립트 종료${PURPLE}               ║"
    echo -e "╚════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${BOLD}${CYAN}"
    read -p "선택해주세요 (1-3): " choice
    echo -e "${NC}"
    
    case $choice in
        1)
            stop_server
            ;;
        2)
            show_logs
            server_running_menu
            ;;
        3)
            print_color "${YELLOW}" "⚠️  스크립트를 종료합니다."
            exit 0
            ;;
        *)
            print_color "${RED}" "❌ 잘못된 선택입니다. 1-3 사이의 숫자를 입력해주세요."
            server_running_menu
            ;;
    esac
}

# 함수: 서버 중지 시 메뉴
server_stopped_menu() {
    echo -e "${PURPLE}╔════════════════════════════════════╗"
    echo -e "║     PalWorld 서버 관리 메뉴      ║"
    echo -e "╠════════════════════════════════════╣"
    echo -e "║  ${WHITE}1. ${GREEN}🚀 서버 시작${PURPLE}                   ║"
    echo -e "║  ${WHITE}2. ${CYAN}📋 로그 보기${PURPLE}                   ║"
    echo -e "║  ${WHITE}3. ${YELLOW}🚫 스크립트 종료${PURPLE}               ║"
    echo -e "╚════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${BOLD}${CYAN}"
    read -p "선택해주세요 (1-3): " choice
    echo -e "${NC}"
    
    case $choice in
        1)
            start_server
            ;;
        2)
            show_logs
            server_stopped_menu
            ;;
        3)
            print_color "${YELLOW}" "⚠️  스크립트를 종료합니다."
            exit 0
            ;;
        *)
            print_color "${RED}" "❌ 잘못된 선택입니다. 1-3 사이의 숫자를 입력해주세요."
            server_stopped_menu
            ;;
    esac
}

# 메인 함수
main() {
    # 화면 초기화
    clear
    
    # 헤더 출력
    echo -e "${BLUE}"
    echo "██████╗  █████╗ ██╗     ██╗    ██╗    ██╗ ██████╗ ██████╗ ██╗     ██████╗ "
    echo "██╔══██╗██╔══██╗██║     ██║    ██║    ██║██╔═══██╗██╔══██╗██║     ██╔══██╗"
    echo "██████╔╝███████║██║     ██║    ██║ █╗ ██║██║   ██║██████╔╝██║     ██║  ██║"
    echo "██╔═══╝ ██╔══██║██║     ██║    ██║███╗██║██║   ██║██╔══██╗██║     ██║  ██║"
    echo "██║     ██║  ██║███████╗███████║╚███╔███╔╝╚██████╔╝██║  ██║███████╗██████╔╝"
    echo "╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝ ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═════╝ "
    echo -e "${NC}"
    echo ""
    
    # 서버 상태 확인
    local pal_status=$(check_pal_server_process)
    local fex_status=$(check_fex_emu_process)
    local binary_status=$(check_pal_binary_process)
    
    # 서버 상태 표시
    show_server_status
    
    # 메뉴 표시
    if [ "$pal_status" = "RUNNING" ] || [ "$fex_status" = "RUNNING" ] || [ "$binary_status" = "RUNNING" ]; then
        print_color "${GREEN}" "✅ 서버가 실행 중입니다."
        server_running_menu
    else
        print_color "${YELLOW}" "⚠️  서버가 실행 중이 아닙니다."
        server_stopped_menu
    fi
}

# 스크립트 실행
main
