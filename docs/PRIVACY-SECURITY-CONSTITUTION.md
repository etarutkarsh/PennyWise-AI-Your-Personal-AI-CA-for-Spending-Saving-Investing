# The PennyWise Privacy & Security Constitution

**Version 1.0 — Founding Document**

*This document governs how PennyWise thinks about, designs for, and communicates privacy and security. It sits beside the PennyWise Constitution and Platform Architecture as a founding document — not a compliance checklist, not a legal policy, not a settings page.*

*Privacy is not a feature we add. It is a property we build from.*

---

## The Manifesto

> Your money belongs to you.
> Your financial history belongs to you.
> Your data belongs to you.
>
> PennyWise is merely its guardian.

Every other fintech company says: *"Your security is important to us."*

PennyWise says something different: **your privacy is a product feature.**

Those are not the same statement. "Security is important" is a policy. "Privacy is a product feature" is a design commitment. It means privacy is not layered on afterward — it shapes every screen, every data model, every API contract, and every business decision from the beginning.

When a user opens PennyWise, they are giving us access to the most intimate map of their life: where they spend, what they earn, what they owe, what they fear, and what they hope for. No other category of software receives that level of trust. We do not take it lightly, and we do not monetize it.

---

## The Ten Design Principles

### Principle 1 — Security Without Friction

Security that inconveniences users becomes security that users bypass.

The complexity of securing a financial application must live behind the interface, not in front of the user. Every authentication step that a user sees should exist because it genuinely reduces risk at that moment — not because it makes the system feel secure.

**The standard:**

```
BAD  — Fixed multi-step authentication for all actions regardless of risk
GOOD — Biometric unlock for low-risk access, escalating verification
       for high-risk actions, invisible security for everything else
```

Apple-level security means the user experiences one touch. The cryptography, the secure enclave, the key derivation, the session management — all of it happens invisibly. PennyWise adopts this as the design target. If a security mechanism requires visible user effort, that effort must be proportional to the risk of the action it protects.

---

### Principle 2 — Adaptive Authentication

Authentication strength scales with action risk. Not all logins are the same. Not all actions deserve the same friction.

```
RISK TIER         ACTION                              AUTHENTICATION
─────────────────────────────────────────────────────────────────────
AMBIENT           Open app, view dashboard            Biometric (Face ID /
                  View transactions, reports          Fingerprint) or
                  View goals, Safe-to-Spend           session token

LOW               Approve AI recommendation           Biometric
                  Set a savings goal
                  Change display preferences

MEDIUM            Change email address                Password
                  Update phone number                 Biometric + OTP
                  Connect a new bank account          Biometric + OTP
                  Update tax profile                  Biometric + OTP
                  Change PAN / linked ID              Biometric + OTP

HIGH              Remove linked bank account          Biometric + Password
                  Change legal nominee                Biometric + OTP + Gov ID
                  Revoke CA access                    Biometric + OTP
                  Export all data                     Biometric + OTP

CRITICAL          Delete account permanently          Biometric + Password
                                                      + OTP + 72-hour delay
                  Emergency freeze                    Any biometric, immediate
                  Dispute a recommendation            Biometric
```

The 72-hour delay on account deletion is deliberate. It protects against account hijacking (an attacker cannot immediately erase the evidence) and protects against impulsive decisions. The delay is communicated honestly: *"Your account is scheduled for deletion on [date]. You can cancel this before then."*

---

### Principle 3 — Zero-Knowledge Philosophy

PennyWise should know as little as possible while delivering as much value as possible. This is not a contradiction — it is the design challenge.

**What PennyWise never stores:**
- Banking passwords or credentials of any kind
- UPI PINs or transaction PINs
- Aadhaar OTPs or authentication tokens
- Card CVVs or full card numbers
- Session tokens from government portals

**How access is achieved instead:**
- Account Aggregator (RBI framework) for bank data — we never touch credentials
- OAuth 2.0 for third-party platform integrations
- Tokenization for any payment instrument reference
- Delegated read-only access with time-bounded consent

The zero-knowledge principle extends to documents. Documents stored in PennyWise are encrypted with a key that PennyWise infrastructure cannot derive. A PennyWise engineer with full database access cannot read your Form 16. A government subpoena served to PennyWise cannot produce your tax documents in plaintext. Only your biometric or PIN, through your device's secure enclave, can decrypt them.

The tradeoff is explicit and communicated to users: cloud AI processing of documents requires a temporary, user-authorized decryption step. This is shown to users before it happens. The decryption is scoped, time-limited, and logged.

---

### Principle 4 — Local First

Wherever computation can happen on the user's device without loss of quality, it happens there.

This means:
- Transaction categorization runs on-device for the first pass (local ML model)
- Receipt OCR runs on-device (Google ML Kit / Apple Vision)
- The Economic Identity Graph computations that don't require server context run locally
- Push notifications are constructed on-device from structured payloads, not as pre-assembled text from the server

Local-first reduces the surface area of what is ever transmitted. Data that never leaves the device cannot be intercepted in transit, cannot be breached at the server, and cannot be subpoenaed from a third party.

Where server processing is required (LLM inference, simulation, cross-account aggregation), data is transmitted over TLS 1.3, processed with the minimum necessary context, and not retained in server-side logs beyond the audit trail.

---

### Principle 5 — Zero Ads, Forever

This principle is in the main Constitution. It is repeated here because it is also a privacy principle.

Advertising-supported financial products create a fundamental conflict of interest: the product earns more when it understands users better, which incentivizes deeper surveillance. Every recommendation becomes suspect — is this advice, or is it targeting?

PennyWise resolves this conflict by eliminating advertising permanently and structurally.

```
PennyWise will never:

  ✗ Sell user financial data to any third party
  ✗ Use financial behavior for advertising targeting
  ✗ Allow third-party tracking SDKs in the application
  ✗ Sell or license transaction histories
  ✗ Sell or license spending patterns
  ✗ Sell or license purchase behavior
  ✗ Use financial data to train models sold to third parties
  ✗ Allow sponsored content or paid placements in recommendations
```

The business model must remain structurally incompatible with advertising. Subscriptions, enterprise contracts, CA platform fees, and API licensing are the revenue model specifically because they create no incentive to surveil users.

---

### Principle 6 — Transparent Access

Every access to user data that produces a meaningful outcome is visible to the user.

Not every database read. Not every cache lookup. But every action taken with user data that affects what they see or what gets computed — that is logged and viewable.

The model is Git history applied to financial data access. The user has a feed that looks like:

```
TRUST LEDGER — July 22, 2026

  10:32 AM  HDFC Bank synced via Account Aggregator
            12 new transactions imported
            No data left your device to third parties  ✓

  11:02 AM  Tax Engine calculated advance tax estimate
            Inputs: ITR data, current income, Q2 timeline
            No third-party access                      ✓

  11:05 AM  Receipt OCR processed (Swiggy receipt)
            Image processed on-device, text extracted
            Image deleted from processing queue         ✓

  11:45 AM  AI generated 3 spending insights
            Based on last 30 days of transaction data
            Model: GPT-4o-mini via PennyWise backend   ✓

  No third-party data access today.
```

This is not buried in a settings page. It is accessible from the main interface, one tap away. It is the Trust Ledger — a concept that does not exist in any competitor product, and one that makes "your privacy is a product feature" concrete rather than a slogan.

---

### Principle 7 — Permission Dashboard

Users have complete, always-current visibility into who can access what — and complete control to change it.

```
PERMISSION DASHBOARD

  CONNECTED INSTITUTIONS
  ────────────────────────────────────────────────────
  HDFC Bank             Read-only transactions     ✓ Active
  ICICI Bank            Read-only transactions     ✓ Active
  Zerodha               Portfolio balance only     ✓ Active
  Groww                 ✗ Disconnected

  PEOPLE WITH ACCESS
  ────────────────────────────────────────────────────
  Priya (Spouse)        Shared budget view only    ✓ Active    [Modify]
  CA Ramesh & Co.       Tax documents only         ✓ Active    [Modify]
  Employer (Infosys)    ✗ Not connected

  THIRD-PARTY SERVICES
  ────────────────────────────────────────────────────
  No third-party apps connected.

  GOVERNMENT ACCESS
  ────────────────────────────────────────────────────
  Income Tax Dept.      ITR filing only, on-demand ✓ Scoped
  DigiLocker            Document verification      ✓ Scoped

  DATA EXPORT & DELETION
  ────────────────────────────────────────────────────
  [Export all my data]          [Delete my account]
```

Every row is editable. Every permission is revocable immediately. Revocation takes effect in real-time — not "within 30 days" or "next billing cycle." The moment consent is revoked, data access stops and cached data from that source is queued for deletion.

The Permission Dashboard is a public-facing feature, not a buried settings menu. It exists as a top-level navigation item called **Trust Center**.

---

### Principle 8 — Emergency Lock

When a phone is lost or stolen, the user can freeze PennyWise completely from any browser, in one action, in under 10 seconds.

**Freeze actions (immediate, simultaneous):**
1. Revoke all active session tokens across all devices
2. Disable all Account Aggregator consents
3. Lock the Document Vault (re-encryption with temporary key)
4. Disconnect all API sync jobs
5. Send confirmation to user's registered email
6. Log the freeze event with timestamp and initiating IP

**The freeze does not:**
- Delete any data (that is a separate action, requiring 72-hour delay)
- Affect ongoing bank transactions (PennyWise is read-only)
- Lock the user's actual bank accounts (only PennyWise access)

**Unfreeze** requires biometric + OTP from the registered number. The user can also initiate a full account review before unfreezing — seeing the Trust Ledger entries since the freeze was activated.

---

### Principle 9 — Privacy Score

Rather than showing users a generic "security: good" label, PennyWise shows a live Privacy Score that reflects the actual state of their account configuration.

```
PRIVACY SCORE   94 / 100

  ✓  Bank credentials never stored (AA only)          +20
  ✓  Documents encrypted on-device                    +15
  ✓  Face ID enabled                                  +10
  ✓  No third-party app integrations                  +10
  ✓  Zero data sold or shared                         +20
  ✓  Audit logging active                             +10
  ⚠  Phone OS backup not end-to-end encrypted          -5
  ⚠  No recovery email set                             -1

  Improve your score:
  → Enable encrypted phone backup in iOS Settings      +3
  → Add a recovery email address                       +1
  → Review connected bank accounts                      —
```

The score is educational, not punitive. The user is never shamed for a lower score — they are shown specific, actionable steps. The maximum score is reachable by any user who follows the suggestions.

The score is also a trust signal: users can share their Privacy Score with a CA or financial advisor as proof of data hygiene. It becomes the financial equivalent of a clean credit report.

---

### Principle 10 — Trust Ledger

This is the architectural implementation of Principle 6. It is also a philosophical statement about the relationship between PennyWise and its users.

Every significant data event in PennyWise is recorded in a user-accessible, append-only log. Not internal server logs — a user-facing log, written in plain language, that answers the question: *"What happened to my financial data today?"*

**What is logged:**
- Account Aggregator syncs (which institution, how many records)
- AI analysis events (what was analyzed, what model, no data left device / data sent to backend)
- Document OCR events (document type, processed on-device / processed on-server, retention policy)
- Recommendation generation (which engine, confidence level)
- CA access events (which CA, what data type, duration)
- Third-party API calls (if any)
- Authentication events (login, failed login, biometric used)
- Permission changes (who was granted / revoked access, when)
- Export requests
- Freeze / unfreeze events

**What is never in the Trust Ledger:**
- The actual financial data itself (amounts, account numbers, transaction details)
- Personally identifiable information beyond what's necessary to describe the event
- Information that would help an attacker understand the system

The Trust Ledger is retained for 36 months. Users can export it at any time. It cannot be deleted by the user (it is the record of what happened to their data) — but it contains no financial data itself.

---

## The Trust Center

The Trust Center is the public-facing manifestation of these ten principles. It is a top-level navigation destination — not buried in Settings — and it is PennyWise's most important marketing surface.

```
┌─────────────────────────────────────────────────────────────────────┐
│  TRUST CENTER                                                       │
│                                                                     │
│  Privacy Score          94/100          [How to improve]           │
│                                                                     │
│  ─────────────────────────────────────────────────────────────────  │
│                                                                     │
│  PERMISSIONS                                                        │
│  Connected Banks (3)    Connected People (2)    Third Parties (0)   │
│  [Manage all permissions →]                                         │
│                                                                     │
│  ─────────────────────────────────────────────────────────────────  │
│                                                                     │
│  TRUST LEDGER                                                       │
│  Today: 4 events. No third-party access.        [View full log →]   │
│                                                                     │
│  ─────────────────────────────────────────────────────────────────  │
│                                                                     │
│  SECURITY                                                           │
│  Face ID              ✓ Enabled                                     │
│  Active Sessions      1 device                  [Manage]            │
│  Emergency Lock                                 [Freeze Account]    │
│                                                                     │
│  ─────────────────────────────────────────────────────────────────  │
│                                                                     │
│  YOUR DATA                                                          │
│  Data Export          Download everything       [Export]            │
│  Delete Account       Permanent, 72hr delay     [Delete]            │
│                                                                     │
│  ─────────────────────────────────────────────────────────────────  │
│                                                                     │
│  OUR COMMITMENTS                                                    │
│  No ads. No data sales. No commissions.                             │
│  Your documents encrypted. Auditable always.    [Read full pledge]  │
└─────────────────────────────────────────────────────────────────────┘
```

The Trust Center is not a compliance page. It is a product experience. It should be as well-designed as the dashboard. When a user shows a friend PennyWise, the Trust Center is what they show them.

---

## Privacy by Design — The Non-Negotiables

### PennyWise Never

- Stores banking passwords, UPI PINs, or government portal credentials
- Reads SMS messages beyond transaction notifications (and only with explicit, revocable permission)
- Accesses the camera, microphone, or location without explicit, moment-of-use consent
- Sells, licenses, or shares financial data with any third party for any commercial purpose
- Uses financial behavior, transaction history, or spending patterns for advertising of any kind
- Trains third-party commercial AI models on personal financial data without explicit, informed, separately-granted consent
- Includes third-party advertising or analytics SDKs in the application
- Retains data beyond the defined retention periods without explicit user consent
- Presents partial data as complete (data gaps are shown, not hidden)
- Transmits sensitive data in plaintext at any layer

### PennyWise Always

- Encrypts all financial data at rest (AES-256 minimum) and in transit (TLS 1.3)
- Uses hardware-backed secure storage (iOS Secure Enclave / Android StrongBox) for authentication credentials and key material
- Derives document encryption keys from user biometric/PIN, not from server-stored keys
- Explains why a piece of data is needed before requesting permission to access it
- Provides export of all user data in a portable, standard format within 72 hours of request
- Provides permanent deletion of all user data within 72 hours of confirmed request
- Shows the Trust Ledger — a full audit log of meaningful data events — to users on demand
- Requires explicit, separate consent before connecting any new financial institution, person, or service
- Implements the minimum necessary data access for any given function (least privilege)
- Applies the Adaptive Authentication framework — authentication strength matches action risk

---

## Engineering Standards

Privacy and security are engineering disciplines, not product features. These standards apply to every team member writing code that touches user financial data.

### Secure Development Lifecycle

**Before writing code:**
- Threat model for any feature that handles Class 1 or Class 2 data (per Platform Architecture classification)
- Architecture review for any new external dependency
- Privacy impact assessment for any new data collection or processing

**During development:**
- Dependency scanning on every build (known CVE detection)
- Static analysis with security rules enabled (no suppression without documented justification)
- Secrets management: no credentials, API keys, or tokens in source code ever — without exception
- Code review checklist includes security review for all data-handling paths

**Before release:**
- Penetration testing before every major release (independent third party, not internal)
- OWASP Mobile Top 10 check for every release
- Certificate pinning validation
- Data flow audit: confirm no new data is collected beyond what's documented

**Ongoing:**
- Dependency updates reviewed weekly
- Security incident log reviewed monthly by founding team
- Annual third-party security audit

### Encryption Standards

```
DATA AT REST          AES-256-GCM
DATA IN TRANSIT       TLS 1.3 (no fallback to 1.2 in new code)
KEY DERIVATION        PBKDF2 or Argon2id for password-derived keys
                      Hardware-backed for biometric-derived keys
HASHING (passwords)   bcrypt (cost factor ≥ 12) or Argon2id
RANDOM GENERATION     CSPRNG only — never Math.random() or equivalent
DOCUMENT ENCRYPTION   AES-256-GCM with user-derived key
                      Key never stored on server
```

### Data Retention Schedule

```
DATA TYPE                           RETENTION PERIOD
─────────────────────────────────────────────────────────────
Transaction records                 User-controlled (min 7 years
                                    recommended for tax purposes)
Tax documents (Form 16, ITR)        7 years from filing date
Receipts and medical bills          User-controlled
Economic Identity Graph             Active account + 30 days
                                    post-deletion
Trust Ledger / Audit Trail          36 months rolling
Authentication logs                 12 months rolling
Session tokens                      24 hours or session end
Temporary processing data           Deleted immediately after use
Backup of deleted account data      30 days (recovery window)
                                    then permanent deletion
```

### Role-Based Access Control (Internal)

```
ROLE                DATA ACCESS
─────────────────────────────────────────────────────────────
Engineering (Dev)   Anonymized test data only. Zero prod access.
Engineering (Ops)   Aggregated metrics. No individual user data.
Support             Session logs, error codes. No financial data.
Security            Audit trail, access logs. No financial data.
Executive           Aggregated business metrics only.
```

No single engineer has unilateral access to user financial data in production. Any access to production data requires dual authorization, is logged in the Trust Ledger, and triggers a notification to the user if it involves their specific account.

### Incident Response Protocol

**When a security event is detected:**

```
T+0       Detection and initial triage
T+1hr     Contain: isolate affected systems, revoke compromised tokens
T+2hr     Assess: determine scope, data types affected, user count
T+4hr     Notify: affected users notified directly (not via press release first)
T+24hr    Full incident report published internally
T+72hr    CERT-In notification (as required under Indian regulations)
T+7day    Root cause analysis complete, remediation plan published
T+30day   External audit of remediation
```

**User notification standard:**

When user data is involved in a security event, the notification:
- Is sent directly to affected users before public disclosure
- States plainly what happened (no euphemism)
- States what data was involved and what was not
- States what PennyWise is doing about it
- States what the user should do (if anything)
- Is written in plain language, not legal language

There are no carve-outs. There is no threshold below which we do not notify. If user financial data was accessed without authorization, the affected users are told.

---

## Regulatory Mapping

Privacy law compliance is a floor, not a ceiling. PennyWise's own standards exceed what regulations require.

```
REGULATION                          HOW PENNYWISE RESPONDS
─────────────────────────────────────────────────────────────────────
India DPDP Act 2023                 Explicit, purpose-limited consent
(Digital Personal Data Protection)  for every data category.
                                    Data Principal rights honored
                                    (access, correction, deletion).
                                    Data Fiduciary obligations met.

RBI Cybersecurity Framework         Encryption, access controls,
                                    audit trails, incident response
                                    per RBI circular standards.

RBI Account Aggregator              Consent architecture follows
Framework                           AA protocol exactly. No data
                                    accessed beyond AA consent scope.

CERT-In Incident Reporting          Security events reported within
                                    6 hours as required. Full audit
                                    trail available for investigation.

SEBI IA Regulations                 Recommendations in the "advise"
(where applicable)                  zone disclosed as AI-generated,
                                    not as registered investment advice.
                                    Human-in-the-loop maintained
                                    for regulated advice categories.
```

---

## The Trust Promise

When a user opens PennyWise for the first time, before they connect a single bank account, they should read this:

> Your financial life is one of the most personal things you own. PennyWise exists to protect it — not profit from it.
>
> Every recommendation, every connection, and every calculation is designed around one principle: your interests come first.
>
> We will never sell your financial data. We will never hide how our AI reaches conclusions. We will never ask you to trade your privacy for convenience.
>
> Security should feel effortless. Transparency should be constant. Control should always remain with you.
>
> This is not a policy we can change without notice. It is the reason we exist.

---

*This Constitution was established at the founding of PennyWise AI.*

*It sits beside the PennyWise Constitution and the Platform Architecture as a foundational document. Where these three documents conflict on any question of user data, user privacy, or user trust, the interpretation most protective of the user governs.*

*No revision may weaken a user protection, reduce transparency, or expand PennyWise's access to user data beyond what users have explicitly authorized. Any such revision is a violation of this Constitution, not an amendment to it.*
