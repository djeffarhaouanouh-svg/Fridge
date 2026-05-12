-- Fridge — schéma Neon pour RevenueCat (à exécuter une fois dans le SQL Editor Neon si les tables n’existent pas).
-- L’app crée aussi ces objets au démarrage via [NeonService.ensureRelationalSchema] / [ensureUserSyncSchema].

-- Statut premium sur le profil utilisateur (sync après achat / restauration).
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_pro BOOLEAN NOT NULL DEFAULT FALSE;

-- Historique des snapshots d’abonnement (une ligne peut être insérée à chaque sync RC).
CREATE TABLE IF NOT EXISTS subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  revenue_cat_user_id TEXT,
  product_id TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'unknown',
  is_pro BOOLEAN NOT NULL DEFAULT FALSE,
  purchased_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON subscriptions(user_id);
