# PennyWise Value Objects

**Core rule: Money is never a bare double. Every monetary value carries its currency.**

All value objects in PennyWise are immutable (`@immutable`), implement `==` and `hashCode`, and provide `copyWith` and `toString`. They live in `mobile/lib/domain/value_objects/`.

---

## Money

**File:** `domain/value_objects/money.dart`

```dart
Money({required num amount, required Currency currency})
```

The fundamental monetary value. No loose `double` for amounts — every money field in the system is `Money`.

| Member | Description |
|--------|-------------|
| `amount` | `num` — avoids floating-point precision issues for display |
| `currency` | `Currency` enum (inr, usd) |
| `+`, `-`, `*` | Type-safe arithmetic. Cross-currency ops throw AssertionError. |
| `format()` | Returns `₹3,000` or `₹1,23,456` (Indian number format) |
| `isZero` | True if amount == 0 |
| `Money.zero` | `const Money(amount: 0, currency: Currency.inr)` |
| `Money.zeroOf(currency)` | Zero for any currency |

**Why:** Prevents silent `double` comparisons like `salary == 50000.0` and makes currency mismatches a compile-time + runtime error, not a silent bug.

---

## Currency

**File:** `domain/value_objects/currency.dart`

```dart
enum Currency { inr, usd }
```

| Member | inr | usd |
|--------|-----|-----|
| `.symbol` | `₹` | `$` |
| `.code` | `INR` | `USD` |

---

## Percentage

**File:** `domain/value_objects/percentage.dart`

```dart
Percentage(double value)  // 0.0–1.0
Percentage.fromPercent(double percent)  // 82.0 → Percentage(0.82)
```

Internally stores as 0.0–1.0 fraction. Use `.toPercent` to get 82.0 back. Use `.format()` for `"82%"`.

**Why:** Prevents the classic bug where 82% is stored as `82` in one place and `0.82` in another.

---

## TimeHorizon

**File:** `domain/value_objects/time_horizon.dart`

```dart
TimeHorizon.months(int months)
TimeHorizon.years(int years)
```

| Getter | Description |
|--------|-------------|
| `.months` | int — always in months internally |
| `.inYears` | double |
| `.label` | `"2 years"`, `"18 months"`, `"1 year 6 months"` |
| `.isShortTerm` | `months < 12` |
| `.isMediumTerm` | `months >= 12 && months <= 60` |
| `.isLongTerm` | `months > 60` |

Used by `SIPCalculation` and `Recommendation` to determine which return rate to apply.

---

## RiskLevel

**File:** `domain/value_objects/risk_level.dart`

```dart
enum RiskLevel { low, medium, high, veryHigh }
```

Used by `PartnerProgram` and `FinancialInstrument` for risk classification.

| Value | `.label` |
|-------|---------|
| `low` | `"Low"` |
| `medium` | `"Medium"` |
| `high` | `"High"` |
| `veryHigh` | `"Very High"` |

---

## Strongly-Typed IDs

**File:** `domain/value_objects/ids.dart`

Each ID type is a thin wrapper around `String` with typed `==` and `hashCode`. This prevents passing a `GoalId` where a `UserId` is expected.

| Type | Used for |
|------|---------|
| `DecisionId` | Decision aggregate identity |
| `RecommendationId` | Recommendation identity |
| `UserId` | User across all bounded contexts |
| `GoalId` | Financial goal |
| `EventId` | Domain events |
| `SessionId` | User session |
| `CorrelationId` | Distributed tracing correlation |
| `TraceId` | Distributed trace |
| `TwinId` | Digital Twin aggregate |
| `ProgramId` | Partner program |

**Pattern:** All IDs are `@immutable` final classes with a `const` constructor:

```dart
@immutable
class UserId {
  final String value;
  const UserId(this.value);
  // == and hashCode on value
}
```

**Why:** `String userId` parameters lead to transposition bugs (passing `sessionId` where `userId` is expected). Typed IDs make this a compile error.

---

## Design Rules

1. **Money is never a bare double.** Use `Money(amount: 50000, currency: Currency.inr)`.
2. **Percentages are never bare doubles.** Use `Percentage.fromPercent(82)`.
3. **IDs are never bare Strings.** Use `UserId('abc-123')`.
4. **Time is never bare months.** Use `TimeHorizon.years(5)`.
5. **All value objects are const-constructible where possible.**
6. **copyWith never changes type** — Percentage.copyWith returns Percentage, not double.
