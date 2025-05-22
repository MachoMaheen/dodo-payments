-- Sample data for development

-- Create extension if it doesn't exist
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Insert sample users (password is 'password123')
INSERT INTO users (username, email, password_hash)
VALUES 
    ('user1', 'user1@example.com', '$argon2id$v=19$m=16,t=2,p=1$cGFzc3dvcmQxMjM$ZyQUfIT6WJGk+p8WAZ6uOA'),
    ('user2', 'user2@example.com', '$argon2id$v=19$m=16,t=2,p=1$cGFzc3dvcmQxMjM$ZyQUfIT6WJGk+p8WAZ6uOA')
ON CONFLICT (username) DO NOTHING;

-- Insert initial account balances
INSERT INTO accounts (user_id, balance, currency)
SELECT id, 1000.00, 'USD' FROM users WHERE username = 'user1'
ON CONFLICT (id) DO NOTHING;

INSERT INTO accounts (user_id, balance, currency)
SELECT id, 500.00, 'USD' FROM users WHERE username = 'user2'
ON CONFLICT (id) DO NOTHING;

-- Insert sample transaction
INSERT INTO transactions (sender_id, receiver_id, amount, description, status)
SELECT 
    (SELECT id FROM users WHERE username = 'user1'),
    (SELECT id FROM users WHERE username = 'user2'),
    100.00,
    'Sample payment',
    'completed'
WHERE EXISTS (SELECT 1 FROM users WHERE username = 'user1')
  AND EXISTS (SELECT 1 FROM users WHERE username = 'user2')
  AND NOT EXISTS (
      SELECT 1 FROM transactions 
      WHERE description = 'Sample payment' 
      AND sender_id = (SELECT id FROM users WHERE username = 'user1')
      AND receiver_id = (SELECT id FROM users WHERE username = 'user2')
  );