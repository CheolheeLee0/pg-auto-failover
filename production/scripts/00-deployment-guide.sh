#!/bin/bash
# PostgreSQL Auto-Failover 배포 가이드
# 서버 구성: 10.164.32.91(Master), 10.164.32.92(Slave), 10.164.32.93(Monitor)

# 1단계: 파일 확인 (각 서버에서)
# 모니터링 서버: ./server3/00-check-files.sh
# 운영 1번 서버: ./server1/00-check-files.sh  
# 운영 2번 서버: ./server2/00-check-files.sh

# 2단계: 통합 설치 (각 서버에서)
# 모니터링 서버: ./server3/01-install-all.sh
# 운영 1번 서버: ./server1/01-install-all.sh
# 운영 2번 서버: ./server2/01-install-all.sh

# 3단계: 모니터링 서버 설정 (10.164.32.93에서)
# ./server3/02-configure-monitor.sh
# ./server3/03-start-monitor.sh

# 4단계: 운영 1번 서버 설정 (10.164.32.91에서)  
# ./server1/02-setup-docker-container.sh
# ./server1/03-start-service.sh

# 5단계: 운영 2번 서버 설정 (10.164.32.92에서)
# ./server2/02-setup-docker-container.sh  
# ./server2/03-start-service.sh

# 6단계: 상태 확인 (모니터링 서버에서)
# docker exec -it rtt-postgres-monitor sudo -u postgres pg_autoctl show state --pgdata /var/lib/postgresql/data

# 주요 명령어
# 상태 확인: ./scripts/03-cluster-status.sh
# 페일오버 테스트: ./scripts/05-failover-test.sh  
# 클러스터 중지: ./scripts/04-cluster-stop.sh

# 주의: 각 단계 사이 30초 대기, 모니터링 서버 우선 설정