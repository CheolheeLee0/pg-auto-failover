#!/bin/bash
# 페일오버 테스트 가이드

# === 페일오버 테스트 절차 ===
# 각 단계별로 해당 서버에서 실행하세요.

# 1. 초기 상태 확인
#    [10.164.32.93 모니터링 서버에서 실행]
#    docker exec -it rtt-postgres-monitor pg_autoctl show state --pgdata /var/lib/postgresql/data

# 2. Primary 서버 중지 (페일오버 트리거)
#    [10.164.32.91 운영1서버에서 실행]
#    docker stop rtt-postgres

# 3. 페일오버 대기 (60초)
#    sleep 60

# 4. 페일오버 후 상태 확인
#    [10.164.32.93 모니터링 서버에서 실행]
#    docker exec -it rtt-postgres-monitor pg_autoctl show state --pgdata /var/lib/postgresql/data

# 5. 새 Primary 연결 테스트
#    [10.164.32.92 운영2서버에서 실행]
#    docker exec -it rtt-postgres pg_isready -h localhost -p 5432 -U postgres

# 6. 원래 서버 재시작
#    [10.164.32.91 운영1서버에서 실행]
#    docker start rtt-postgres

# 7. 복구 대기 (30초)
#    sleep 30

# 8. 최종 상태 확인
#    [10.164.32.93 모니터링 서버에서 실행]
#    docker exec -it rtt-postgres-monitor pg_autoctl show state --pgdata /var/lib/postgresql/data