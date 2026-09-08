#!/usr/bin/env bash
# Хук защиты критических зон репозитория (согласно GEMINI.md Section 5)
set -uo pipefail

python3 -c '
import sys
import json
import re

try:
    data = json.load(sys.stdin)
except Exception:
    print(json.dumps({"decision": "allow"}))
    sys.exit(0)

tool_call = data.get("toolCall", {})
args = tool_call.get("args", {})

target_file = args.get("TargetFile") or args.get("path") or args.get("file_path") or ""

if not target_file:
    print(json.dumps({"decision": "allow"}))
    sys.exit(0)

CRITICAL_PATTERNS = [
    r"packages/db/prisma/migrations/.*",
    r"packages/db/prisma/schema\.prisma",
    r"packages/contracts/.*",
    r".*/auth/.*",
    r".*/billing/.*",
    r".*/payment.*",
    r".*\.env.*",
    r"infra/.*",
    r"\.github/workflows/.*",
    r".*Dockerfile.*",
    r".*docker-compose.*",
]

is_critical = any(re.search(pat, target_file) for pat in CRITICAL_PATTERNS)

if is_critical:
    response = {
        "decision": "force_ask",
        "reason": f"ESCALATE: Файл \"{target_file}\" находится в критической зоне архитектуры (GEMINI.md раздел 5). Требуется явное подтверждение человека!"
    }
else:
    response = {
        "decision": "allow"
    }

print(json.dumps(response, ensure_ascii=False))
'
