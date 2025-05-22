-- Migration to add the missing currency column to transactions table
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS currency VARCHAR(3) DEFAULT 'USD';

-- Add the description column back if missing (from the error it appears this might be in the schema but not in the actual table)
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS description TEXT DEFAULT '';
