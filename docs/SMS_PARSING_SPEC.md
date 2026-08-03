# SMS Parsing Specification — Indian Banking SMS

> Reference document for building the PennyWise Android SMS Intelligence Engine.
> Every parser version must be validated against the format catalogue below.
> Last updated: 2026-08-04

---

## 1. Architecture Overview

The SMS pipeline is a staged extraction chain. Each stage is independently testable.

```
SMS Broadcast Received
      ↓
BankDetector         — Is this from a known bank sender ID?
      ↓
PreDebitFilter       — Is this a future-tense "will be debited" alert? (discard)
      ↓
RailClassifier       — UPI / NACH / ECS / SI / NEFT / ATM / POS / ECOM / ...
      ↓
DirectionExtractor   — DEBIT or CREDIT
      ↓
AmountExtractor      — amount + paise
      ↓
MerchantExtractor    — payee name, VPA handle, or NACH payee
      ↓
ReferenceExtractor   — UPI RRN, UTR, IMPS ref, mandate ref
      ↓
AccountExtractor     — last 4 digits
      ↓
DateExtractor        — normalised DateTime
      ↓
BalanceExtractor     — available balance (optional)
      ↓
ConfidenceScorer     — aggregate confidence from per-field confidence
      ↓
ExtractionResult     — all fields + ambiguities + parserVersion
      ↓
TransactionCandidate (via TransactionNormalizer)
      ↓
CanonicalTransaction (via DuplicateDetector)
```

---

## 2. Sender ID Reference

### 2.1 TRAI Prefix Format

All Indian bank SMS sender IDs follow the TRAI format:
```
[Operator]-[BareID][-S]
```
- First 2 chars = `XX-` where X[0] = operator code, X[1] = circle code
- From May 6, 2025: service messages append `-S` suffix

**Parser MUST strip prefix:**
```dart
RegExp(r'^[A-Z]{2}-([A-Z0-9]+?)(?:-S)?$')
// "VK-HDFCBK-S" → group(1) = "HDFCBK"
// "AD-SBIINB" → group(1) = "SBIINB"
```

### 2.2 Bank Sender ID Allowlist

| Bank | Bare Sender IDs |
|------|----------------|
| SBI | `SBIINB`, `SBICRD`, `SBIUPI`, `SBIBNK` |
| HDFC | `HDFCBK`, `HDFCBANKLTD`, `HDFCCRD` |
| ICICI | `ICICIB`, `ICICIBK`, `ICICIN` |
| Axis | `AXISBK`, `AXISBN`, `AXISDB` |
| Kotak | `KOTAKB`, `KOTKBK` |
| IDFC FIRST | `IDFCBK`, `IDFCFT` |
| Yes Bank | `YESBKL`, `YESBNK` |
| IndusInd | `INDBNK`, `INDUSB` |
| AU Small Finance | `AUBANK`, `AUSFBL` |
| Federal Bank | `FEDBKL`, `FEDBNK` |
| PNB | `PNBSMS`, `PNBBNK` |
| Canara | `CANBNK`, `CANARA` |
| Bank of Baroda | `BOBIMT`, `BOBTXN` |
| Union Bank | `UBIBNK`, `UNIONB` |
| Paytm Payments Bank | `PAYTMB`, `PYTMIB` |
| RBL Bank | `RBLBNK` |
| Bandhan Bank | `BANDHN` |

**⚠ Important caveats:**
- **HDFC (June 2024)**: SMS suppressed for UPI sent < ₹100 and received < ₹500. These transactions are real but invisible to SMS parsing.
- **Kotak (Nov 2025)**: Started charging for SMS alerts. Some users may have opted out — expect gaps.
- **TRAI May 2025**: Sender IDs now end in `-S` for service category. Old format still valid for historical SMS.

---

## 3. Pre-Debit Alert Filter

**MUST run before any other parsing.** Pre-debit alerts are future-tense notifications — NOT transactions.

```dart
// Discard if body contains "will be debited" within the message
// RBI mandates 24h pre-debit for all recurring mandates > ₹15,000
static final _preDebitPattern = RegExp(
  r'will\s+be\s+debited|pre.debit\s+notification|scheduled\s+for\s+(?:ECS|NACH)',
  caseSensitive: false,
);
```

**Examples to discard:**
- `"Pre-debit notification: Rs.999.00 will be debited from your A/c XX1234 on 30-09-22 for NETFLIX via UPI AutoPay"`
- `"your EMI of Rs.99650.00 is scheduled for ECS clearance on 08-08-26"`
- `"Pre-debit alert: Rs.25000.00 will be debited from your A/c XX1234 on 05-Oct-22 via NACH"`

**Exception (FASTag/NCMC from Sept 23, 2024):** FASTag and NCMC NCMC NACH replenishment no longer sends pre-debit alerts — only post-debit confirmations fire.

---

## 4. Rail Classification

Run in priority order. First match wins.

### 4.1 Rail Detection Patterns (Priority Order)

```dart
// Priority 1: UPI AutoPay (must check before generic UPI)
static final upiAutopay = RegExp(
  r'UPI.?AUTOPAY|UPI\s+AutoPay|AUTOPAY|via\s+AutoPay',
  caseSensitive: false,
);

// Priority 2: NACH Debit
static final nach = RegExp(r'NACH\s*DR', caseSensitive: false);

// Priority 3: ECS Debit
static final ecs = RegExp(r'ECS\s*DR|ECS\s+clearance', caseSensitive: false);

// Priority 4: Standing Instruction
static final si = RegExp(
  r'Standing\s+Instruction|S\.I\.|(?<![A-Z])SI(?![A-Z0-9])',
  caseSensitive: false,
);

// Priority 5: NEFT
static final neft = RegExp(r'NEFT|INB\s+txn', caseSensitive: false);

// Priority 6: RTGS
static final rtgs = RegExp(r'RTGS', caseSensitive: false);

// Priority 7: IMPS
static final imps = RegExp(r'IMPS', caseSensitive: false);

// Priority 8: ATM Withdrawal
static final atm = RegExp(
  r'ATM\s*WDL|withdrawn\s+(?:at|from)\s+ATM|ATM\s+CASH|ATM\s+withdrawal',
  caseSensitive: false,
);

// Priority 9: POS Card Swipe
static final pos = RegExp(
  r'POS\s+txn|spent\s+at|using\s+Debit\s+Card',
  caseSensitive: false,
);

// Priority 10: ECOM Card (Credit Card spend)
static final ecom = RegExp(
  r'spent\s+(?:on|via)\s+(?:HDFC|ICICI|SBI|Axis|Kotak)\s+(?:Bank\s+)?(?:Credit\s+)?Card',
  caseSensitive: false,
);

// Priority 11: Generic UPI (after AutoPay check)
static final upi = RegExp(
  r'UPI\s*Ref|via\s+UPI|UPI-|UPI\s+ID|@[a-z]+(?:bank|upi|ybl|ibl|sbi|hdfcbank)',
  caseSensitive: false,
);

// Priority 12: Wallet
static final wallet = RegExp(
  r'Paytm\s+wallet|PhonePe\s+wallet|wallet\s+balance',
  caseSensitive: false,
);
```

### 4.2 Sub-Category within NACH/ECS

Once NACH/ECS is detected, sub-classify the commitment type:

```dart
// Insurance: HDFC LIFE, LIC, SBI LIFE, ICICI PRU, BAJAJ ALLIANZ, MAX LIFE, TATA AIA
static final insurancePayee = RegExp(
  r'LIFE\s+INS|INSURANCE|LIC\s+OF\s+INDIA|LIC\s+PREMIUM',
  caseSensitive: false,
);

// SIP/MF: CAMS, KFintech, AMC names, FOLIO keyword
static final sipPayee = RegExp(
  r'\bCAMS\b|\bKFIN\b|FOLIO\s*\d|MF\s+SIP|\bSIP\b',
  caseSensitive: false,
);

// EMI: loan company names
static final emiPayee = RegExp(
  r'BAJAJ\s+FIN|HDFC\s+LOAN|TATA\s+CAPITAL|ICICI\s+BANK\s+LOAN|HOME\s+CREDIT|\bEMI\b',
  caseSensitive: false,
);
```

---

## 5. Direction Detection

```dart
static final _debitSignals = RegExp(
  r'\b(?:debited|debit|sent\s+to|withdrawn|spent|paid|payment\s+of|INB\s+txn)\b',
  caseSensitive: false,
);

static final _creditSignals = RegExp(
  r'\b(?:credited|credit|received|deposited|salary\s+credited)\b',
  caseSensitive: false,
);
```

**⚠ Ambiguity rule:** If both signals appear (IMPS confirmation shows both accounts), the sender's account direction is DEBIT. IMPS SMS typically reads: `"Acct XX123 debited ... & Acct XX456 credited"` — parse direction = DEBIT from the perspective of the account holder receiving the SMS.

**⚠ Refund detection:** `"refund of INR X credited"` → direction = CREDIT, category = REFUND (override normal income category).

---

## 6. Amount Extraction

```dart
static final _amountPattern = RegExp(
  r'(?:INR|Rs\.?|₹)\s*([\d,]+(?:\.\d{1,2})?)',
  caseSensitive: false,
);
```

**Handles:** `INR 1,500.00` / `Rs.1,500.00` / `Rs 1,500.00` / `Rs500.00` / `₹1,500`

**After match:** strip commas, parse as double.

**Edge case:** Some SMSes show amount twice (once as debit, once as available balance). Always take the FIRST amount match — it precedes the balance in all observed formats.

---

## 7. Merchant / Payee Extraction

Merchant extraction depends on the detected rail:

### 7.1 UPI Push

```dart
// VPA handle: most reliable merchant signal for UPI
static final _vpaPattern = RegExp(r'[\w.\-]+@[\w]+');

// Fallback: after "to" or "Merchant:"
static final _upiMerchant = RegExp(
  r'(?:to\s+|Merchant:\s*|payee\s*)([A-Z][A-Z0-9\s.&\-]{2,40})',
  caseSensitive: false,
);
```

**Common UPI handle suffixes:** `@okhdfcbank`, `@okicici`, `@oksbi`, `@okaxis`, `@ybl`, `@ibl`, `@upi`, `@paytm`, `@apl`, `@amazonpay`, `@freecharge`, `@pockets`

### 7.2 NACH / ECS

```dart
// Payee appears after "NACH DR -" or "ECS DR -"
static final _nachPayee = RegExp(
  r'(?:NACH|ECS)\s+DR\s*[-–]\s*([A-Z][A-Z0-9\s&\-\/]{2,50})(?:\s*[-–]|\s+Avl|\s+Ref|$)',
  caseSensitive: false,
);
```

### 7.3 POS (Card Swipe)

```dart
// After "spent at" or "POS txn at"
static final _posmerchant = RegExp(
  r'(?:spent\s+at|POS\s+txn\s+at|at\s+POS)\s+([A-Z][A-Z0-9\s\-\.]{2,40})',
  caseSensitive: false,
);
```

### 7.4 ECOM (Credit Card Online)

```dart
// After "at" followed by merchant name, before "Avl Lmt"
static final _ecomMerchant = RegExp(
  r'at\s+([A-Z][A-Z0-9\s\-\.\/]{2,40}?)(?:\s*\.?\s+Avl)',
  caseSensitive: false,
);
```

---

## 8. Reference ID Extraction

```dart
// UPI RRN (12 digits after UPI Ref keyword)
static final _upiRef = RegExp(
  r'(?:UPI\s+Ref\s*(?:No\.?\s*)?|Ref\s+No\s+)(\d{12})',
  caseSensitive: false,
);

// NEFT UTR (16 chars: bank code + YY + julian day + sequence)
static final _neftUtr = RegExp(r'UTR\s+([A-Z]{4}\d{12})', caseSensitive: false);

// RTGS UTR (starts with RBIA)
static final _rtgsUtr = RegExp(r'UTR\s+(RBIA\d{12})', caseSensitive: false);

// IMPS Ref (12 digits)
static final _impsRef = RegExp(
  r'IMPS\s+Ref\s*(?:no\.?\s*)?(\d{12})',
  caseSensitive: false,
);

// NACH / Mandate Ref
static final _nachRef = RegExp(
  r'(?:Mandate\s+Ref|NACH\s+Ref|Ref\s+NACH)\s*:?\s*([A-Z0-9]{8,20})',
  caseSensitive: false,
);
```

**Use in deduplication:** The reference ID is the most reliable deduplication key. Same RRN/UTR from SMS + AA = same transaction with certainty.

---

## 9. Account Number Extraction

```dart
static final _accountPattern = RegExp(
  r'(?:a\/c|acct|account)\s*(?:no\.?\s*)?[Xx*]{0,8}\s*(\d{4})',
  caseSensitive: false,
);
```

Returns last 4 digits of the account number.

---

## 10. Date Extraction

Reuse existing `SmsParserService` patterns — they are correct:

| Format | Example | Pattern |
|--------|---------|---------|
| `DD-MM-YY` | `29-09-22` | `\d{2}-\d{2}-\d{2}` |
| `DD-MM-YYYY` | `29-09-2022` | `\d{2}-\d{2}-\d{4}` |
| `DD-Mon-YY` | `20-Oct-22` | `\d{2}-[A-Za-z]{3}-\d{2,4}` |
| `DD Mon YYYY` | `29 Sep 2022` | `\d{2}\s[A-Za-z]{3}\s\d{4}` |
| `DDMonYY` | `29Sep22` | `\d{2}[A-Za-z]{3}\d{2}` |
| `DD/MM/YYYY` | `13/07/2022` | `\d{2}\/\d{2}\/\d{4}` |

---

## 11. Balance Extraction

```dart
// Savings account: "Avl Bal", "Available Balance", "Bal"
static final _savingsBalance = RegExp(
  r'(?:Avl\s+Bal|Available\s+Balance|Bal)[\s:]*(?:Rs\.?|INR)?\s*([\d,]+(?:\.\d{1,2})?)',
  caseSensitive: false,
);

// Credit card: "Avl Lmt", "Available Limit", "Avl Limit"
static final _creditLimit = RegExp(
  r'(?:Avl\s+Lmt|Available\s+Limit|Avl\s+Limit|Avl\s+Credit)[\s:]*(?:Rs\.?|INR)?\s*([\d,]+(?:\.\d{1,2})?)',
  caseSensitive: false,
);
```

**⚠ Important:** `Avl Lmt` indicates a credit card transaction. `Avl Bal` indicates a debit/savings transaction. This distinction affects merchant category inference.

---

## 12. Confidence Scoring

Each field contributes to the aggregate ExtractionResult confidence:

| Field | Present & High Quality | Present & Ambiguous | Missing |
|-------|----------------------|---------------------|---------|
| Amount | +0.30 | +0.15 | −0.30 (fatal) |
| Direction | +0.25 | +0.10 | −0.25 (fatal) |
| Date | +0.15 | +0.08 | −0.10 |
| Merchant | +0.15 | +0.05 | 0 (allowed missing) |
| Rail | +0.10 | +0.05 | 0 (allowed missing) |
| Reference ID | +0.05 | +0.02 | 0 |

**Thresholds:**
- `≥ 0.85` → High confidence → record immediately
- `0.60–0.84` → Medium confidence → record with note
- `< 0.60` → Low confidence → queue for manual review

---

## 13. Known Ambiguities and Edge Cases

| # | Case | Handling |
|---|------|----------|
| 1 | IMPS SMS shows both debit and credit accounts | Parse direction = DEBIT (sender's perspective) |
| 2 | `"received"` appears in debit SMS (`"received UPI Ref"`) | Debit keyword takes priority; `received` only signals CREDIT if it's the first direction signal |
| 3 | Pre-debit alert (`"will be debited"`) | Discard — do not record as transaction |
| 4 | CC spend vs bank debit | `Avl Lmt` keyword → credit card spend; `Avl Bal` → savings debit |
| 5 | Wallet load from bank | `"transferred to Paytm wallet from A/c XX1234"` → DEBIT from bank (record) |
| 6 | Wallet credit notification | `"Rs.500 added to your Paytm wallet"` → do NOT record (wallet internal) |
| 7 | SIP: bank NACH SMS + AMC confirmation SMS | Bank NACH = actual debit (record). AMC SMS (`CAMSIN`, `KFINSS`) = duplicate signal — skip |
| 8 | CC bill payment vs CC spend | `"BillPay/Credit Card payment"` keyword → payment to CC (DEBIT from savings). Different from `"spent on Card"` |
| 9 | Refund credit | `"refund"` keyword + `"credited"` → CREDIT direction, category = REFUND |
| 10 | HDFC sub-₹100 UPI gap | Some HDFC UPI sends have no SMS at all. Do not infer completeness from HDFC SMS count |
| 11 | `SI` ambiguity | `SI` alone matches IFSC codes. Only classify as Standing Instruction if surrounded by spaces or at start: `(?<![A-Z])SI(?![A-Z0-9])` |
| 12 | Salary vs large NEFT | `"Salary credited"` keyword → salary. Large NEFT credit without keyword → income (uncategorized) |

---

## 14. Data Gaps (Non-Parseable Transactions)

The following cannot be detected from SMS alone:

| Transaction Type | Why Missing | Mitigation |
|-----------------|-------------|------------|
| HDFC UPI < ₹100 sent | HDFC suppressed SMS (June 2024) | Account Aggregator |
| HDFC UPI < ₹500 received | Same as above | Account Aggregator |
| Kotak opt-out users | User disabled paid SMS alerts | Account Aggregator / CSV import |
| iOS users | No READ_SMS permission on iOS | Account Aggregator (primary iOS path) |
| Cash transactions | No electronic record | Manual entry |
| UPI via app without bank SMS | PhonePe/Paytm internal wallets | Email parsing or app API |
| International card transactions | Bank SMS has partial merchant name | Account Aggregator / OCR |
| FASTag toll deductions | May appear as generic NACH DR | FASTag statement API |

---

## 15. AMC / Non-Bank SMS (Do Not Parse as Bank Transactions)

These sender IDs send financial SMS but must NOT be parsed as bank debit/credit events:

| Sender ID | Issuer | Type |
|-----------|--------|------|
| `CAMSIN` | CAMS | MF unit allotment confirmation |
| `KFINSS`, `KFINTX` | KFintech | MF unit allotment confirmation |
| `NIPSIP`, `NIPPON` | Nippon MF | SIP confirmation |
| `AXISMF` | Axis MF | SIP confirmation |
| `SBIMLF` | SBI MF | SIP confirmation |
| `HDFCMF` | HDFC MF | SIP confirmation |
| `ICICIM` | ICICI Pru MF | SIP confirmation |

**Rule:** These confirm that a transaction already recorded from the bank's NACH DR SMS was processed. Recording them separately causes double-counting.

---

## 16. Parser Versioning

Every `ExtractionResult` must carry the parser version that produced it. This enables replay.

```dart
static const String kCurrentVersion = 'sms-parser-v1';
```

Version increment rules:
- **Patch** (v1.0 → v1.1): New regex variant added for existing pattern
- **Minor** (v1 → v2): New field added to ExtractionResult (e.g., adding `vpaHandle`)
- **Major** (v2 → v3): Fundamental model change (e.g., staged extraction replaces monolithic parse)

When `kCurrentVersion` is bumped, all historical `RawFinancialEvent` records with the old parser version should be queued for replay to extract newly available fields.

---

## 17. Test Corpus (Minimum Required)

Before Phase 8.2 ships, the following SMS variants must have passing unit tests:

### Required test cases

| # | Bank | Rail | Direction | Test case description |
|---|------|------|-----------|----------------------|
| 1 | SBI | UPI push | DEBIT | `"A/c X1234-debited by Rs500.00 ... transfer to merchant@upi"` |
| 2 | HDFC | UPI push | DEBIT | `"Rs.500.00 debited from HDFC Bank A/c **1234 ... UPI Ref No 123456789012"` |
| 3 | HDFC | UPI push | CREDIT | `"Rs.5000.00 credited to HDFC Bank A/c **1234 ... Sender: name@oksbi"` |
| 4 | ICICI | UPI push | DEBIT | `"Rs.500.00 debited from your A/c XX1234 on 20-Oct-22 via UPI"` |
| 5 | Any | UPI AutoPay | DEBIT | Body contains `UPI-AUTOPAY` — rail = upiAutopay |
| 6 | Any | NACH | DEBIT | Body contains `NACH DR - HDFC LIFE` — rail = nach, category = insurance |
| 7 | Any | NACH | DEBIT | Body contains `NACH DR - CAMS - FOLIO` — rail = nach, category = investment (SIP) |
| 8 | Any | ECS | DEBIT | Body contains `ECS DR` — rail = ecs |
| 9 | Any | SI | DEBIT | Body contains `Standing Instruction` — rail = standingInstruction |
| 10 | SBI | NEFT | DEBIT | Body contains `INB txn ... NEFT` |
| 11 | HDFC | RTGS | DEBIT | Body contains `via RTGS ... UTR HDFC22283012345` |
| 12 | SBI | IMPS | DEBIT | Body contains `IMPS Ref no` |
| 13 | Any | ATM | DEBIT | Body contains `withdrawn at ATM` |
| 14 | Any | POS | DEBIT | Body contains `spent at ZARA` |
| 15 | ICICI | ECOM | DEBIT | Body contains `spent on ICICI Bank Card XX1234` — `Avl Lmt` present |
| 16 | Any | PRE-DEBIT | DISCARD | Body contains `will be debited` — return null |
| 17 | Any | Salary | CREDIT | Body contains `Salary credited` |
| 18 | Any | CC Bill Pay | DEBIT | Body contains `BillPay/Credit Card payment` |
| 19 | SBI | TRAI 2025 | Any | Sender `AD-SBIINB-S` — strips to `SBIINB`, identified as bank |
| 20 | Any | Refund | CREDIT | Body contains `refund of INR X credited` — category = REFUND |

---

## 18. References

1. Existing parser: `mobile/lib/core/services/sms_parser_service.dart`
2. Moneyprism bank sender IDs: `https://github.com/qtw4c7phzx-alt/Moneyprism`
3. transaction_sms_parser (Dart/Flutter, 30+ banks): `https://github.com/MabudAlam/transaction_sms_parser`
4. Real SMS corpus (SBI/ICICI/Paytm): `https://gist.github.com/avinal/4079e1752e5b987530315b4802e51287`
5. TRAI sender ID prefix codes: `https://www.phonon.io/what-do-the-initial-two-character-prefixes-like-vm-ad-etc-mean-in-bulk-sms/`
6. TRAI TCCCPR 2025 `-S` suffix rule: `https://kb.smsalert.co.in/knowledgebase/trai-mandates-header-suffixes-for-sms-new-rules-effective-from-may-6-2025/`
7. HDFC UPI SMS suppression (June 2024): `https://www.business-standard.com/amp/finance/personal-finance/hdfc-bank-to-stop-sms-alerts-for-upi-payments-up-to-rs-100-check-details-124052901252_1.html`
8. RBI e-mandate ₹15,000 threshold: `https://www.rocketpay.co.in/blog/rbi-e-mandate-recurring-payments-15000`
9. FASTag AutoPay exemption (Sept 2024): `https://www.business-standard.com/finance/personal-finance/new-upi-autopay-rule-no-24-hour-pre-debit-alert-for-fastag-rupay-ncmc-124092600876_1.html`
10. UPI/NEFT/IMPS narration codes: `https://mybankstatementanalysis.com/blog/upi-neft-imps-rtgs-codes-explained`
