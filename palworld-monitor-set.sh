# 모니터링 로그 디렉토리 생성
mkdir -p /home/ubuntu/docker-palworld-server/monitor_logs

# 스크립트 파일 생성
nano /home/ubuntu/palworld-monitor.sh
# 위 스크립트 내용 복사 후 저장

# 실행 권한 부여
chmod +x /home/ubuntu/palworld-monitor.sh

# Systemd 서비스 파일 생성
sudo tee /etc/systemd/system/palworld-monitor.service > /dev/null <<EOF
[Unit]
Description=Palworld Server Monitor
After=docker.service

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu
ExecStart=/home/ubuntu/palworld-monitor.sh
Restart=always
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF

# 서비스 시작
sudo systemctl daemon-reload
sudo systemctl enable palworld-monitor.service
sudo systemctl start palworld-monitor.service
