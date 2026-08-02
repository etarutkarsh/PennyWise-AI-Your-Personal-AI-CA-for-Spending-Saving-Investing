CREATE TABLE behavior_profile (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                     UUID NOT NULL UNIQUE,

    -- Behavior scores (0–100)
    discipline_score            SMALLINT NOT NULL DEFAULT 50,
    consistency_score           SMALLINT NOT NULL DEFAULT 50,
    impulse_score               SMALLINT NOT NULL DEFAULT 50,  -- lower = more impulsive
    risk_behavior_score         SMALLINT NOT NULL DEFAULT 50,
    goal_commitment_score       SMALLINT NOT NULL DEFAULT 50,
    savings_discipline_score    SMALLINT NOT NULL DEFAULT 50,
    spending_stability_score    SMALLINT NOT NULL DEFAULT 50,
    recommendation_follow_rate  SMALLINT NOT NULL DEFAULT 0,   -- % of recommendations followed

    -- Pattern flags (JSON array of detected pattern strings)
    detected_patterns           TEXT,

    -- Traits (JSON object: {"discipline":"A","impulseControl":"B+","goalCommitment":"A-",...})
    traits_json                 TEXT,

    -- Insights (JSON array of insight strings)
    insights_json               TEXT,

    -- Primary and secondary behavior classifications
    primary_behavior            VARCHAR(60),   -- e.g. "Consistent Saver"
    secondary_behavior          VARCHAR(60),   -- e.g. "Salary Euphoria"

    -- Sample sizes for confidence
    events_analyzed             INT NOT NULL DEFAULT 0,
    decisions_analyzed          INT NOT NULL DEFAULT 0,
    months_of_data              INT NOT NULL DEFAULT 0,

    last_computed_at            TIMESTAMPTZ,
    created_at                  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT fk_behavior_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_behavior_profile_user ON behavior_profile (user_id);
