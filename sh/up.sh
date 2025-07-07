#!/bin/bash

# PostgreSQL Auto-Failover 배포 스크립트
# 로그 파일 경로 설정
LOG_FILE="./deployment.log"

# 로그 함수 정의: 콘솔과 파일에 동시에 로그 출력
log() {
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$message"
    echo "$message" >> "$LOG_FILE"
}

START_TIME=$(date +%s.%N)
log "PostgreSQL Auto-Failover 배포 스크립트 시작"

# 서버 설정
SSH_HOST="ai-docker"
REMOTE_DIR="~/pg-auto-failover"
log "변수 설정 완료 - 대상 서버: $SSH_HOST"

# 현재 디렉토리 저장
CURRENT_DIR=$(pwd)
log "현재 디렉토리: $CURRENT_DIR"

# pg-auto-failover 프로젝트 디렉토리로 이동
cd /Users/icheolhui/Mirror/Github/1_Projects/pg-auto-failover

log "PostgreSQL Auto-Failover 파일 복사 시작"
# 원격 서버에 디렉토리가 없으면 생성
sshpass -p "$SSH_PASS" ssh $SSH_HOST "mkdir -p $REMOTE_DIR"

# pg-auto-failover 프로젝트 파일 복사
sshpass -p "$SSH_PASS" rsync -avz --delete ./ $SSH_HOST:$REMOTE_DIR \
    --exclude .git \
    --exclude .gitignore \
    --exclude README.md \
    --exclude "*.log" \
    --exclude __pycache__ \
    --exclude "*.pyc" \
    --exclude "*.pyo" \
    --exclude .pytest_cache \
    --exclude .coverage \
    --exclude htmlcov \
    --exclude .tox \
    --exclude .venv \
    --exclude venv \
    --exclude dist \
    --exclude build \
    --exclude "*.egg-info"

log "PostgreSQL Auto-Failover 파일 복사 완료"

log "원격 서버에 SSH 접속하여 배포 시작"
sshpass -p "$SSH_PASS" ssh $SSH_HOST << EOF
    cd $REMOTE_DIR
    
    # 스크립트 실행 권한 부여
    chmod +x setup-*.sh
    chmod +x test/*.sh
    chmod +x sh/*.sh
    
    # 기존 컨테이너 정리
    sudo docker compose -f test/docker-compose.monitor.yml down --volumes 2>/dev/null || true
    sudo docker compose -f test/docker-compose.db1.yml down --volumes 2>/dev/null || true
    sudo docker compose -f test/docker-compose.db2.yml down --volumes 2>/dev/null || true
    
    # 사용하지 않는 Docker 볼륨 정리
    sudo docker volume prune -f
    
    # PostgreSQL Auto-Failover 클러스터 시작 (test 디렉토리에서)
    echo "Monitor 서버 시작..."
    sudo docker compose -f test/docker-compose.monitor.yml up -d
    
    # Monitor가 준비될 때까지 대기
    sleep 10
    
    echo "DB1 서버 시작..."
    sudo docker compose -f test/docker-compose.db1.yml up -d
    
    # DB1이 준비될 때까지 대기
    sleep 10
    
    echo "DB2 서버 시작..."
    sudo docker compose -f test/docker-compose.db2.yml up -d
    
    # 클러스터 상태 확인
    sleep 10
    echo "클러스터 상태 확인 중..."
    sudo docker logs pg-monitor 2>/dev/null | tail -10 || true
    
    echo "PostgreSQL Auto-Failover 클러스터 배포 완료"
    echo "Monitor: localhost:5432"
    echo "DB1: localhost:5433"  
    echo "DB2: localhost:5434"
EOF

log "원격 서버 SSH 접속 및 PostgreSQL Auto-Failover 배포 완료"

# 원래 디렉토리로 복귀
cd "$CURRENT_DIR"

END_TIME=$(date +%s.%N)
EXECUTION_TIME=$(echo "$END_TIME - $START_TIME" | bc)
log "PostgreSQL Auto-Failover 배포 스크립트 실행 완료. 총 실행 시간: $(printf "%.3f" $EXECUTION_TIME) 초"

log "배포 완료 - 클러스터 상태 확인:"
log "  Monitor: $SSH_HOST:5432"
log "  Primary DB: $SSH_HOST:5433"
log "  Secondary DB: $SSH_HOST:5434"