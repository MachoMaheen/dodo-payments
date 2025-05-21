-- Insert test users with hashed passwords (password: password123)
-- These are for development/testing only!
INSERT INTO users (id, username, email, password_hash)
VALUES 
    ('00000000-0000-0000-0000-000000000001', 'test_user1', 'user1@example.com', '$argon2id$v=19$m=19456,t=2,p=1$VFpGNlc4QzRFMm9CTFlJZg$N9jPPPB4Vcim5zTcO5oUaTqZbDRI5m63wNRafG5GQpY'),
    ('00000000-0000-0000-0000-000000000002', 'test_user2', 'user2@example.com', '$argon2id$v=19$m=19456,t=2,p=1$VzVMODJMRGRaSTlxYmJLTA$2gfTj7lXvvJlIV/wNXqXdkhZbpugJFoOtNZP8SzIjx4')
ON CONFLICT DO NOTHING;

-- Create accounts for test users with initial balances
INSERT INTO accounts (user_id, balance, currency)
VALUES 
    ('00000000-0000-0000-0000-000000000001', 1000.00, 'USD'),
    ('00000000-0000-0000-0000-000000000002', 500.00, 'USD')
ON CONFLICT (user_id) DO NOTHING;
