#!/bin/bash
# 운영 2번 서버 (10.164.32.92) - 서비스 중지

set -e

# 설정 파일 로드
source /opt/pg-auto-failover/config/cluster.conf

echo "=== 운영 2번 서버 서비스 중지 ==="

# 컨테이너 정상 중지
echo "컨테이너 정상 중지 중..."
docker stop $CONTAINER_NAME

# 컨테이너 상태 확인
echo "컨테이너 상태 확인 중..."
docker ps -a | grep $CONTAINER_NAME

echo "=== 운영 2번 서버 서비스 중지 완료 ==="