# Контрольная работа 2

Вариант 1. Студент: Абалаев Никита, группа ЭФБО-11-24.

Приложение Flask с Redis публикуется через Nginx по адресу https://api.devops.local.
Исходный шаблон: https://gitverse.ru/dgimatdinov/kr2-template, ветка main.

## Конфигурация

- Сервер: devops-vm, Ubuntu 24.04 ARM64, адрес Host-only 192.168.56.3.
- Базовый образ приложения: python:3.12-slim, закреплённый digest из ПР7.
- Приложение слушает 0.0.0.0:8001 внутри контейнера от пользователя app.
- Docker публикует приложение только на 127.0.0.1:8001 Ubuntu.
- Redis: официальный redis:7-alpine, имя сервиса redis, AOF и том kr2_redis_data.
- PostgreSQL и приложение ПР7 остаются отдельным проектом в /home/devops/app.
- Секрет генерируется только на VM; в репозитории его нет. Старый пароль шаблона в истории main считается раскрытым и не используется.

## Доставка с Mac

```bash
rsync -avz --delete --exclude=.env --exclude=.git --dry-run ./ devops:kr2/
rsync -avz --delete --exclude=.env --exclude=.git ./ devops:kr2/
```

Исключения сохраняют серверный .env и не доставляют историю Git с паролем шаблона.

## Первый запуск на VM

Не экспортировать REDIS_PASSWORD в оболочке: подстановка Compose и env_file должны читать один серверный файл. При наличии старого проекта нельзя перезаписывать .env: пароль должен соответствовать работающему Redis.

```bash
cd ~/kr2
unset REDIS_PASSWORD
umask 077
# Только для нового развёртывания без .env:
test ! -e .env && { printf 'REDIS_PASSWORD='; openssl rand -hex 16; } > .env
chmod 600 .env
docker compose up -d --build --wait
docker compose ps
```

Не выполнять docker compose config и полный docker inspect с записью в отчёт: подставленный пароль виден в аргументах Redis и окружении контейнеров. Доступ к группе docker эквивалентен административному.

## Публикация

Файл deploy/nginx/kr2.conf устанавливается отдельно как /etc/nginx/sites-available/kr2. Скрипт scripts/admin-setup.sh создаёт сертификат с SAN=DNS:api.devops.local, устанавливает конфигурацию, проверяет nginx -t и выполняет reload. Существующий devops-site и UFW не меняются. Закрытый ключ остаётся на сервере с владельцем root и правами 600.

На Mac запись в /etc/hosts: `192.168.56.3 api.devops.local`. Публичный сертификат копируется в ~/kr2.crt, закрытый ключ не копируется.

```bash
curl -I http://api.devops.local/
curl --cacert ~/kr2.crt https://api.devops.local/
curl --cacert ~/kr2.crt https://api.devops.local/whoami
curl --cacert ~/devops.crt https://devops.local/app/
```

## Аудит

scripts/audit.sh сохраняет разделы 1–5 предыдущих работ и добавляет раздел 6 с пятью проверками КР2. На сервере этот файл устанавливается также в ~/devops-course-2026/scripts/audit.sh, чтобы команда допуска оставалась прежней.

scripts/verify-audit.sh временно публикует 8001 на всех адресах, ожидает код аудита 1, возвращает исходную конфигурацию и ожидает код 0. Обработчик EXIT восстанавливает безопасную публикацию даже при ошибке. Флаг down -v не используется, данные Redis сохраняются.

Таблица дефектов: docs/template-review.md. Материалы к защите: docs/defense.md. Pull Request из kr2/variant-1 в main не объединяется до защиты.
