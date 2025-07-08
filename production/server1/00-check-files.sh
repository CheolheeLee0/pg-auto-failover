#!/bin/bash
# 운영 1번 서버 (10.164.32.91) - 필수 파일 존재 확인

echo "=== 운영 1번 서버 필수 파일 확인 ==="

# 체크할 파일 및 디렉토리 목록
FILES_TO_CHECK=(
    "/opt/pg-auto-failover/config/cluster.conf"
    "/opt/pg-auto-failover/server1/01-install-all.sh"
    "/opt/pg-auto-failover/server1/02-setup-docker-container.sh"
    "/opt/pg-auto-failover/server1/03-start-service.sh"
    "/opt/pg-auto-failover/server1/04-stop-service.sh"
    "/opt/pg-auto-failover/server1/05-status-check.sh"
    "/var/log/pg-auto-failover"
)

MISSING_FILES=()

for file in "${FILES_TO_CHECK[@]}"; do
    if [ -e "$file" ]; then
        echo "✓ $file - 존재함"
    else
        echo "✗ $file - 없음"
        MISSING_FILES+=("$file")
    fi
done

echo ""
echo "=== Docker 상태 확인 ==="
if command -v docker &> /dev/null; then
    echo "✓ Docker - 설치됨"
    docker --version
    
    # Docker 서비스 상태 확인
    if systemctl is-active --quiet docker; then
        echo "✓ Docker 서비스 - 실행 중"
    else
        echo "✗ Docker 서비스 - 중지됨"
    fi
else
    echo "✗ Docker - 설치되지 않음"
    MISSING_FILES+=("Docker")
fi

echo ""
echo "=== PostgreSQL 클라이언트 확인 ==="
if command -v psql &> /dev/null; then
    echo "✓ PostgreSQL 클라이언트 - 설치됨"
    psql --version
else
    echo "✗ PostgreSQL 클라이언트 - 설치되지 않음"
    MISSING_FILES+=("PostgreSQL Client")
fi

echo ""
echo "=== 볼륨 확인 ==="
if docker volume ls | grep -q "rtt-postgres-data"; then
    echo "✓ Docker 볼륨 rtt-postgres-data - 존재함"
else
    echo "○ Docker 볼륨 rtt-postgres-data - 없음 (정상, 설치 시 생성됨)"
fi

echo ""
echo "=== 컨테이너 확인 ==="
if docker ps -a | grep -q "rtt-postgres"; then
    echo "✓ 컨테이너 rtt-postgres - 존재함"
    docker ps -a | grep rtt-postgres
else
    echo "○ 컨테이너 rtt-postgres - 없음 (정상, 설치 시 생성됨)"
fi

echo ""
if [ ${#MISSING_FILES[@]} -eq 0 ]; then
    echo "✓ 모든 필수 파일이 존재합니다!"
    echo "다음 단계: ./server1/01-install-all.sh 실행"
else
    echo "✗ 누락된 파일/항목이 있습니다:"
    for missing in "${MISSING_FILES[@]}"; do
        echo "  - $missing"
    done
    echo ""
    echo "누락된 파일을 확인하고 다시 시도하세요."
fi

echo ""
echo "=== 운영 1번 서버 파일 확인 완료 ==="