#!/bin/bash
# 수동 페일오버 명령어 가이드

# === 수동 페일오버 절차 ===
# 주의: 클러스터가 정상 상태일 때만 실행

# 1. 현재 상태 확인
#    [10.164.32.93 모니터링 서버에서 실행]
#    docker exec -it rtt-postgres-monitor pg_autoctl show state --pgdata /var/lib/postgresql/data

# 2. 수동 페일오버 실행
#    [10.164.32.93 모니터링 서버에서 실행]  
#    docker exec -it rtt-postgres-monitor pg_autoctl perform failover --pgdata /var/lib/postgresql/data

# 3. 페일오버 대기 (20초)
#    sleep 20

# 4. 페일오버 후 상태 확인
#    [10.164.32.93 모니터링 서버에서 실행]
#    docker exec -it rtt-postgres-monitor pg_autoctl show state --pgdata /var/lib/postgresql/data