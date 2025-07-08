#!/bin/bash
# 모니터링 서버 (Server 3) - 모니터 컨테이너 중지

set -e

# 설정 파일 로드
source /opt/pg-auto-failover/config/cluster.conf

echo "=== 모니터링 서버 컨테이너 중지 ==="

# 컨테이너 정상 중지
echo "모니터 컨테이너 정상 중지 중..."
docker stop $CONTAINER_NAME-monitor

# 컨테이너 상태 확인
echo "컨테이너 상태 확인 중..."
docker ps -a | grep $CONTAINER_NAME-monitor

echo "=== 모니터링 서버 중지 완료 ==="