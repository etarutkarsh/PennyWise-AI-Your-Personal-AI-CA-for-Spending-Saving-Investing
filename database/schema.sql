-- =====================================================================
-- PennyWise AI - PostgreSQL Schema (PRD Section 13)
-- =====================================================================
-- This file is the canonical reference schema for the whole roadmap
-- (Phase 1-4). The backend's Flyway migration
-- (backend/src/main/resources/db/migration/V1__init.sql) currently
-- creates all of these tables so later phases don't require a
-- structural migration, but only Phase 1 tables are actively written
-- to by the current codebase:
--   users, categories, transactions, budgets, goals
--
-- Everything else (investment_portfolio, assets, liabilities,
-- learning_progress, notifications, achievements, savings_rules,
-- affordability_history, chat_history) is provisioned ahead of time
-- for Phase 2-4 features described in the PRD.
-- =====================================================================

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------
-- Users
-- ---------------------------------------------------------------------
create table if not exists users (
    id                  uuid primary key default gen_random_uuid(),
    email               varchar(255) not null unique,
    password_hash       varchar(255) not null,
    full_name           varchar(255),
    phone_number        varchar(32),
    user_type           varchar(32),   -- student | professional | freelancer | family
    date_of_birth       date,
    monthly_income      numeric(14,2),
    currency            varchar(3) default 'INR',
    risk_appetite       varchar(16),   -- low | medium | high
    onboarding_complete boolean default false,
    created_at          timestamptz default now(),
    updated_at          timestamptz default now()
);

-- ---------------------------------------------------------------------
-- Categories
-- ---------------------------------------------------------------------
create table if not exists categories (
    id              uuid primary key default gen_random_uuid(),
    name            varchar(100) not null,
    icon            varchar(64),
    type            varchar(16) not null default 'expense', -- expense | income
    user_id         uuid references users(id) on delete cascade, -- null = system default
    system_default  boolean default true,
    created_at      timestamptz default now(),
    updated_at      timestamptz default now()
);

create index if not exists idx_categories_user on categories(user_id);

-- ---------------------------------------------------------------------
-- Transactions
-- ---------------------------------------------------------------------
create table if not exists transactions (
    id                  uuid primary key default gen_random_uuid(),
    user_id             uuid not null references users(id) on delete cascade,
    amount              numeric(14,2) not null,
    merchant            varchar(255),
    note                text,
    category_id         uuid references categories(id) on delete set null,
    transaction_date    timestamptz not null,
    payment_method      varchar(32),   -- UPI | CARD | CASH | NETBANKING | WALLET
    direction           varchar(8) not null, -- DEBIT | CREDIT
    source              varchar(32) not null default 'MANUAL', -- SMS | BANK_NOTIFICATION | MANUAL | EMAIL | OCR
    recurring           boolean default false,
    category_confidence double precision,
    created_at          timestamptz default now(),
    updated_at          timestamptz default now()
);

create index if not exists idx_transactions_user_date on transactions(user_id, transaction_date desc);
create index if not exists idx_transactions_category on transactions(category_id);

-- ---------------------------------------------------------------------
-- Budgets
-- ---------------------------------------------------------------------
create table if not exists budgets (
    id                       uuid primary key default gen_random_uuid(),
    user_id                  uuid not null references users(id) on delete cascade,
    category_id              uuid not null references categories(id) on delete cascade,
    monthly_limit            numeric(14,2) not null,
    period                   varchar(7) not null, -- "YYYY-MM"
    spent_so_far             numeric(14,2) default 0,
    alerts_enabled           boolean default true,
    alert_threshold_percent  int default 80,
    created_at               timestamptz default now(),
    updated_at               timestamptz default now(),
    unique (user_id, category_id, period)
);

create index if not exists idx_budgets_user_period on budgets(user_id, period);

-- ---------------------------------------------------------------------
-- Goals
-- ---------------------------------------------------------------------
create table if not exists goals (
    id                                  uuid primary key default gen_random_uuid(),
    user_id                             uuid not null references users(id) on delete cascade,
    name                                varchar(255) not null,
    goal_type                           varchar(32) not null, -- house|car|vacation|laptop|wedding|emergency_fund|retirement|education|custom
    target_amount                      numeric(14,2) not null,
    current_saved                      numeric(14,2) default 0,
    deadline                           date not null,
    priority                           varchar(16) default 'medium',
    recommended_monthly_contribution   numeric(14,2),
    investment_suggestion              varchar(32), -- liquid_fund|rd|hybrid_fund|equity|debt|fd|mixed
    achieved                           boolean default false,
    created_at                         timestamptz default now(),
    updated_at                         timestamptz default now()
);

create index if not exists idx_goals_user on goals(user_id);

-- ---------------------------------------------------------------------
-- Investment Portfolio (Phase 3)
-- ---------------------------------------------------------------------
create table if not exists investment_portfolio (
    id              uuid primary key default gen_random_uuid(),
    user_id         uuid not null references users(id) on delete cascade,
    instrument_type varchar(32) not null, -- mutual_fund|stock|etf|gold|fd|ppf|nps|bond|reit|sip
    name            varchar(255) not null,
    invested_amount numeric(14,2) not null,
    current_value   numeric(14,2),
    units           numeric(18,6),
    started_on      date,
    created_at      timestamptz default now(),
    updated_at      timestamptz default now()
);

create index if not exists idx_investment_user on investment_portfolio(user_id);

-- ---------------------------------------------------------------------
-- Assets (Phase 4 - net worth tracker)
-- ---------------------------------------------------------------------
create table if not exists assets (
    id           uuid primary key default gen_random_uuid(),
    user_id      uuid not null references users(id) on delete cascade,
    asset_type   varchar(64) not null, -- real_estate|vehicle|cash|jewelry|other
    name         varchar(255),
    value        numeric(14,2) not null,
    as_of_date   date default current_date,
    created_at   timestamptz default now(),
    updated_at   timestamptz default now()
);

-- ---------------------------------------------------------------------
-- Liabilities (Phase 4)
-- ---------------------------------------------------------------------
create table if not exists liabilities (
    id              uuid primary key default gen_random_uuid(),
    user_id         uuid not null references users(id) on delete cascade,
    liability_type  varchar(64) not null, -- home_loan|car_loan|personal_loan|credit_card|other
    name            varchar(255),
    outstanding     numeric(14,2) not null,
    monthly_emi     numeric(14,2),
    interest_rate   numeric(5,2),
    as_of_date      date default current_date,
    created_at      timestamptz default now(),
    updated_at      timestamptz default now()
);

-- ---------------------------------------------------------------------
-- Learning Progress (Feature 11 - Learning Mode)
-- ---------------------------------------------------------------------
create table if not exists learning_progress (
    id             uuid primary key default gen_random_uuid(),
    user_id        uuid not null references users(id) on delete cascade,
    topic          varchar(128) not null,
    lesson_id      varchar(64) not null,
    completed      boolean default false,
    quiz_score     int,
    completed_at   timestamptz,
    created_at     timestamptz default now(),
    unique (user_id, lesson_id)
);

-- ---------------------------------------------------------------------
-- Notifications / AI Alerts (Feature 14)
-- ---------------------------------------------------------------------
create table if not exists notifications (
    id          uuid primary key default gen_random_uuid(),
    user_id     uuid not null references users(id) on delete cascade,
    type        varchar(64) not null, -- overspend|shopping_spike|sip_suggestion|subscription_unused|bill_anomaly
    title       varchar(255) not null,
    body        text,
    read        boolean default false,
    created_at  timestamptz default now()
);

create index if not exists idx_notifications_user_unread on notifications(user_id, read);

-- ---------------------------------------------------------------------
-- Achievements / Gamification (Feature 15)
-- ---------------------------------------------------------------------
create table if not exists achievements (
    id              uuid primary key default gen_random_uuid(),
    user_id         uuid not null references users(id) on delete cascade,
    code            varchar(64) not null, -- e.g. "100_DAYS_SAVING", "FIRST_SIP"
    title           varchar(255) not null,
    unlocked_at     timestamptz default now(),
    unique (user_id, code)
);

-- ---------------------------------------------------------------------
-- Savings Rules (Feature 6 - Savings Coach automations)
-- ---------------------------------------------------------------------
create table if not exists savings_rules (
    id              uuid primary key default gen_random_uuid(),
    user_id         uuid not null references users(id) on delete cascade,
    trigger_type    varchar(64) not null, -- category_overspend|round_up|surplus_sweep
    category_id     uuid references categories(id) on delete set null,
    config          jsonb,
    active          boolean default true,
    created_at      timestamptz default now(),
    updated_at      timestamptz default now()
);

-- ---------------------------------------------------------------------
-- Affordability History (Feature 4 - audit trail of checks)
-- ---------------------------------------------------------------------
create table if not exists affordability_history (
    id                          uuid primary key default gen_random_uuid(),
    user_id                     uuid not null references users(id) on delete cascade,
    item_name                   varchar(255) not null,
    price                       numeric(14,2) not null,
    verdict                     varchar(32) not null, -- SAFE_TO_BUY|WAIT_AND_SAVE|DONT_BUY
    reason                      text,
    recommended_wait_months     int,
    expected_purchase_date      date,
    checked_at                  timestamptz default now()
);

create index if not exists idx_affordability_user on affordability_history(user_id, checked_at desc);

-- ---------------------------------------------------------------------
-- Chat History (Feature 10 - AI Financial Assistant)
-- ---------------------------------------------------------------------
create table if not exists chat_history (
    id          uuid primary key default gen_random_uuid(),
    user_id     uuid not null references users(id) on delete cascade,
    role        varchar(16) not null, -- user | assistant
    message     text not null,
    created_at  timestamptz default now()
);

create index if not exists idx_chat_history_user on chat_history(user_id, created_at);
