CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY,
  full_name VARCHAR(120) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS credit_cards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  credit_limit NUMERIC(12, 2) NOT NULL CHECK (credit_limit > 0),
  status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'blocked')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS credit_cards_user_id_idx ON credit_cards(user_id);
CREATE INDEX IF NOT EXISTS credit_cards_active_idx ON credit_cards(status) WHERE deleted_at IS NULL;

INSERT INTO users (id, full_name, email) VALUES
  ('11111111-1111-4111-8111-111111111111', 'Jose Gerardo Santizo', 'jose.gerardo@gmail.com'),
  ('22222222-2222-4222-8222-222222222222', 'Wuenfril Levi Matias', 'levi.matias@gmail.com'),
  ('33333333-3333-4333-8333-333333333333', 'Enrique Lopez', 'enrique.lopez@gmail.com')
ON CONFLICT (id) DO NOTHING;

INSERT INTO credit_cards (id, user_id, credit_limit, status) VALUES
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111111', 5000.00, 'active'),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', '22222222-2222-4222-8222-222222222222', 12500.50, 'active'),
  ('cccccccc-cccc-4ccc-8ccc-cccccccccccc', '33333333-3333-4333-8333-333333333333', 3000.00, 'blocked')
ON CONFLICT (id) DO NOTHING;
