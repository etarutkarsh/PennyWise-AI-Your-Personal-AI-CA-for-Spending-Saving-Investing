alter table chat_history
    add column if not exists updated_at timestamptz default now();
