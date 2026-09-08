---
name: fsd-boundaries
description: Проверяет соблюдение архитектурных границ Feature-Sliced Design (FSD). Вызывай при создании или редактировании UI-компонентов, виджетов, фич и сущностей в apps/web или apps/admin.
---

# Feature-Sliced Design (FSD) Boundaries Validator

Этот скилл предназначен для проверки архитектурных инвариантов FSD на фронтенде согласно Конституции репозитория ([GEMINI.md](../../../GEMINI.md)).

## Инварианты FSD

1. **Иерархия слоев (импорт только сверху вниз):**
   `app → processes → pages → widgets → features → entities → shared`
   Слой никогда не импортирует вышестоящие слои (например, `entities` не могут импортировать `features` или `widgets`).
2. **Публичный API (Public API):**
   Кросс-слайсовые импорты допустимы **только** через `index.ts` слайса.
   - ❌ Запрещено: `import { Button } from '@/features/auth/ui/Button'`
   - ✅ Разрешено: `import { Button } from '@/features/auth'`
3. **Изоляция слайсов:**
   Слайс не импортирует соседний слайс своего же слоя напрямую.

## Проверка

Запусти проверочный скрипт:
```bash
.agents/skills/fsd-boundaries/scripts/check.sh [путь_к_директории]
```
По умолчанию проверяется `apps/web/src`. Для админки передай `apps/admin/src`.
При наличии нарушений скрипт завершится с кодом 1 и выведет проблемные файлы.
