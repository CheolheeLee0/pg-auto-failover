#!/bin/bash
# 모니터링 서버 (Server 3) - 모니터 컨테이너 시작

set -e

# 설정 파일 로드
source /opt/pg-auto-failover/config/cluster.conf

echo "=== 모니터링 서버 컨테이너 시작 ==="

# 컨테이너 시작
echo "모니터 컨테이너 시작 중..."
docker start $CONTAINER_NAME-monitor

# 서비스 준비 대기
echo "서비스 준비 대기 중..."
sleep 20

# 서비스 상태 확인
echo "서비스 상태 확인 중..."
docker exec -it $CONTAINER_NAME-monitor pg_autoctl show state --pgdata /var/lib/postgresql/data

# 연결 테스트
echo "연결 테스트 중..."
docker exec -it $CONTAINER_NAME-monitor pg_isready -h localhost -p 5432 -U postgres

echo "=== 모니터링 서버 시작 완료 ==="