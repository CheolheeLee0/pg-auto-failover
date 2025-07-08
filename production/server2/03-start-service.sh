#!/bin/bash
# 운영 2번 서버 (10.164.32.92) - 서비스 시작

set -e

# 설정 파일 로드
source /opt/pg-auto-failover/config/cluster.conf

echo "=== 운영 2번 서버 서비스 시작 ==="

# 컨테이너 시작
echo "컨테이너 시작 중..."
docker start $CONTAINER_NAME

# 서비스 준비 대기
echo "서비스 준비 대기 중..."
sleep 30

# 서비스 상태 확인
echo "서비스 상태 확인 중..."
docker exec -it $CONTAINER_NAME pg_autoctl show state --pgdata /var/lib/postgresql/data

# 연결 테스트
echo "연결 테스트 중..."
docker exec -it $CONTAINER_NAME pg_isready -h localhost -p 5432 -U postgres

echo "=== 운영 2번 서버 서비스 시작 완료 ==="