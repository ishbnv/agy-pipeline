#!/usr/bin/env bash
# Оркестратор параллельного запуска агентов через Git Worktrees
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKTREES_DIR="$REPO_ROOT/.worktrees"

usage() {
  echo "Использование:"
  echo "  $0 start <TICKET_ID> [SLUG]   - Создать изолированный worktree и ветку для задачи"
  echo "  $0 list                       - Показать все активные агентские воркспейсы"
  echo "  $0 clean <TICKET_ID>          - Удалить воркспейс после завершения задачи"
  echo ""
  echo "Пример:"
  echo "  $0 start ENG-101 user-auth"
  exit 1
}

ACTION="${1:-}"

if [[ -z "$ACTION" ]]; then
  usage
fi

case "$ACTION" in
  start)
    TICKET="${2:-}"
    SLUG="${3:-task}"
    if [[ -z "$TICKET" ]]; then
      echo "❌ Укажите ID тикета (например, ENG-101)"
      exit 1
    fi

    BRANCH_NAME="feat/${TICKET}-${SLUG}"
    WORKTREE_PATH="$WORKTREES_DIR/$TICKET"

    mkdir -p "$WORKTREES_DIR"

    if [[ -d "$WORKTREE_PATH" ]]; then
      echo "⚠️  Воркспейс $WORKTREE_PATH уже существует!"
      echo "Для запуска агента выполните:"
      echo "  cd $WORKTREE_PATH && agy"
      exit 0
    fi

    echo "🚀 Создание изолированного воркспейса для задачи $TICKET..."
    
    # Проверяем, существует ли уже такая ветка
    if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
      git worktree add "$WORKTREE_PATH" "$BRANCH_NAME"
    else
      git worktree add -b "$BRANCH_NAME" "$WORKTREE_PATH" HEAD
    fi

    echo "✅ Изолированный воркспейс готов: $WORKTREE_PATH (ветка $BRANCH_NAME)"
    echo ""
    echo "Запуск агента в изолированном контексте:"
    echo "--------------------------------------------------------"
    echo "  cd $WORKTREE_PATH && agy --mode accept-edits --dangerously-skip-permissions"
    echo "--------------------------------------------------------"
    ;;

  list)
    echo "📋 Список активных Git Worktrees:"
    git worktree list
    ;;

  clean)
    TICKET="${2:-}"
    if [[ -z "$TICKET" ]]; then
      echo "❌ Укажите ID тикета для очистки"
      exit 1
    fi

    WORKTREE_PATH="$WORKTREES_DIR/$TICKET"
    if [[ ! -d "$WORKTREE_PATH" ]]; then
      echo "⚠️  Воркспейс $WORKTREE_PATH не найден."
      exit 0
    fi

    echo "🧹 Удаление воркспейса $WORKTREE_PATH..."
    git worktree remove "$WORKTREE_PATH" --force
    echo "✅ Воркспейс $TICKET удален."
    ;;

  *)
    usage
    ;;
esac
