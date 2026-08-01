-- Phone-based OTP auth: unique partial index so two users can't share a phone
-- number, while NULLs are still allowed (existing email-only accounts).
create unique index if not exists idx_users_phone_unique
    on users (phone_number)
    where phone_number is not null;
