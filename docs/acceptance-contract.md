# Acceptance Contract Specification & Template

Этот документ определяет единый формат контракта задачи (`acceptance-contract.md`).
Контракт является источником правды для всей цепочки: **PRD Analyst → Interface/Contract → Test Author → Dev Author → Reviewer**.

---

## 1. Назначение и правила

1. **Неизменяемость критериев:** После того как контракт утвержден, агент-разработчик не имеет права сокращать критерии приемки (`acceptance`) или объявлять их необязательными.
2. **Машиночитаемость:** Каждый пункт в `acceptance` должен быть формулирован по стандарту **Given-When-Then** и быть проверяемым автоматическим тестом (Unit / Integration / E2E).
3. **Строгий Scope:** Изменения кода должны ограничиваться только директориями и пакетами из раздела `scope`. Все остальное запрещено к модификации.
4. **Фиксация сигнатур и DTO:** Чтобы разорвать тупик TDD в TypeScript (`TS2307`, несовпадение параметров функций), контракт **обязан** содержать предварительные сигнатуры интерфейсов и DTO до написания тестов.

---

## 2. Шаблон контракта задачи

```markdown
---
ticket: "ENG-123"
title: "Добавление подписки и биллинга пользователя"
author: "prd-analyst"
status: "draft" | "approved" | "in_progress" | "review" | "done"
touches_critical_zones: true # Если true — требует обязательного подтверждения человека
critical_zones_paths:
  - "packages/db/prisma/schema.prisma"
  - "apps/api-gateway/src/billing/**"
---

## 1. Why (Контекст и ценность)
Краткое описание бизнес-цели: зачем мы это делаем, какую проблему пользователя решаем.

## 2. Non-Goals (Чего мы НЕ делаем)
Четкий список исключений, защищающий от разрастания скоупа (scope creep):
- Мы НЕ подключаем провайдера PayPal в этой задаче (только Stripe).
- Мы НЕ редизайним страницу настроек пользователя.

## 3. Scope (Разрешенные пути и пакеты)
- `packages/contracts/src/billing/**`
- `packages/db/prisma/**`
- `apps/api-gateway/src/modules/billing/**`

## 4. Public Interfaces & DTO (Контракт типов)
> [!IMPORTANT]
> Эти сигнатуры фиксируются ДО написания тестов, чтобы компилятор TypeScript не падал на Red-фазе.

```typescript
// packages/contracts/src/billing/dto.ts
import { z } from 'zod';

export const CreateSubscriptionSchema = z.object({
  userId: z.string().uuid(),
  planId: z.enum(['starter', 'pro', 'enterprise']),
  paymentMethodId: z.string().min(1),
});

export type CreateSubscriptionDTO = z.infer<typeof CreateSubscriptionSchema>;

export interface BillingService {
  createSubscription(dto: CreateSubscriptionDTO): Promise<{ subscriptionId: string; status: string }>;
}
```

## 5. Acceptance Criteria (Given-When-Then)

### AC-1: Успешное создание подписки (Happy path)
- **Given:** Валидный пользователь `userId` с привязанным платежным методом `pm_123` и планом `pro`.
- **When:** Вызывается `createSubscription` с валидным DTO.
- **Then:**
  - Создается запись подписки в статусе `ACTIVE`.
  - Публикуется Kafka-событие `billing.subscription.created.v1`.
  - Возвращается `status: 201` с объектом подписки.

### AC-2: Ошибка при невалидном плане
- **Given:** Запрос на создание подписки с планом `ultra_vip` (которого нет в схеме).
- **When:** Запрос поступает на HTTP-шлюз.
- **Then:**
  - Zod-валидатор отклоняет запрос до бизнес-логики.
  - Возвращается `status: 400 Bad Request` с кодом ошибки `VALIDATION_FAILED`.
  - В БД и Kafka ничего не создается.

### AC-3: Идемпотентность создания подписки
- **Given:** Запрос с одинаковым заголовком `Idempotency-Key` или повторное событие `eventId`.
- **When:** Запрос отправлен повторно в течение 60 секунд.
- **Then:**
  - Повторная транзакция в платежном шлюзе не создается.
  - Возвращается результат первоначальной операции из кэша Redis.

## 6. Architecture & Invariants Check
- [ ] FSD: Компоненты UI не импортируют напрямую слой entities/features в обход `index.ts`.
- [ ] Prisma: Любые миграции двухфазные, внешние ключи проиндексированы.
- [ ] Ошибки: Использованы типизированные доменные классы (`SubscriptionAlreadyExistsError`).
- [ ] Redis: Установлен TTL (по умолчанию 86400s) для ключей идемпотентности.
```
