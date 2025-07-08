#!/bin/bash
# 클러스터 중지 명령어 가이드 (역순 중지)

# 1. 운영 2번 서버 (10.164.32.92)에서
# docker stop rtt-postgres

# 2. 운영 1번 서버 (10.164.32.91)에서  
# docker stop rtt-postgres

# 3. 모니터링 서버 (10.164.32.93)에서
# docker stop rtt-postgres-monitor

# 전체 상태 확인 (모든 서버에서)
# docker ps -a | grep rtt-postgres