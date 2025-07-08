#!/bin/bash
# PostgreSQL Auto-Failover 클러스터 설정 가이드

# 1단계: 모든 서버에서 통합 설치
# 운영 1번 서버 (10.164.32.91)에서: ./server1/01-install-all.sh
# 운영 2번 서버 (10.164.32.92)에서: ./server2/01-install-all.sh  
# 모니터링 서버 (10.164.32.93)에서: ./server3/01-install-all.sh

# 2단계: 모니터링 서버 설정 (10.164.32.93에서)
# ./server3/02-configure-monitor.sh
# ./server3/03-start-monitor.sh

# 3단계: 운영 1번 서버 설정 (10.164.32.91에서)
# ./server1/02-setup-docker-container.sh
# ./server1/03-start-service.sh

# 4단계: 운영 2번 서버 설정 (10.164.32.92에서)
# ./server2/02-setup-docker-container.sh
# ./server2/03-start-service.sh

# 5단계: 클러스터 상태 확인 (모니터링 서버에서)
# docker exec -it rtt-postgres-monitor sudo -u postgres pg_autoctl show state --pgdata /var/lib/postgresql/data

# 각 단계 사이에 30초씩 대기