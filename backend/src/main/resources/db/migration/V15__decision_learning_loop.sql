-- V15: Decision Learning Loop
-- Closes the 8-step loop: Generated → Executed → Observed → Evaluated → Learned → Behavior Updated → Twin Calibrated
-- Each table maps to a distinct step with full provenance and attribution.

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 3: Execution Detection
-- Records whether a decision was actually executed (from any source)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE decision_executions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    decision_id     UUID        NOT NULL,
    user_id         UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    executed        BOOLEAN     NOT NULL,
    execution_source VARCHAR(32) NOT NULL
        CHECK (execution_source IN ('USER_CONFIRMED', 'TRANSACTION_DETECTED',
                                    'SMS_DETECTED', 'AA_VERIFIED', 'INFERRED')),
    executed_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    amount_executed NUMERIC(15, 2),
    confidence      NUMERIC(4, 3) NOT NULL DEFAULT 1.000
        CHECK (confidence BETWEEN 0 AND 1),
    note            TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (decision_id)
);

CREATE INDEX idx_decision_executions_user ON decision_executions(user_id);
CREATE INDEX idx_decision_executions_decision ON decision_executions(decision_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- Steps 4–5: Observation + Evaluation
-- Multi-dimensional outcome measured ~60 days post-execution
-- DEV = observed_health_delta - predicted_health_delta
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE decision_outcomes (
    id                              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    decision_id                     UUID        NOT NULL,
    user_id                         UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    observed_at                     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    overall_outcome                 VARCHAR(16) NOT NULL
        CHECK (overall_outcome IN ('BETTER', 'WORSE', 'AS_EXPECTED', 'NO_DATA')),
    decision_expectation_variance   NUMERIC(6, 2) NOT NULL DEFAULT 0,
    predicted_health_delta          INT,
    observed_health_delta           INT,
    baseline_health_score           INT,
    observed_health_score           INT,
    emergency_fund_delta            NUMERIC(5, 2),
    savings_rate_delta              NUMERIC(5, 4),
    debt_ratio_delta                NUMERIC(5, 4),
    goal_progress_delta             NUMERIC(5, 4),
    stress_reduced                  BOOLEAN,
    investment_consistency          BOOLEAN,
    attribution_confidence          NUMERIC(4, 3) NOT NULL DEFAULT 0.500
        CHECK (attribution_confidence BETWEEN 0 AND 1),
    created_at                      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (decision_id)
);

CREATE INDEX idx_decision_outcomes_user ON decision_outcomes(user_id);
CREATE INDEX idx_decision_outcomes_observed_at ON decision_outcomes(observed_at);

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 6: Learned Lessons
-- Extracted from significant outcomes — drives BehavioralVector calibration
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE decision_lessons (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    lesson_type         VARCHAR(32) NOT NULL
        CHECK (lesson_type IN ('BEHAVIOR_PATTERN', 'REJECTION_PATTERN',
                               'POSITIVE_DEVIATION', 'NEGATIVE_DEVIATION',
                               'SEASONAL_PATTERN', 'HEALTH_IMPACT',
                               'TIMELINE_MISCALIBRATION')),
    extracted_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    confidence_score    NUMERIC(4, 3) NOT NULL
        CHECK (confidence_score BETWEEN 0 AND 1),
    observations        INT         NOT NULL DEFAULT 1,
    last_validated      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    summary             TEXT        NOT NULL,
    evidence            TEXT        NOT NULL,
    target_parameters   TEXT[]      NOT NULL DEFAULT '{}',
    suggested_deltas    JSONB       NOT NULL DEFAULT '{}',
    seasonal_context    VARCHAR(64),
    is_active           BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_decision_lessons_user ON decision_lessons(user_id);
CREATE INDEX idx_decision_lessons_active ON decision_lessons(user_id, is_active);
CREATE INDEX idx_decision_lessons_confidence ON decision_lessons(confidence_score DESC);

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 7: Behavior Adjustments
-- Individual parameter deltas applied to BehavioralVector
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE behavior_adjustments (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    source_lesson_id    UUID        NOT NULL REFERENCES decision_lessons(id) ON DELETE CASCADE,
    applied_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    parameter           VARCHAR(64) NOT NULL,
    old_value           NUMERIC(8, 6) NOT NULL,
    new_value           NUMERIC(8, 6) NOT NULL,
    delta               NUMERIC(8, 6) NOT NULL GENERATED ALWAYS AS (new_value - old_value) STORED,
    rationale           TEXT        NOT NULL,
    engine_version      VARCHAR(64) NOT NULL
);

CREATE INDEX idx_behavior_adjustments_user ON behavior_adjustments(user_id);
CREATE INDEX idx_behavior_adjustments_lesson ON behavior_adjustments(source_lesson_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 8: Twin Calibration Events
-- Domain events emitted after vector updates — consumed by Digital Twin
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE twin_calibrations (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    calibrated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    previous_vector     JSONB       NOT NULL,
    updated_vector      JSONB       NOT NULL,
    source_lesson_ids   UUID[]      NOT NULL DEFAULT '{}',
    parameters_affected INT         NOT NULL DEFAULT 0,
    summary             TEXT        NOT NULL,
    engine_version      VARCHAR(64) NOT NULL
);

CREATE INDEX idx_twin_calibrations_user ON twin_calibrations(user_id);
CREATE INDEX idx_twin_calibrations_at ON twin_calibrations(calibrated_at DESC);

-- ─────────────────────────────────────────────────────────────────────────────
-- Learning Snapshots
-- Point-in-time accumulated learning state (for audit + Digital Twin replay)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE learning_snapshots (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    snapshot_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_cycles    INT         NOT NULL DEFAULT 0,
    outcomes_observed   INT         NOT NULL DEFAULT 0,
    maturity            NUMERIC(4, 3) NOT NULL DEFAULT 0.000
        CHECK (maturity BETWEEN 0 AND 1),
    behavioral_vector   JSONB       NOT NULL,
    active_lesson_ids   UUID[]      NOT NULL DEFAULT '{}'
);

CREATE INDEX idx_learning_snapshots_user ON learning_snapshots(user_id);
CREATE INDEX idx_learning_snapshots_at ON learning_snapshots(snapshot_at DESC);
