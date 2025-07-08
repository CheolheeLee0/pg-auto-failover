# PostgreSQL Auto-Failover 테스트 가이드

## 🧪 페일오버 테스트

### 실행 방법
```bash
./test/simple-failover-test.sh
```

### 테스트 내용
- 자동 페일오버 동작 확인
- 5초 간격 실시간 모니터링
- 정확한 페일오버 시간 측정
- 성능 등급 자동 평가

## 📊 최신 테스트 결과
- **페일오버 시간**: 55초
- **성능 등급**: 🥇 양호 (60초 이내)
- **자동화 수준**: 완전 자동 페일오버

## 🛑 테스트 정리
```bash
docker compose -f test/docker-compose.yml down
```

상세한 테스트 결과는 `FINAL_TEST_REPORT.md` 파일을 참조하세요.