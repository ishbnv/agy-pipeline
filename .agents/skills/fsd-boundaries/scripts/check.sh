#!/usr/bin/env bash
# Проверка архитектурных границ Feature-Sliced Design (FSD)
set -uo pipefail

TARGET_DIR="${1:-apps/web/src}"

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "ℹ️ Директория $TARGET_DIR не найдена. Пропускаем проверку FSD."
  exit 0
fi

echo "🔍 Проверяем границы FSD в $TARGET_DIR..."
FAIL=0

# Проверка 1: Запрет на импорт вышестоящих слоев
if [[ -d "$TARGET_DIR/entities" ]]; then
  if grep -rnE "from ['\"]@/(features|widgets|pages|app)['\"]" "$TARGET_DIR/entities" 2>/dev/null; then
    echo "❌ ОШИБКА: Обнаружен импорт вышестоящего слоя из entities!"
    FAIL=1
  fi
fi

if [[ -d "$TARGET_DIR/features" ]]; then
  if grep -rnE "from ['\"]@/(widgets|pages|app)['\"]" "$TARGET_DIR/features" 2>/dev/null; then
    echo "❌ ОШИБКА: Обнаружен импорт вышестоящего слоя из features!"
    FAIL=1
  fi
fi

if [[ -d "$TARGET_DIR/widgets" ]]; then
  if grep -rnE "from ['\"]@/(pages|app)['\"]" "$TARGET_DIR/widgets" 2>/dev/null; then
    echo "❌ ОШИБКА: Обнаружен импорт вышестоящего слоя из widgets!"
    FAIL=1
  fi
fi

# Проверка 2: Запрет на глубокие кросс-слайсовые импорты (в обход публичного API index.ts)
# Ищет импорты вида: from '@/features/some-feature/ui/...' или from '@/entities/user/model/...'
if grep -rnE "from ['\"]@/(features|entities|widgets)/[^/'\"]+/[^'\"]+['\"]" "$TARGET_DIR" 2>/dev/null; then
  echo "❌ ОШИБКА: Найден глубокий импорт в обход публичного API слайса (index.ts)!"
  FAIL=1
fi

if [[ $FAIL -eq 0 ]]; then
  echo "✅ FSD границы не нарушены."
  exit 0
else
  echo "🛑 Исправь нарушения FSD перед продолжением."
  exit 1
fi
