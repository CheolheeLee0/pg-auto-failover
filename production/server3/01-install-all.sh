#!/bin/bash
# 모니터링 서버 (10.164.32.93) - 통합 설치 스크립트

set -e

echo "=== 모니터링 서버 통합 설치 시작 ==="
echo "서버 IP: 10.164.32.93"
echo "역할: Monitor 노드"
echo ""

# =========================
# 1. 디렉토리 및 권한 설정
# =========================
echo "Step 1: 디렉토리 및 권한 설정 중..."

# 로그 디렉토리 생성
sudo mkdir -p /var/log/pg-auto-failover
sudo chown $USER:$USER /var/log/pg-auto-failover

# 설정 디렉토리 생성
sudo mkdir -p /opt/pg-auto-failover
sudo chown $USER:$USER /opt/pg-auto-failover

echo "✓ 디렉토리 설정 완룼"
echo ""

# =========================
# 2. 네트워크 연결 테스트
# =========================
echo "Step 2: 네트워크 연결 테스트 중..."

echo "운영 1번 서버 (10.164.32.91) 연결 테스트:"
ping -c 2 10.164.32.91 > /dev/null 2>&1 && echo "✓ 운영 1번 서버 연결 성공" || echo "✗ 운영 1번 서버 연결 실패"

echo "운영 2번 서버 (10.164.32.92) 연결 테스트:"
ping -c 2 10.164.32.92 > /dev/null 2>&1 && echo "✓ 운영 2번 서버 연결 성공" || echo "✗ 운영 2번 서버 연결 실패"
echo ""

# =========================
# 3. 방화벽 설정 (필요시)
# =========================
echo "Step 3: 방화벽 설정 확인 중..."

command -v ufw &> /dev/null && UFW_STATUS=$(sudo ufw status | grep "Status:" | awk '{print $2}') || UFW_STATUS="not_installed"

if [ "$UFW_STATUS" = "active" ]; then
    echo "UFW 방화벽이 활성화되어 있습니다."
    echo "PostgreSQL 포트 (5432) 허용 설정 중..."
    sudo ufw allow 5432
    echo "✓ 방화벽 설정 완료"
elif [ "$UFW_STATUS" = "inactive" ]; then
    echo "UFW 방화벽이 비활성화되어 있습니다."
else
    echo "UFW가 설치되어 있지 않습니다."
fi
echo ""

# =========================
# 4. 설치 완료 확인
# =========================
echo "=== 설치 완료 확인 ==="

echo ""
echo "=== 모니터링 서버 설치 완료 ==="
echo ""
echo "⚠️  주의사항:"
echo "1. 이 서버가 클러스터의 중심 역할을 합니다"
echo ""
echo "📋 다음 단계:"
echo "1. 이 서버에서 모니터 노드를 먼저 설정:"
echo "   ./server3/02-configure-monitor.sh"
echo "2. 운영 1번 서버 (10.164.32.91)로 이동하여 설치 진행"
echo "3. 운영 2번 서버 (10.164.32.92)로 이동하여 설치 진행"
echo ""