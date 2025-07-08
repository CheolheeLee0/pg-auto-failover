#!/bin/bash
# PostgreSQL Auto-Failover 테스트

set -e

echo "=== PostgreSQL Auto-Failover 테스트 시작 ==="

# 환경 초기화
docker compose -f test/docker-compose.yml down
docker compose -f test/docker-compose.yml up -d --remove-orphans

# 초기화 대기
echo "클러스터 초기화 대기 (40초)..."
sleep 40

# 1. 초기 상태 확인
echo ""
echo "1. 초기 클러스터 상태"
docker exec pg-monitor-test sudo -u postgres pg_autoctl show state --pgdata /tmp/pgdata/monitor

# 2. Primary 노드 중지 및 시간 측정
echo ""
echo "2. 페일오버 테스트 시작"
START_TIME=$(date +%s)
echo "Primary 노드 중지 시간: $(date)"
docker stop postgres-db1-test

# 3. 5초 간격 모니터링
echo ""
echo "3. 페일오버 진행 모니터링 (5초 간격)"
FAILOVER_COMPLETED=false

for i in {1..20}; do
    ELAPSED=$((i * 5))
    echo ""
    echo "--- ${ELAPSED}초 경과 ---"
    
    STATE=$(docker exec pg-monitor-test sudo -u postgres pg_autoctl show state --pgdata /tmp/pgdata/monitor 2>/dev/null || echo "상태 확인 실패")
    echo "$STATE"
    
    # 페일오버 완료 확인
    if echo "$STATE" | grep -q "postgres-db2.*primary"; then
        echo "🎉 페일오버 완료! db2가 Primary로 승격 (${ELAPSED}초)"
        FAILOVER_COMPLETED=true
        FAILOVER_TIME=$ELAPSED
        break
    fi
    
    sleep 5
done

# 4. 결과 분석
END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))

echo ""
echo "4. 테스트 결과"
if [ "$FAILOVER_COMPLETED" = true ]; then
    echo "✅ 페일오버 성공"
    echo "📊 페일오버 시간: ${FAILOVER_TIME}초"
    
    # 성능 등급
    if [ $FAILOVER_TIME -le 30 ]; then
        echo "🏆 성능 등급: 우수"
    elif [ $FAILOVER_TIME -le 60 ]; then
        echo "🥇 성능 등급: 양호"
    else
        echo "🥈 성능 등급: 보통"
    fi
else
    echo "❌ 페일오버 실패 (100초 초과)"
fi

# 5. 연결 테스트
echo ""
echo "5. 새로운 Primary 연결 테스트"
if docker exec postgres-db2-test pg_isready -h localhost -p 5432 -U postgres > /dev/null 2>&1; then
    echo "✅ 연결 성공"
else
    echo "❌ 연결 실패"
fi

echo ""
echo "=== 테스트 완료 ==="