#!/bin/bash
# 모니터링 서버 (Server 3) - Docker 모니터 컨테이너 구성

set -e

# 설정 파일 로드
source /opt/pg-auto-failover/config/cluster.conf

echo "=== 모니터링 서버 Docker 컨테이너 구성 시작 ==="

# 기존 컨테이너 정리
echo "기존 컨테이너 정리 중..."
docker stop $CONTAINER_NAME-monitor 2>/dev/null || true
docker rm $CONTAINER_NAME-monitor 2>/dev/null || true

# 데이터 볼륨 생성
echo "모니터 데이터 볼륨 생성 중..."
docker volume create rtt-postgres-monitor-data

# 모니터 Docker 컨테이너 실행
echo "PostgreSQL Auto-Failover 모니터 컨테이너 실행 중..."
docker run -d \
    --name $CONTAINER_NAME-monitor \
    --restart unless-stopped \
    -p 5432:5432 \
    -v rtt-postgres-monitor-data:/var/lib/postgresql/data \
    -v /var/log/pg-auto-failover:/var/log/pg-auto-failover \
    -e POSTGRES_PASSWORD=postgres \
    -e PGUSER=postgres \
    -e PGPASSWORD=postgres \
    -e PG_AUTOCTL_HBA_LAN=true \
    -e PG_AUTOCTL_AUTH_METHOD=trust \
    citusdata/pg_auto_failover:latest \
    bash -c "sudo -u postgres pg_autoctl create monitor --pgdata /var/lib/postgresql/data --pgport 5432 --auth trust --no-ssl --run"

# 컨테이너 상태 확인
echo "컨테이너 상태 확인 중..."
sleep 10
docker ps | grep $CONTAINER_NAME-monitor

echo "=== 모니터링 서버 Docker 컨테이너 구성 완료 ==="