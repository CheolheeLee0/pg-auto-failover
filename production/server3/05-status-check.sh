#!/bin/bash
# 모니터링 서버 (Server 3) - 상태 확인

set -e

# 설정 파일 로드
source /opt/pg-auto-failover/config/cluster.conf

echo "=== 모니터링 서버 상태 확인 ==="

# 컨테이너 상태 확인
echo "컨테이너 상태:"
docker ps | grep $CONTAINER_NAME-monitor

echo ""
echo "컨테이너 상세 정보:"
docker inspect $CONTAINER_NAME-monitor --format='{{.State.Status}}'

echo ""
echo "PostgreSQL 연결 상태:"
docker exec -it $CONTAINER_NAME-monitor pg_isready -h localhost -p 5432 -U postgres

echo ""
echo "Auto-Failover 클러스터 전체 상태:"
docker exec -it $CONTAINER_NAME-monitor pg_autoctl show state --pgdata /var/lib/postgresql/data

echo ""
echo "컨테이너 로그 (최근 20줄):"
docker logs --tail 20 $CONTAINER_NAME-monitor

echo ""
echo "=== 모니터링 서버 상태 확인 완료 ==="