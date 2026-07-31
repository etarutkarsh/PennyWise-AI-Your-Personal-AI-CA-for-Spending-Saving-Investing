-- =====================================================================
-- V5: Tax-ready schema additions (Phase 3/4 foundation)
--
-- Adds nullable columns to users and transactions so every record
-- captured from this point forward carries the metadata the future
-- Tax Intelligence module (Phase 4) will need — with zero impact on
-- existing rows or API behaviour (all new columns are nullable/defaulted).
--
-- Also creates the documents table for the Financial Vault (Phase 3).
-- =====================================================================

-- ---------------------------------------------------------------------
-- users: PAN, tax regime preference, financial year start
-- ---------------------------------------------------------------------
alter table users
    add column if not exists pan                  varchar(10),
    add column if not exists tax_regime           varchar(8)  default 'NEW',
    add column if not exists financial_year_start int         default 4;

-- ---------------------------------------------------------------------
-- transactions: receipt proof, tax category, verification lifecycle
-- ---------------------------------------------------------------------
alter table transactions
    add column if not exists receipt_url          text,
    add column if not exists tax_category         varchar(64),
    add column if not exists verification_status  varchar(16) default 'UNVERIFIED',
    add column if not exists is_business_expense  boolean     default false;

create index if not exists idx_transactions_tax_category
    on transactions(user_id, tax_category)
    where tax_category is not null;

-- ---------------------------------------------------------------------
-- documents: Financial Vault — every uploaded document lives here
-- ---------------------------------------------------------------------
create table if not exists documents (
    id                      uuid primary key default gen_random_uuid(),
    user_id                 uuid not null references users(id) on delete cascade,

    -- Classification
    document_type           varchar(32) not null,
    -- FORM_16 | FORM_26AS | AIS | RECEIPT | SALARY_SLIP |
    -- INSURANCE | HOME_LOAN | MUTUAL_FUND | PREVIOUS_ITR | OTHER

    original_filename       varchar(255),
    file_url                text,

    -- OCR pipeline state
    ocr_status              varchar(16) not null default 'PENDING',
    -- PENDING | PROCESSING | COMPLETED | FAILED
    ocr_data                jsonb,
    confidence_score        double precision,

    -- Tax context
    financial_year          varchar(7),   -- e.g. "2025-26"
    tax_category            varchar(64),  -- 80C | 80D | HRA | FORM_16 | etc.
    linked_transaction_id   uuid references transactions(id) on delete set null,

    -- Verification lifecycle (mirrors the transaction field)
    verification_status     varchar(16) not null default 'UNVERIFIED',
    -- UNVERIFIED | VERIFIED | DISPUTED

    created_at              timestamptz default now(),
    updated_at              timestamptz default now()
);

create index if not exists idx_documents_user on documents(user_id, created_at desc);
create index if not exists idx_documents_type  on documents(user_id, document_type);
create index if not exists idx_documents_year  on documents(user_id, financial_year)
    where financial_year is not null;
