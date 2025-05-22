-- -- Create users table
-- CREATE TABLE IF NOT EXISTS users (
--     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--     username VARCHAR(50) NOT NULL UNIQUE,
--     email VARCHAR(255) NOT NULL UNIQUE,
--     password_hash VARCHAR(255) NOT NULL,
--     created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
--     updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
-- );

-- -- Create accounts table
-- CREATE TABLE IF NOT EXISTS accounts (
--     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--     user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
--     balance NUMERIC(19, 4) NOT NULL DEFAULT 0,
--     currency VARCHAR(3) NOT NULL DEFAULT 'USD',
--     created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
--     updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
--     UNIQUE(user_id, currency)
-- );

-- -- Create transaction status enum
-- DO $$ 
-- BEGIN 
--     IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'transaction_status') THEN
--         CREATE TYPE transaction_status AS ENUM ('pending', 'completed', 'failed');
--     END IF;
-- END $$;

-- -- Create transactions table
-- CREATE TABLE IF NOT EXISTS transactions (
--     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--     sender_id UUID NOT NULL REFERENCES users(id),
--     recipient_id UUID NOT NULL REFERENCES users(id),
--     amount NUMERIC(19, 4) NOT NULL,
--     currency VARCHAR(3) NOT NULL,
--     status transaction_status NOT NULL DEFAULT 'pending',
--     created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
--     updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
-- );

-- -- Create trigger to update the updated_at timestamp automatically
-- CREATE OR REPLACE FUNCTION update_updated_at_column()
-- RETURNS TRIGGER AS $$
-- BEGIN
--     NEW.updated_at = NOW();
--     RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;

-- -- Apply trigger to users table
-- DROP TRIGGER IF EXISTS update_users_updated_at ON users;
-- CREATE TRIGGER update_users_updated_at
-- BEFORE UPDATE ON users
-- FOR EACH ROW
-- EXECUTE FUNCTION update_updated_at_column();

-- -- Apply trigger to accounts table
-- DROP TRIGGER IF EXISTS update_accounts_updated_at ON accounts;
-- CREATE TRIGGER update_accounts_updated_at
-- BEFORE UPDATE ON accounts
-- FOR EACH ROW
-- EXECUTE FUNCTION update_updated_at_column();

-- -- Apply trigger to transactions table
-- DROP TRIGGER IF EXISTS update_transactions_updated_at ON transactions;
-- CREATE TRIGGER update_transactions_updated_at
-- BEFORE UPDATE ON transactions
-- FOR EACH ROW
-- EXECUTE FUNCTION update_updated_at_column();

-- -- Create indexes for better performance
-- CREATE INDEX IF NOT EXISTS idx_transactions_sender_id ON transactions(sender_id);
-- CREATE INDEX IF NOT EXISTS idx_transactions_recipient_id ON transactions(recipient_id);
-- CREATE INDEX IF NOT EXISTS idx_accounts_user_id ON accounts(user_id);



-- Initial schema for Dodo Payments

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create indices for users
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Accounts table
CREATE TABLE IF NOT EXISTS accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    balance NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create indices for accounts
CREATE INDEX IF NOT EXISTS idx_accounts_user_id ON accounts(user_id);

-- Transactions table
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID NOT NULL REFERENCES users(id),
    receiver_id UUID NOT NULL REFERENCES users(id),
    amount NUMERIC(15, 2) NOT NULL,
    description TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create indices for transactions
CREATE INDEX IF NOT EXISTS idx_transactions_sender_id ON transactions(sender_id);
CREATE INDEX IF NOT EXISTS idx_transactions_receiver_id ON transactions(receiver_id);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions(created_at DESC);