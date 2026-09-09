#!/usr/bin/env bash
# Скрипт установки Antigravity Multi-Agent Pipeline в существующий проект
set -uo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="${1:-.}"

TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd || echo "$TARGET_DIR")"

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "❌ Ошибка: Директория '$TARGET_DIR' не существует!"
  echo "Использование: $0 /путь/к/вашему/проекту"
  exit 1
fi

echo "============================================================"
echo "🚀 Установка Antigravity Pipeline в: $TARGET_DIR"
echo "============================================================"

# 1. Создаем необходимые директории
echo "📁 Создание директорий..."
mkdir -p "$TARGET_DIR/.agents/skills"
mkdir -p "$TARGET_DIR/.agents/subagents"
mkdir -p "$TARGET_DIR/.agents/scripts"
mkdir -p "$TARGET_DIR/docs"
mkdir -p "$TARGET_DIR/scripts"

# 2. Копируем скиллы и субагентов
echo "📦 Копирование скиллов и ролей субагентов..."
cp -R "$SOURCE_DIR/.agents/skills/"* "$TARGET_DIR/.agents/skills/"
cp -R "$SOURCE_DIR/.agents/subagents/"* "$TARGET_DIR/.agents/subagents/"
cp -R "$SOURCE_DIR/.agents/scripts/"* "$TARGET_DIR/.agents/scripts/"
cp "$SOURCE_DIR/.agents/hooks.json" "$TARGET_DIR/.agents/hooks.json"

# 3. Копируем спецификацию контракта
if [[ ! -f "$TARGET_DIR/docs/acceptance-contract.md" ]]; then
  echo "📄 Копирование docs/acceptance-contract.md..."
  cp "$SOURCE_DIR/docs/acceptance-contract.md" "$TARGET_DIR/docs/acceptance-contract.md"
else
  echo "ℹ️ docs/acceptance-contract.md уже существует, пропускаем."
fi

# 4. Копируем GEMINI.md (Конституцию) если её нет
if [[ ! -f "$TARGET_DIR/GEMINI.md" ]]; then
  echo "📜 Копирование GEMINI.md (Конституции архитектуры)..."
  cp "$SOURCE_DIR/GEMINI.md" "$TARGET_DIR/GEMINI.md"
else
  echo "ℹ️ GEMINI.md уже существует, сохраняем существующую версию."
fi

# 5. Копируем скрипты автоматизации
echo "🛠 Копирование скриптов запуска..."
cp "$SOURCE_DIR/scripts/worktree-agent.sh" "$TARGET_DIR/scripts/worktree-agent.sh"
cp "$SOURCE_DIR/scripts/guard-critical-zones.sh" "$TARGET_DIR/scripts/guard-critical-zones.sh"
cp "$SOURCE_DIR/mcp_config.json.template" "$TARGET_DIR/mcp_config.json.template"

# 6. Делаем скрипты исполняемыми
chmod +x "$TARGET_DIR"/scripts/*.sh 2>/dev/null || true
chmod +x "$TARGET_DIR"/.agents/scripts/*.sh 2>/dev/null || true
chmod +x "$TARGET_DIR"/.agents/skills/*/scripts/*.sh 2>/dev/null || true

# 7. Обновляем .gitignore проекта
GITIGNORE="$TARGET_DIR/.gitignore"
if [[ -f "$GITIGNORE" ]]; then
  if ! grep -q "\.worktrees" "$GITIGNORE"; then
    echo "" >> "$GITIGNORE"
    echo "# Antigravity worktrees and state" >> "$GITIGNORE"
    echo ".worktrees/" >> "$GITIGNORE"
    echo ".agents/.state/" >> "$GITIGNORE"
    echo "✅ Добавлены .worktrees/ и .agents/.state/ в .gitignore"
  fi
else
  cat << 'GIEOF' > "$GITIGNORE"
.worktrees/
.agents/.state/
*.log
.DS_Store
GIEOF
  echo "✅ Создан базовый .gitignore с игнорированием .worktrees/"
fi

echo ""
echo "============================================================"
echo "🎉 Установка завершена успешно!"
echo "============================================================"
echo "Что теперь доступно в проекте $TARGET_DIR:"
echo "  1. .agents/hooks.json       - Защита критических зон и БД"
echo "  2. .agents/skills/          - Скиллы FSD, Prisma и др."
echo "  3. .agents/subagents/       - Роли Orchestrator, TDD, Dev, Reviewer"
echo "  4. docs/acceptance-contract - Шаблон постановки задач"
echo "  5. ./scripts/worktree-agent - Запуск изолированных задач:"
echo "     ./scripts/worktree-agent.sh start TASK-01 my-feature"
echo ""
