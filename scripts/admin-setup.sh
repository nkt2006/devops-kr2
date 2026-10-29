#!/usr/bin/env bash
set -euo pipefail
cd /home/devops/kr2
mkdir -p /home/devops/kr2-evidence
exec > >(tee /home/devops/kr2-evidence/04-admin.log) 2>&1
sudo -v
test -s /home/devops/ufw-before-kr2.txt
sha256sum -c /home/devops/kr2-evidence/devops-site-before.sha256
diff <(sudo ufw status numbered) /home/devops/ufw-before-kr2.txt

if [[ ! -e /etc/ssl/certs/kr2.crt ]] && ! sudo test -e /etc/ssl/private/kr2.key; then
    sudo openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
        -keyout /etc/ssl/private/kr2.key -out /etc/ssl/certs/kr2.crt \
        -subj '/CN=api.devops.local' -addext 'subjectAltName=DNS:api.devops.local'
elif [[ ! -f /etc/ssl/certs/kr2.crt ]] || ! sudo test -f /etc/ssl/private/kr2.key; then
    echo 'Неполная существующая пара сертификата и ключа; требуется проверка.'
    exit 1
fi
openssl x509 -in /etc/ssl/certs/kr2.crt -noout -checkhost api.devops.local
sudo chown root:root /etc/ssl/private/kr2.key /etc/ssl/certs/kr2.crt
sudo chmod 600 /etc/ssl/private/kr2.key
sudo chmod 644 /etc/ssl/certs/kr2.crt
if [[ -e /etc/nginx/sites-available/kr2 ]] && ! cmp -s deploy/nginx/kr2.conf /etc/nginx/sites-available/kr2; then
    echo 'Найдена другая конфигурация kr2; она не перезаписана.'
    exit 1
fi
sudo install -m 644 deploy/nginx/kr2.conf /etc/nginx/sites-available/kr2
if [[ ! -e /etc/nginx/sites-enabled/kr2 ]] && [[ ! -L /etc/nginx/sites-enabled/kr2 ]]; then
    sudo ln -s /etc/nginx/sites-available/kr2 /etc/nginx/sites-enabled/kr2
fi
test "$(readlink -f /etc/nginx/sites-enabled/kr2)" = /etc/nginx/sites-available/kr2
sudo nginx -t
sudo systemctl reload nginx

if [[ ! -f /home/devops/kr2-evidence/audit-before-kr2.sh ]]; then
    cp /home/devops/devops-course-2026/scripts/audit.sh /home/devops/kr2-evidence/audit-before-kr2.sh
fi
install -m 755 scripts/audit.sh /home/devops/devops-course-2026/scripts/audit.sh
/home/devops/devops-course-2026/scripts/audit.sh
echo 'audit normal exit=0'
diff <(sudo ufw status numbered) /home/devops/ufw-before-kr2.txt
echo 'Правила UFW не изменены'
sha256sum -c /home/devops/kr2-evidence/devops-site-before.sha256
sudo ls -l /etc/ssl/private/kr2.key /home/devops/kr2/.env
sudo ss -tlnp | grep -E ':(8001|6379)\b'
openssl x509 -in /etc/ssl/certs/kr2.crt -noout -subject -ext subjectAltName
echo KR2_ADMIN_SETUP_READY
