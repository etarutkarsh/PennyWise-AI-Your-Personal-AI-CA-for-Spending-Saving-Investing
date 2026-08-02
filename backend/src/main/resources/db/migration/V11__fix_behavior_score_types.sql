-- Hibernate validates SMALLINT (int2) as INTEGER (int4) mismatch — promote all score columns
ALTER TABLE behavior_profile
    ALTER COLUMN discipline_score          TYPE INTEGER,
    ALTER COLUMN consistency_score         TYPE INTEGER,
    ALTER COLUMN impulse_score             TYPE INTEGER,
    ALTER COLUMN risk_behavior_score       TYPE INTEGER,
    ALTER COLUMN goal_commitment_score     TYPE INTEGER,
    ALTER COLUMN savings_discipline_score  TYPE INTEGER,
    ALTER COLUMN spending_stability_score  TYPE INTEGER,
    ALTER COLUMN recommendation_follow_rate TYPE INTEGER,
    ALTER COLUMN events_analyzed           TYPE INTEGER,
    ALTER COLUMN decisions_analyzed        TYPE INTEGER,
    ALTER COLUMN months_of_data            TYPE INTEGER;
