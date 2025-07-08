#!/bin/bash
# 클러스터 상태 확인 명령어 가이드

# === 클러스터 상태 확인 가이드 ===
# 각 서버에서 실행할 명령어들:

# 1. 전체 클러스터 상태 확인
#    [10.164.32.93 모니터링 서버에서 실행]
#    docker exec -it rtt-postgres-monitor pg_autoctl show state --pgdata /var/lib/postgresql/data

# 2. 운영 1번 서버 상태 확인
#    [10.164.32.91 서버에서 실행]
#    docker ps | grep rtt-postgres
#    docker exec -it rtt-postgres pg_isready -h localhost -p 5432 -U postgres

# 3. 운영 2번 서버 상태 확인
#    [10.164.32.92 서버에서 실행]
#    docker ps | grep rtt-postgres
#    docker exec -it rtt-postgres pg_isready -h localhost -p 5432 -U postgres

# 4. 모니터링 서버 상태 확인
#    [10.164.32.93 서버에서 실행]
#    docker ps | grep rtt-postgres-monitor
#    docker exec -it rtt-postgres-monitor pg_isready -h localhost -p 5432 -U postgres