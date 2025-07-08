# 운영 서버 환경

## 서버 구성
- **운영 1번**: 10.164.32.91 (Master)
- **운영 2번**: 10.164.32.92 (Slave)  
- **모니터링**: 10.164.32.93 (Monitor)

## 설치 순서

### 1. 파일 확인 (각 서버에서)
```bash
# 모니터링 서버: ./server3/00-check-files.sh
# 운영 1번 서버: ./server1/00-check-files.sh  
# 운영 2번 서버: ./server2/00-check-files.sh
```

### 2. 통합 설치 (각 서버에서)
```bash
# 모니터링 서버: ./server3/01-install-all.sh
# 운영 1번 서버: ./server1/01-install-all.sh
# 운영 2번 서버: ./server2/01-install-all.sh
```

### 3. 서비스 설정
```bash
# 모니터링 서버 (10.164.32.93에서)
./server3/02-configure-monitor.sh
./server3/03-start-monitor.sh

# 운영 1번 서버 (10.164.32.91에서)  
./server1/02-setup-docker-container.sh
./server1/03-start-service.sh

# 운영 2번 서버 (10.164.32.92에서)
./server2/02-setup-docker-container.sh  
./server2/03-start-service.sh
```

## 관리 명령어

### 상태 확인
```bash
# 클러스터 전체 상태 (모니터링 서버에서)
docker exec -it rtt-postgres-monitor sudo -u postgres pg_autoctl show state --pgdata /var/lib/postgresql/data
```

### 페일오버 테스트  
```bash
# Primary 서버 중지 (운영 1번 서버에서)
docker stop rtt-postgres

# 상태 확인 (모니터링 서버에서)
docker exec -it rtt-postgres-monitor sudo -u postgres pg_autoctl show state --pgdata /var/lib/postgresql/data
```

### 서비스 중지
```bash
# 운영 2번 → 운영 1번 → 모니터링 순서로 중지
docker stop rtt-postgres        # 운영 서버들
docker stop rtt-postgres-monitor # 모니터링 서버
```