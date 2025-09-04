#!/usr/bin/bash
YAML_FILE="/home/ubuntu/docker-palworld-server/docker-compose.yml"
CONTAINER_NAME="palworld-arm64"
RCON_PASSWORD=""

rcon_send() {
    docker exec -i "${CONTAINER_NAME}" rcon-cli --host localhost --port 25575 --password "${RCON_PASSWORD}" "$1"
}

rcon_send "save"
for i in {10..1}; do
    rcon_send "Broadcast Server_will_restart_in_${i}_seconds"
    sleep 1
done
rcon_send "Broadcast Server_is_shutting_down_for_maintenance"
docker-compose -f "${YAML_FILE}" pull
docker-compose -f "${YAML_FILE}" down
