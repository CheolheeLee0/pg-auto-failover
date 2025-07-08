#!/bin/bash
# 운영 2번 서버 (10.164.32.92) - Docker 컨테이너 설정

set -e

# 설정 파일 로드
source /opt/pg-auto-failover/config/cluster.conf

echo "=== 운영 2번 서버 Docker 컨테이너 설정 ==="

# 기존 컨테이너 정리
echo "기존 컨테이너 정리 중..."
docker stop $CONTAINER_NAME 2>/dev/null || true
docker rm $CONTAINER_NAME 2>/dev/null || true

# 데이터 볼륨 생성
echo "데이터 볼륨 생성 중..."
docker volume create rtt-postgres-data

# Docker 컨테이너 실행
echo "PostgreSQL Auto-Failover 컨테이너 실행 중..."
docker run -d \
    --name $CONTAINER_NAME \
    --restart unless-stopped \
    -p 5432:5432 \
    -v rtt-postgres-data:/var/lib/postgresql/data \
    -v /var/log/pg-auto-failover:/var/log/pg-auto-failover \
    -e POSTGRES_PASSWORD=postgres \
    -e PGUSER=postgres \
    -e PGPASSWORD=postgres \
    -e PG_AUTOCTL_HBA_LAN=true \
    -e PG_AUTOCTL_AUTH_METHOD=trust \
    citusdata/pg_auto_failover:latest \
    bash -c "sleep 15 && sudo -u postgres pg_autoctl create postgres --pgdata /var/lib/postgresql/data --pgport 5432 --username postgres --dbname $DB_NAME --hostname $DB_SERVER_2 --auth trust --monitor postgres://autoctl_node@$MONITOR_SERVER:$MONITOR_PORT/pg_auto_failover --no-ssl --candidate-priority 50 --run"

# 컨테이너 상태 확인
echo "컨테이너 상태 확인 중..."
sleep 10
docker ps | grep $CONTAINER_NAME

echo "=== 운영 2번 서버 Docker 컨테이너 설정 완료 ==="