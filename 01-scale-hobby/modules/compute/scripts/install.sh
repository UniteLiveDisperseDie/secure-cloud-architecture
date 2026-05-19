#!/bin/bash

# 1. 시스템 업데이트 및 패키지 설치
yum update -y
yum install -y amazon-ssm-agent mariadb-server unzip

# 2. SSM 에이전트 시작
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# 3. Docker 설치 및 시작
amazon-linux-extras install docker -y
systemctl enable docker
systemctl start docker

# 4. MariaDB 시작
systemctl enable mariadb
systemctl start mariadb

# 5. MariaDB localhost 전용 바인딩 (외부 접근 차단)
echo "[mysqld]
bind-address=127.0.0.1" > /etc/my.cnf.d/server.cnf

systemctl restart mariadb