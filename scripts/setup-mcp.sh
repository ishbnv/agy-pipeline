#!/usr/bin/env bash
set -uo pipefail

TARGET_MCP_CONFIG="${HOME}/.gemini/config/mcp_config.json"
PROJECT_TEMPLATE="./mcp_config.json.template"

echo "===================================================="
echo " Настройка Model Context Protocol (MCP) для Antigravity"
echo "===================================================="

# Проверяем наличие nvm/node
if ! command -v node >/dev/null 2>&1; then
  echo "❌ Node.js не найден. Установите Node.js для запуска MCP серверов."
  exit 1
fi

echo "✅ Node.js обнаружен: $(node -v)"

# Проверка переменных окружения
echo ""
echo "Проверка необходимых токенов окружения:"
missing_tokens=0

if [[ -z "${GITHUB_TOKEN:-}" && -z "${GITHUB_PERSONAL_ACCESS_TOKEN:-}" ]]; then
  echo "⚠️  GITHUB_TOKEN / GITHUB_PERSONAL_ACCESS_TOKEN не задан (нужен для GitHub MCP)"
  missing_tokens=$((missing_tokens + 1))
else
  echo "✅ GitHub token найден"
fi

if [[ -z "${LINEAR_API_KEY:-}" ]]; then
  echo "⚠️  LINEAR_API_KEY не задан (нужен для Linear MCP)"
  missing_tokens=$((missing_tokens + 1))
else
  echo "✅ LINEAR_API_KEY найден"
fi

if [[ -z "${FIGMA_TOKEN:-}" && -z "${FIGMA_ACCESS_TOKEN:-}" ]]; then
  echo "⚠️  FIGMA_TOKEN / FIGMA_ACCESS_TOKEN не задан (нужен для Figma MCP)"
  missing_tokens=$((missing_tokens + 1))
else
  echo "✅ Figma token найден"
fi

echo ""
echo "Файл шаблона: $PROJECT_TEMPLATE"
echo "Глобальный путь конфигурации Antigravity: $TARGET_MCP_CONFIG"
echo ""

if [[ -f "$PROJECT_TEMPLATE" ]]; then
  echo "Для применения скопируйте шаблон в ваш глобальный конфиг:"
  echo "  mkdir -p ~/.gemini/config && cp $PROJECT_TEMPLATE $TARGET_MCP_CONFIG"
fi

echo ""
echo "Текущие зарегистрированные MCP серверы в agy:"
if command -v agy >/dev/null 2>&1; then
  agy mcp list || true
else
  echo "ℹ️  Команда 'agy' не найдена в текущем PATH. Убедитесь, что Antigravity CLI установлен."
fi
