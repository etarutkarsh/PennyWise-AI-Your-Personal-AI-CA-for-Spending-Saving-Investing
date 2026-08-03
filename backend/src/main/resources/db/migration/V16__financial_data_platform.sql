-- V16: Financial Data Platform — Canonical Transaction Pipeline
-- Every ingestion source (SMS, AA, OCR, manual) writes to this schema.
-- Downstream: Health Engine, Decision Engine, Behavioral Engine, Digital Twin.

-- ─────────────────────────────────────────────────────────────────────────────
-- Merchant Profiles — Financial Identity Resolution
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE merchant_profiles (
    id                      VARCHAR(64) PRIMARY KEY,   -- snake_case, e.g. 'netflix', 'hdfc_home_loan'
    canonical_name          VARCHAR(256) NOT NULL,
    category                VARCHAR(64) NOT NULL,
    aliases                 TEXT[]       NOT NULL DEFAULT '{}',
    is_subscription         BOOLEAN      NOT NULL DEFAULT FALSE,
    is_investment           BOOLEAN      NOT NULL DEFAULT FALSE,
    is_debt                 BOOLEAN      NOT NULL DEFAULT FALSE,
    is_insurance            BOOLEAN      NOT NULL DEFAULT FALSE,
    country                 CHAR(2)      NOT NULL DEFAULT 'IN',
    website                 VARCHAR(256),
    typical_monthly_amount  NUMERIC(15, 2),
    upi_handles             TEXT[]       NOT NULL DEFAULT '{}',
    confidence              NUMERIC(4, 3) NOT NULL DEFAULT 1.000,
    created_at              TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_merchant_profiles_category ON merchant_profiles(category);
CREATE INDEX idx_merchant_profiles_subscription ON merchant_profiles(is_subscription) WHERE is_subscription = TRUE;

-- Seed a small canonical set — full dataset managed by HardcodedMerchantResolver in Flutter
INSERT INTO merchant_profiles (id, canonical_name, category, aliases, is_subscription) VALUES
  ('netflix',      'Netflix',         'STREAMING',   ARRAY['NETFLIX','Netflix','NETFLIX INDIA','NETFLIX.COM'], TRUE),
  ('spotify',      'Spotify',         'MUSIC',       ARRAY['SPOTIFY','Spotify','SPOTIFY INDIA'], TRUE),
  ('amazon_prime', 'Amazon Prime',    'STREAMING',   ARRAY['AMAZON PRIME','Prime Video','PRIME VIDEO'], TRUE),
  ('swiggy',       'Swiggy',          'FOOD',        ARRAY['SWIGGY','Swiggy','SWIGGY INSTAMART'], FALSE),
  ('zomato',       'Zomato',          'FOOD',        ARRAY['ZOMATO','Zomato'], FALSE),
  ('groww',        'Groww',           'INVESTMENT',  ARRAY['GROWW','Groww','GROWW MF'], FALSE),
  ('zerodha',      'Zerodha',         'INVESTMENT',  ARRAY['ZERODHA','Zerodha','ZERODHA BROKING'], FALSE),
  ('lic',          'LIC',             'INSURANCE',   ARRAY['LIC','LIC OF INDIA','LIC PREMIUM'], FALSE),
  ('airtel',       'Airtel',          'MOBILE',      ARRAY['AIRTEL','Airtel','BHARTI AIRTEL'], TRUE),
  ('jio',          'Reliance Jio',    'MOBILE',      ARRAY['JIO','Jio','RELIANCE JIO','JIO FIBER'], TRUE);

-- ─────────────────────────────────────────────────────────────────────────────
-- Canonical Transactions — deduplicated, reconciled master records
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE canonical_transactions (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount              NUMERIC(15, 2) NOT NULL,
    direction           VARCHAR(8)   NOT NULL CHECK (direction IN ('DEBIT', 'CREDIT')),
    merchant_id         VARCHAR(64)  REFERENCES merchant_profiles(id),
    raw_merchant        VARCHAR(512) NOT NULL,
    payment_rail        VARCHAR(32)  NOT NULL DEFAULT 'UNKNOWN',
    transaction_date    DATE         NOT NULL,
    category_id         UUID         REFERENCES categories(id),
    note                TEXT,

    -- Provenance
    master_source       VARCHAR(32)  NOT NULL,
    sources             TEXT[]       NOT NULL DEFAULT '{}',
    confidence          NUMERIC(4, 3) NOT NULL DEFAULT 0.800
        CHECK (confidence BETWEEN 0 AND 1),
    is_reconciled       BOOLEAN      NOT NULL DEFAULT FALSE,
    reconciliation_note TEXT,
    account_last4       CHAR(4),

    -- Commitment
    is_mandate          BOOLEAN      NOT NULL DEFAULT FALSE,
    is_recurring        BOOLEAN      NOT NULL DEFAULT FALSE,

    -- Tax fields (Phase 3/4)
    tax_category        VARCHAR(32),
    is_business_expense BOOLEAN      NOT NULL DEFAULT FALSE,

    created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_canonical_txn_user ON canonical_transactions(user_id);
CREATE INDEX idx_canonical_txn_date ON canonical_transactions(user_id, transaction_date DESC);
CREATE INDEX idx_canonical_txn_merchant ON canonical_transactions(user_id, merchant_id);
CREATE INDEX idx_canonical_txn_direction ON canonical_transactions(user_id, direction);
CREATE INDEX idx_canonical_txn_mandate ON canonical_transactions(user_id, is_mandate) WHERE is_mandate = TRUE;
CREATE INDEX idx_canonical_txn_confidence ON canonical_transactions(confidence DESC);

-- ─────────────────────────────────────────────────────────────────────────────
-- Raw Transaction Sources — audit trail of every ingested event
-- Allows reprocessing if normalization logic improves
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE raw_transaction_sources (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    canonical_transaction_id UUID        NOT NULL REFERENCES canonical_transactions(id) ON DELETE CASCADE,
    user_id                 UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    source_type             VARCHAR(32)  NOT NULL,
    source_ref              VARCHAR(512),        -- SMS message ID, AA txn ID, email message-id
    raw_merchant            VARCHAR(512),
    raw_amount              NUMERIC(15, 2),
    raw_direction           VARCHAR(8),
    raw_date                TIMESTAMPTZ,
    raw_text                TEXT,                -- original SMS/AA record
    confidence              NUMERIC(4, 3) NOT NULL DEFAULT 0.800,
    ingested_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_raw_sources_canonical ON raw_transaction_sources(canonical_transaction_id);
CREATE INDEX idx_raw_sources_user ON raw_transaction_sources(user_id);
CREATE INDEX idx_raw_sources_type ON raw_transaction_sources(source_type);

-- ─────────────────────────────────────────────────────────────────────────────
-- Deduplication Log — for debugging and confidence auditing
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE deduplication_log (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                 UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    ingestion_run_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    raw_event_count         INT          NOT NULL DEFAULT 0,
    candidate_count         INT          NOT NULL DEFAULT 0,
    canonical_count         INT          NOT NULL DEFAULT 0,
    duplicates_removed      INT          NOT NULL DEFAULT 0,
    reconciled_count        INT          NOT NULL DEFAULT 0,
    engine_version          VARCHAR(64)  NOT NULL
);

CREATE INDEX idx_dedup_log_user ON deduplication_log(user_id);
