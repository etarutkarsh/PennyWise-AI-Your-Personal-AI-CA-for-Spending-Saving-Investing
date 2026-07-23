-- Seeds the system-default expense/income categories from PRD Feature 3.
insert into categories (name, type, system_default) values
    ('Food',          'expense', true),
    ('Transport',     'expense', true),
    ('Shopping',      'expense', true),
    ('Travel',        'expense', true),
    ('Health',        'expense', true),
    ('Education',     'expense', true),
    ('Entertainment', 'expense', true),
    ('Investment',    'expense', true),
    ('Rent',          'expense', true),
    ('Bills',         'expense', true),
    ('Insurance',     'expense', true),
    ('Utilities',     'expense', true),
    ('Loans',         'expense', true),
    ('Subscriptions', 'expense', true),
    ('Pets',          'expense', true),
    ('Gifts',         'expense', true),
    ('Luxury',        'expense', true),
    ('Others',        'expense', true),
    ('Salary',        'income',  true),
    ('Other Income',  'income',  true)
on conflict do nothing;
