CREATE TABLE financial_events (
    id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID         NOT NULL,
    event_type    VARCHAR(100) NOT NULL,
    payload       TEXT,
    correlation_id UUID,
    source        VARCHAR(100),
    occurred_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    processed_at  TIMESTAMPTZ
);

CREATE INDEX idx_financial_events_user_id        ON financial_events(user_id);
CREATE INDEX idx_financial_events_event_type     ON financial_events(event_type);
CREATE INDEX idx_financial_events_occurred_at    ON financial_events(occurred_at DESC);
CREATE INDEX idx_financial_events_user_type_time ON financial_events(user_id, event_type, occurred_at DESC);
