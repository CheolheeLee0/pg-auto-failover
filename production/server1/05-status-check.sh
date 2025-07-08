#!/bin/bash
# 운영 1번 서버 (10.164.32.91) - 상태 확인

set -e

# 설정 파일 로드
source /opt/pg-auto-failover/config/cluster.conf

echo "=== 운영 1번 서버 상태 확인 ==="

# 컨테이너 상태 확인
echo "컨테이너 상태:"
docker ps | grep $CONTAINER_NAME

echo ""
echo "컨테이너 상세 정보:"
docker inspect $CONTAINER_NAME --format='{{.State.Status}}'

echo ""
echo "PostgreSQL 연결 상태:"
docker exec -it $CONTAINER_NAME pg_isready -h localhost -p 5432 -U postgres

echo ""
echo "Auto-Failover 상태:"
docker exec -it $CONTAINER_NAME pg_autoctl show state --pgdata /var/lib/postgresql/data

echo ""
echo "컨테이너 로그 (최근 20줄):"
docker logs --tail 20 $CONTAINER_NAME

echo ""
echo "=== 운영 1번 서버 상태 확인 완료 ==="