#!/usr/bin/env bash
# Проверка безопасности миграций и схемы Prisma
set -uo pipefail

CONTENT=""
if [[ $# -gt 0 && -f "$1" ]]; then
  CONTENT=$(cat "$1")
elif [[ ! -t 0 ]]; then
  CONTENT=$(cat)
fi

if [[ -z "$CONTENT" ]]; then
  echo "ℹ️ Нет данных для проверки (передайте файл или diff через stdin)."
  exit 0
fi

echo "🔍 Проверка изменений Prisma..."
FAIL=0

# Проверка 1: Запрет на DROP TABLE / DROP COLUMN
if echo "$CONTENT" | grep -Eiq "DROP\s+(TABLE|COLUMN)"; then
  echo "❌ ОШИБКА: Обнаружен DROP TABLE / DROP COLUMN. Разрушающие изменения должны идти двухфазно!"
  FAIL=1
fi

# Проверка 2: Запрещенные команды Prisma
if echo "$CONTENT" | grep -Eiq "prisma\s+migrate\s+reset|prisma\s+db\s+push"; then
  echo "❌ ОШИБКА: Запрещенные команды Prisma! В CI/prod разрешен только 'migrate deploy'."
  FAIL=1
fi

# Проверка 3: Наличие индексов для новых связей (базовая эвристика)
if echo "$CONTENT" | grep -iq "relation(" && ! echo "$CONTENT" | grep -iq "@@index"; then
  echo "⚠️ ПРЕДУПРЕЖДЕНИЕ: Добавлена relation, но в том же блоке изменений не обнаружен @@index. Убедитесь, что внешние ключи проиндексированы."
fi

if [[ $FAIL -eq 0 ]]; then
  echo "✅ Изменения базы данных соответствуют правилам безопасности."
  exit 0
else
  echo "🛑 Обнаружены критические нарушения в работе с БД!"
  exit 1
fi
