---
name: prisma-migrations
description: Проверяет безопасность схемы Prisma и миграций базы данных. Вызывай при изменении schema.prisma или файлов в packages/db/prisma/migrations.
---

# Prisma Migrations & Schema Safety Guard

Этот скилл обеспечивает соблюдение правил работы с базой данных согласно Конституции репозитория ([GEMINI.md](../../../GEMINI.md)).

## Инварианты базы данных

1. **Иммутабельность миграций:** Применённые миграции не редактируются, только создаются новые поверх.
2. **Запрет разрушающих команд:** `prisma migrate reset`, `prisma db push` и прямой `DROP TABLE / DROP COLUMN` запрещены.
3. **Двухфазность изменений:** Разрушающие изменения проводятся в 2 этапа (расширение схемы + двойная запись, затем удаление старого отдельным релизом).
4. **Обязательные индексы:** Каждое внешнее поле (`relation`) и поля фильтрации/сортировки обязаны иметь `@@index` или `@unique`.

## Проверка

Запусти проверочный скрипт, передав ему diff изменений:
```bash
git diff origin/main...HEAD packages/db/ | .agents/skills/prisma-migrations/scripts/check.sh
```
или передав путь к файлу с diff:
```bash
.agents/skills/prisma-migrations/scripts/check.sh path/to/migration.sql
```
