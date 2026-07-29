# PennyWise AI — Security Checklist

Five security checks derived from the Emergent Security review framework, applied to PennyWise's specific stack: Spring Boot 3 backend, Flutter mobile client, PostgreSQL 16, Redis 7, JWT auth, and OpenAI integration.

---

## Check 01 — Secret Leak Prevention (Gitleaks)

**Risk:** Hardcoded API keys or JWT secrets committed to git are permanent and exploitable even after deletion.

**PennyWise-specific concerns:**

| Secret | Location | Action |
|--------|----------|--------|
| `OPENAI_API_KEY` | `backend/src/main/resources/application.yml` | Must be env var only — never a literal value |
| `JWT_SECRET` | Same file (`app.security.jwt.secret`) | Min 256-bit random string, never committed |
| `spring.datasource.password` | Same file | Must come from env var `DB_PASSWORD` |
| `spring.data.redis.password` | Same file | Must come from env var `REDIS_PASSWORD` |

**Required:**
- `.env` in `.gitignore` — verify with `git check-ignore -v .env`
- Add `.env.example` with dummy values so developers know what to set
- Never log `Authorization` headers — audit `PrettyDioLogger` in `ApiClient.dart` (currently logs request bodies in debug mode; ensure `kDebugMode` gate is always respected)
- If any secret was ever committed: rotate it immediately, even if the commit was deleted (git history is not private once pushed)
- Run `gitleaks detect --source .` before every release

---

## Check 02 — Personal Data Flow Audit (Bearer)

**Risk:** PII leaks through logs, third-party SDKs, or improperly filtered API responses.

**PennyWise handles sensitive PII:** salary, spending habits, bank transaction amounts, financial goals.

**Required:**

- **Logs must never contain:** email addresses, salary figures, transaction amounts, JWT tokens, or OpenAI prompts/completions
  - Audit `AuthController.java`, `AuthService.java`, and any `@Slf4j` logger in the backend
  - `PrettyDioLogger` in Flutter only fires in debug builds — confirm `kDebugMode` gate in `api_client.dart:50`

- **Password hashing:** Verify `AuthService.java` uses BCrypt (`BCryptPasswordEncoder`), never MD5 or SHA-256 plain

- **No PII in `localStorage` / `SharedPreferences`:**
  - `user_prefs_storage.dart` stores salary, XP, quiz scores — this is acceptable (non-auth, non-financial-critical)
  - JWT access/refresh tokens must stay in `FlutterSecureStorage` (Keychain/Keystore) — confirm `token_storage.dart` uses `flutter_secure_storage`, not `SharedPreferences`

- **API response filtering:** Never return password hashes or internal IDs that expose schema structure in JSON responses — audit all `@RestController` response DTOs

- **Third-party SDKs:** `google_mlkit_text_recognition` (OCR), `another_telephony` (SMS) — when implemented, ensure raw SMS/receipt content is never sent to third-party analytics

- **Data deletion:** Implement a DELETE /users/me endpoint that cascades across all 11 tables when a user requests account deletion

---

## Check 03 — Pre-Deploy Production Audit (ECC)

**Risk:** Debug artifacts, missing security headers, and lax CORS expose the production API to trivial attacks.

**Required:**

**Fail-fast on missing env vars** — in `application.yml` / Spring boot startup, validate:
```java
// If JWT_SECRET is missing or shorter than 32 chars, throw on startup
Assert.hasLength(jwtSecret, "JWT_SECRET env var must be set");
Assert.isTrue(jwtSecret.length() >= 32, "JWT_SECRET too short");
```

**Remove before production:**
- Any `@GetMapping("/test")` or `@PostMapping("/debug")` endpoints in controllers
- Swagger/OpenAPI UI at `/swagger-ui.html` — disable in prod (`springdoc.swagger-ui.enabled=false`)
- `PrettyDioLogger` is already gated behind `kDebugMode` in Flutter — keep it that way

**Generic error responses:** Spring Boot must not return stack traces. In `application.yml`:
```yaml
server:
  error:
    include-stacktrace: never
    include-message: never
```
All `@ExceptionHandler` methods should return `{ "error": "Something went wrong" }`, not exception messages.

**Security headers** — add to Spring Security config:
```
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Strict-Transport-Security: max-age=31536000; includeSubDomains
Content-Security-Policy: default-src 'self'
```

**Rate limiting on auth endpoints:**
- `POST /auth/login` — max 5 attempts per IP per minute
- `POST /auth/register` — max 10 per IP per hour
- `POST /auth/refresh` — max 20 per IP per minute
- Use Spring Boot's `bucket4j` or a Redis-backed rate limiter

**CORS:** Restrict to the Flutter web origin only — never `allowedOrigins("*")` in production:
```java
.allowedOrigins("https://app.pennywise.ai")  // not "*"
```

**Database TLS:** `spring.datasource.url` must include `?ssl=true&sslmode=require` for production PostgreSQL

---

## Check 04 — Deep Security Audit (Trail of Bits)

**Risk:** Business logic and authorization flaws that bypass authentication entirely.

**Required:**

**Auth middleware on every protected route:**
- Every `@RestController` endpoint except `/auth/login`, `/auth/register`, `/auth/refresh` must require a valid JWT
- Verify Spring Security's `SecurityFilterChain` has `.anyRequest().authenticated()` and that no route accidentally matches the permit-all pattern

**IDOR prevention — ownership checks:**
```java
// Every resource fetch must verify the requesting user owns it
@GetMapping("/transactions/{id}")
public Transaction get(@PathVariable Long id, @AuthenticationPrincipal UserDetails user) {
    Transaction tx = repo.findById(id).orElseThrow();
    if (!tx.getUserId().equals(user.getId())) throw new ForbiddenException();
    return tx;
}
```
Apply this to: transactions, budgets, goals, affordability history, chat history.

**JWT security:**
- Signing secret: min 256-bit random value from env var `JWT_SECRET`
- Access token expiry: 15 minutes (currently set in `AuthController.java` — verify)
- Refresh token expiry: 30 days (stored in `refresh_tokens` table or Redis)
- On logout: blacklist the refresh token so it cannot be replayed
  - `token_storage.dart` clears local storage on logout — backend must also invalidate server-side

**Password reset** (when implemented):
- Token must be random (UUID or 32-byte SecureRandom), single-use, 15-minute TTL
- Never derive reset tokens from email + timestamp

**Parameterized queries:**
- Spring Data JPA uses parameterized queries by default — never use `@Query` with string concatenation
- All search/filter inputs (category name, merchant name) must go through JPA, never native SQL with string interpolation

**Server-side calculations:**
- Affordability verdict (`AffordabilityEngine.java`) already runs server-side — keep it that way
- Never trust `amount` or `savedAmount` values from the client without range validation (no negative transaction amounts, no impossibly large goals)

**XSS — Flutter web:**
- `flutter_html` or any widget rendering raw HTML must sanitize input
- The AI chat response (when wired) must never render raw HTML from OpenAI's output

---

## Check 05 — Attacker's Perspective Review (ECC Security Review)

**Risk:** An attacker probing specific business logic paths PennyWise exposes.

**Attack scenarios to test before every release:**

**ID manipulation:**
```
GET /transactions/1  (logged in as user B, transaction belongs to user A)
→ Must return 403, not the transaction
```
Test every `/{id}` endpoint with IDs belonging to other test users.

**Login bypass:**
```
Authorization: Bearer <expired_token>
Authorization: Bearer <malformed.token.here>
Authorization: Bearer null
```
All must return 401, never 200 or 500.

**Privilege escalation:**
- If admin roles are added later: verify role is checked server-side in every `@PreAuthorize`, not just hidden in the Flutter UI
- Never store `isAdmin: true` in the JWT payload without server-side verification against the database

**Rate limits on:**
- `POST /auth/login` — brute-force password guessing
- `POST /auth/register` — spam account creation
- `POST /ai/chat` (when live) — OpenAI cost abuse; add per-user daily token budget
- `POST /transactions` — bulk transaction flooding

**JavaScript/SQL injection in text fields:**
- Merchant name field in transactions: test with `<script>alert(1)</script>` and `'; DROP TABLE transactions;--`
- Spring Data JPA prevents SQL injection by default; Flutter's text fields render as text, not HTML — confirm no `flutter_html` renders merchant names

**Exposed infrastructure — verify these return 404 in production:**
- `/.env`
- `/.git/config`
- `/swagger-ui.html` (disable in prod)
- `/actuator/env` (Spring Boot Actuator — restrict to admin-only or disable)
- `/h2-console` (must be disabled; PennyWise uses PostgreSQL but Spring Boot may auto-configure H2)

**Business logic manipulation:**
- `PATCH /goals/{id}/saved-amount` with `amount: -999999` — backend must reject negative saved amounts
- `POST /transactions` with `amount: 0` or `amount: -1` — validate server-side
- Affordability check with `price: -100` — validate that `AffordabilityEngine.java` handles edge inputs

---

## Quick Audit Checklist

Before every production release, run through:

- [ ] `gitleaks detect --source .` — zero secrets in git history
- [ ] `JWT_SECRET`, `OPENAI_API_KEY`, `DB_PASSWORD` sourced from env vars (not hardcoded in `application.yml`)
- [ ] `server.error.include-stacktrace=never` in production `application.yml`
- [ ] CORS restricted to production domain only
- [ ] Rate limiting active on `/auth/login` and `/auth/register`
- [ ] Swagger UI disabled in production
- [ ] Every `/{id}` endpoint has ownership check
- [ ] Refresh token blacklisted on logout
- [ ] `POST /ai/chat` has per-user rate/token limit
- [ ] `PATCH /goals/{id}/saved-amount` rejects negative or zero amounts
- [ ] `PrettyDioLogger` only fires in debug builds (verify `kDebugMode` gate in `api_client.dart`)
- [ ] `FlutterSecureStorage` used for JWT — not `SharedPreferences`
