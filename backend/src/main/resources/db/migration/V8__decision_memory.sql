CREATE TABLE decision_memory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    decision_type VARCHAR(50) NOT NULL DEFAULT 'PURCHASE',
    item_name VARCHAR(255),
    item_price NUMERIC(15,2),
    recommendation VARCHAR(50) NOT NULL,
    recommendation_strength VARCHAR(10) NOT NULL,
    recommendation_evidence TEXT,
    recommended_scenario TEXT,
    alternatives TEXT,
    goal_impacts TEXT,
    behavior_snapshot TEXT,
    financial_health_at_decision INT DEFAULT 0,
    review_after DATE NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'PENDING_REVIEW',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE decision_outcome (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    decision_id UUID NOT NULL REFERENCES decision_memory(id) ON DELETE CASCADE,
    actual_choice VARCHAR(100),
    followed_recommendation BOOLEAN,
    notes TEXT,
    reviewed_at DATE NOT NULL DEFAULT CURRENT_DATE,
    goal_delta INT,
    health_delta INT,
    accuracy_score NUMERIC(5,2),
    lessons TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_decision_memory_user_id ON decision_memory(user_id);
CREATE INDEX idx_decision_memory_status ON decision_memory(status);
CREATE INDEX idx_decision_memory_review_after ON decision_memory(review_after);
CREATE INDEX idx_decision_outcome_decision_id ON decision_outcome(decision_id);
