-- Add BaseEntity audit columns to tables created before audit tracking was standardised

-- achievements: had unlocked_at but not created_at / updated_at
alter table achievements
    add column if not exists created_at  timestamptz default now(),
    add column if not exists updated_at  timestamptz default now();

-- learning_progress: had created_at but not updated_at
alter table learning_progress
    add column if not exists updated_at  timestamptz default now();

-- notifications: had created_at but not updated_at
alter table notifications
    add column if not exists updated_at  timestamptz default now();
