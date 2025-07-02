-- Book Swap/PostgreSQL Database Schema

-- USERS TABLE
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    display_name VARCHAR(100),
    profile_img_url TEXT,
    bio TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- BOOKS TABLE
CREATE TABLE books (
    id SERIAL PRIMARY KEY,
    owner_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    author VARCHAR(150) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    image_url TEXT,
    listed_for_swap BOOLEAN DEFAULT TRUE,
    listed_for_sale BOOLEAN DEFAULT FALSE,
    price_cents INTEGER,
    condition VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- SWAP REQUESTS TABLE
CREATE TABLE swaps (
    id SERIAL PRIMARY KEY,
    proposer_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    receiver_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    proposer_book_id INTEGER NOT NULL REFERENCES books(id) ON DELETE CASCADE,
    receiver_book_id INTEGER NOT NULL REFERENCES books(id) ON DELETE CASCADE,
    status VARCHAR(30) NOT NULL CHECK (status IN ('pending', 'accepted', 'rejected', 'cancelled', 'completed')) DEFAULT 'pending',
    message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- PURCHASES TABLE
CREATE TABLE purchases (
    id SERIAL PRIMARY KEY,
    buyer_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    seller_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    book_id INTEGER NOT NULL REFERENCES books(id) ON DELETE CASCADE,
    price_cents INTEGER NOT NULL,
    payment_id VARCHAR(255),
    payment_status VARCHAR(30),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- USER HISTORY TABLE
CREATE TABLE user_history (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    action_type VARCHAR(30) NOT NULL, -- e.g., 'swap_requested', 'swap_accepted', 'purchase', 'login', 'profile_update'
    details TEXT,
    related_book_id INTEGER REFERENCES books(id),
    related_user_id INTEGER REFERENCES users(id),
    related_swap_id INTEGER REFERENCES swaps(id),
    related_purchase_id INTEGER REFERENCES purchases(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for faster lookups
CREATE INDEX idx_books_owner_id ON books(owner_id);
CREATE INDEX idx_swaps_proposer_id ON swaps(proposer_id);
CREATE INDEX idx_swaps_receiver_id ON swaps(receiver_id);
CREATE INDEX idx_swaps_status ON swaps(status);
CREATE INDEX idx_purchases_buyer_id ON purchases(buyer_id);
CREATE INDEX idx_purchases_seller_id ON purchases(seller_id);
CREATE INDEX idx_user_history_user_id ON user_history(user_id);

-- Helper to ensure book listed_for_sale implies price_cents is not null
ALTER TABLE books
    ADD CONSTRAINT chk_listed_for_sale_price
    CHECK (NOT listed_for_sale OR price_cents IS NOT NULL);

-- Triggers for automatic 'updated_at' timestamp
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE PROCEDURE update_modified_column();

CREATE TRIGGER trg_update_books_updated_at
    BEFORE UPDATE ON books
    FOR EACH ROW
    EXECUTE PROCEDURE update_modified_column();

CREATE TRIGGER trg_update_swaps_updated_at
    BEFORE UPDATE ON swaps
    FOR EACH ROW
    EXECUTE PROCEDURE update_modified_column();

CREATE TRIGGER trg_update_purchases_updated_at
    BEFORE UPDATE ON purchases
    FOR EACH ROW
    EXECUTE PROCEDURE update_modified_column();

-- END OF SCHEMA
