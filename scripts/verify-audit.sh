#!/usr/bin/env bash
set -euo pipefail
cd /home/devops/kr2
unset REDIS_PASSWORD
exec > >(tee /home/devops/kr2-evidence/05-audit-negative.log) 2>&1
sudo -v
audit=/home/devops/devops-course-2026/scripts/audit.sh
backup="$(mktemp /home/devops/kr2-evidence/compose-safe.XXXXXX)"
cp docker-compose.yml "$backup"
restore() {
    cp "$backup" docker-compose.yml
    docker compose up -d --wait --wait-timeout 90
}
trap restore EXIT
sed -i 's/127\.0\.0\.1:8001:8001/8001:8001/' docker-compose.yml
docker compose up -d --wait --wait-timeout 90
docker compose port app 8001
set +e
"$audit"
negative_code=$?
set -e
echo "audit exposed port exit=$negative_code"
test "$negative_code" -eq 1
restore
trap - EXIT
"$audit"
echo 'audit restored exit=0'
docker compose port app 8001
diff <(sudo ufw status numbered) /home/devops/ufw-before-kr2.txt
echo 'Правила UFW не изменены'
echo KR2_AUDIT_TEST_READY
