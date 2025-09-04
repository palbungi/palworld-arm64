#!/usr/bin/env bash

# =============================================================================
# Settings
# =============================================================================
YAML_FILE="/home/ubuntu/palworld-arm64/docker-compose.yml"
CONTAINER_NAME="palworld-arm64"
RCON_PASSWORD=""
LOG_FILE="/home/ubuntu/palworld-arm64/server.log"

# =============================================================================
# Logging function
# =============================================================================
log() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] $1" | tee -a "$LOG_FILE"
}

# =============================================================================
# RCON command transmission function
# =============================================================================
rcon_send() {
    log "RCON command execution: $1"
    docker exec -i "${CONTAINER_NAME}" rcon-cli \
        --host localhost \
        --port 25575 \
        --password "${RCON_PASSWORD}" \
        "$1" 2>&1 | tee -a "$LOG_FILE"
    return ${PIPESTATUS[0]}
}

# =============================================================================
# Restart notification broadcast function
# =============================================================================
broadcast_restart() {
    local time=$1
    rcon_send "Broadcast Server_will_restart_in_${time}"
}

# =============================================================================
# Main process (including log recording)
# =============================================================================
{
    log "===== Server restart process started ====="

    # 5 minutes before notification
    broadcast_restart "5_minutes"
    sleep 120  # Wait 2 minutes

    # 3 minutes before notification
    broadcast_restart "3_minutes"
    sleep 60   # Wait 1 minute

    # 2 minutes before notification
    broadcast_restart "2_minutes"
    sleep 60   # Wait 1 minute

    # 1 minute before notification and save
    broadcast_restart "1_minutes"
    rcon_send "save"  # Save game
    sleep 50  # Wait 50 seconds

    # 10 seconds before notification and final save
    broadcast_restart "10_seconds"
    rcon_send "save"  # Final save
    sleep 5   # Wait 5 seconds

    # Countdown in seconds (5~1)
    for i in {5..1}; do
        broadcast_restart "${i}_seconds"
        sleep 1
    done

    # Server restart process
    docker-compose -f "${YAML_FILE}" pull 2>&1 | tee -a "$LOG_FILE"

    docker-compose -f "${YAML_FILE}" restart 2>&1 | tee -a "$LOG_FILE"

    log "===== Server restart process complete ====="
} 2>&1 | while IFS= read -r line; do
    # Add timestamp to all output
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] ${line}" >> "$LOG_FILE"
done

Translated with DeepL.com (free version)
