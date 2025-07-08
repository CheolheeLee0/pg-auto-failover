#!/bin/bash
# 운영 2번 서버 (10.164.32.92) - 통합 설치 스크립트

set -e

echo "=== 운영 2번 서버 (Slave) 통합 설치 시작 ==="
echo "서버 IP: 10.164.32.92"
echo "역할: Secondary/Slave 노드"
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

echo "✓ 디렉토리 설정 완료"
echo ""

# =========================
# 2. 네트워크 연결 테스트
# =========================
echo "Step 2: 네트워크 연결 테스트 중..."

echo "모니터링 서버 (10.164.32.93) 연결 테스트:"
ping -c 2 10.164.32.93 > /dev/null 2>&1 && echo "✓ 모니터링 서버 연결 성공" || echo "✗ 모니터링 서버 연결 실패"

echo "운영 1번 서버 (10.164.32.91) 연결 테스트:"
ping -c 2 10.164.32.91 > /dev/null 2>&1 && echo "✓ 운영 1번 서버 연결 성공" || echo "✗ 운영 1번 서버 연결 실패"
echo ""

# =========================
# 3. 설치 완료 확인
# =========================
echo "=== 설치 완료 확인 ==="

echo ""
echo "=== 운영 2번 서버 설치 완료 ==="
echo ""
echo "⚠️  주의사항:"
echo "1. 모니터링 서버와 운영 1번 서버가 먼저 설정되어야 합니다"
echo ""
echo "📋 다음 단계:"
echo "1. 모니터링 서버와 운영 1번 서버 설정 완료 후"
echo "2. 이 서버에서 다음 명령어 실행:"
echo "   ./server2/02-setup-docker-container.sh"
echo ""