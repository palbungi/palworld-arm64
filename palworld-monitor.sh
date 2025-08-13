#!/bin/bash

CONTAINER_NAME="palworld-server"
LOG_PATH="/home/ubuntu/docker-palworld-server/monitor_logs"
ERROR_PATTERN="API request timeout|API request final failure"
COMPOSE_FILE="/home/ubuntu/docker-palworld-server/docker-compose.yml"

# 감시 주기 설정 (초 단위)
CHECK_INTERVAL=30
# 오류 카운트 초기화
error_count=0
# 재시작 임계값
RESTART_THRESHOLD=5
# 마지막 재시작 시간
last_restart=0
# 재시작 쿨다운 (300초 = 5분)
COOLDOWN_PERIOD=300
# 낮은 리소스 카운트
low_resource_count=0
# 낮은 리소스 임계값 (1분 = 60초 / CHECK_INTERVAL)
LOW_RESOURCE_THRESHOLD=$((60 / CHECK_INTERVAL))

mkdir -p "$LOG_PATH"

# bc 명령어 존재 확인
if ! command -v bc &> /dev/null; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] bc command not found. Low resource monitoring disabled." >> "$LOG_PATH/error.log"
    enable_resource_check=false
else
    enable_resource_check=true
fi

while true; do
    # 현재 시간 기록
    current_time=$(date +%s)

    # 컨테이너 상태 확인
    container_status=$(docker inspect -f '{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null)

    if [ "$container_status" != "running" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Container not running. Restarting..." >> "$LOG_PATH/status.log"
        docker compose -f "$COMPOSE_FILE" up -d
        last_restart=$current_time
        error_count=0
        low_resource_count=0
        sleep 60  # 재시작 후 안정화 대기
        continue
    fi

    # 오류 로그 검사 (지난 1분 동안의 로그만 확인)
    log_output=$(docker logs --since 1m "$CONTAINER_NAME" 2>&1 | grep -E "$ERROR_PATTERN")

    if [ -n "$log_output" ]; then
        ((error_count++))
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Error detected (count: $error_count)" >> "$LOG_PATH/error.log"
        echo "$log_output" >> "$LOG_PATH/error.log"
    else
        # 오류 없으면 카운트 감소 (최소 0)
        if [ $error_count -gt 0 ]; then
            ((error_count--))
        fi
    fi

    # 리소스 사용량 체크 활성화 상태에서만 실행
    if [ "$enable_resource_check" = true ]; then
        # CPU/RAM 사용량 획득
        stats_output=$(docker stats --no-stream --format "{{.CPUPerc}} {{.MemPerc}}" "$CONTAINER_NAME" 2>/dev/null | tail -n 1)
        cpu_usage=$(echo "$stats_output" | awk '{print $1}' | tr -d '%')
        mem_usage=$(echo "$stats_output" | awk '{print $2}' | tr -d '%')

        # 숫자 유효성 검사
        if [[ "$cpu_usage" =~ ^[0-9]+(\.[0-9]+)?$ ]] && [[ "$mem_usage" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            # 낮은 리소스 상태 확인 (CPU < 10% AND RAM < 5%)
            low_resource_flag=$(echo "$cpu_usage < 10 && $mem_usage < 5" | bc -l 2>/dev/null)

            if [ "$low_resource_flag" -eq 1 ]; then
                ((low_resource_count++))
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] Low resources detected: CPU=${cpu_usage}%, RAM=${mem_usage}% (count: $low_resource_count)" >> "$LOG_PATH/resource.log"
            else
                low_resource_count=0
            fi
        else
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Invalid resource data: $stats_output" >> "$LOG_PATH/error.log"
        fi
    fi

    # 재시작 조건 확인 (오류 임계값 초과 OR 낮은 리소스 지속 + 쿨다운 기간 경과)
    restart_required=false
    restart_reason=""

    if [ $error_count -ge $RESTART_THRESHOLD ]; then
        restart_required=true
        restart_reason="error count ($error_count)"
    fi

    if [ $low_resource_count -ge $LOW_RESOURCE_THRESHOLD ]; then
        restart_required=true
        restart_reason="low resources ($low_resource_count cycles)"
    fi

    if [ "$restart_required" = true ] &&
       [ $((current_time - last_restart)) -ge $COOLDOWN_PERIOD ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Restarting container ($restart_reason)" >> "$LOG_PATH/restart.log"
        docker compose -f "$COMPOSE_FILE" restart

        # 상태 리셋
        last_restart=$current_time
        error_count=0
        low_resource_count=0
        sleep 60  # 재시작 후 안정화 대기
    fi

    sleep $CHECK_INTERVAL
done

