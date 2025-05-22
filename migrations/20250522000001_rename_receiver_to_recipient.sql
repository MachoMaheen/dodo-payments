-- Rename receiver_id to recipient_id in transactions table
ALTER TABLE transactions RENAME COLUMN receiver_id TO recipient_id;

-- Update the index on receiver_id to point to recipient_id
DROP INDEX IF EXISTS idx_transactions_receiver_id;
CREATE INDEX IF NOT EXISTS idx_transactions_recipient_id ON transactions(recipient_id);
