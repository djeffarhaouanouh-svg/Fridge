-- =============================================================================
-- Fridge — schéma PostgreSQL pour Neon (compatible lib/core/services/neon_service.dart)
-- Exécuter dans Neon → SQL Editor. En cas d’erreur sur une table déjà mal créée,
-- voir la section « Nettoyage optionnel » en bas (après sauvegarde).
-- =============================================================================

BEGIN;

-- UUID (souvent déjà activé sur Neon)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ─────────────────────────────────────────────────────────────────────────────
-- 1) Table users : ajouter les colonnes manquantes (ta table existe déjà)
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS cooking_level TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS fridge_ingredients_json TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS plan_selections_json TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_login_date DATE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS login_streak INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS scan_meals_json TEXT;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2) Tables relationnelles (CREATE IF NOT EXISTS — ordre des FK respecté)
-- ─────────────────────────────────────────────────────────────────────────----

CREATE TABLE IF NOT EXISTS nutrition_profiles (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  calories INTEGER NOT NULL DEFAULT 2000,
  proteins INTEGER NOT NULL DEFAULT 150,
  carbs INTEGER NOT NULL DEFAULT 200,
  fats INTEGER NOT NULL DEFAULT 65
);

-- Objectifs cuisine (perte de poids, etc.) — PAS la table "goals" générique Neon
CREATE TABLE IF NOT EXISTS user_goals (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  goal TEXT
);

CREATE TABLE IF NOT EXISTS allergies (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS diets (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS user_allergies (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  allergy_id INTEGER NOT NULL REFERENCES allergies(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, allergy_id)
);

CREATE TABLE IF NOT EXISTS user_diets (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  diet_id INTEGER NOT NULL REFERENCES diets(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, diet_id)
);

CREATE TABLE IF NOT EXISTS user_notifications (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  notif_expiry BOOLEAN NOT NULL DEFAULT TRUE,
  notif_suggestion BOOLEAN NOT NULL DEFAULT TRUE,
  notif_fridge BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS recipes (
  id UUID PRIMARY KEY,
  title TEXT NOT NULL,
  image_url TEXT,
  duration INTEGER NOT NULL DEFAULT 0,
  calories INTEGER NOT NULL DEFAULT 0,
  difficulty TEXT,
  type TEXT,
  type_label TEXT,
  emoji TEXT,
  color TEXT,
  locked BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS ingredients (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS recipe_steps (
  recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  step_order INTEGER NOT NULL,
  instruction TEXT NOT NULL,
  PRIMARY KEY (recipe_id, step_order)
);

CREATE TABLE IF NOT EXISTS recipe_ingredients (
  recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  ingredient_id INTEGER NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
  quantity DOUBLE PRECISION,
  unit TEXT,
  PRIMARY KEY (recipe_id, ingredient_id)
);

CREATE TABLE IF NOT EXISTS favorites (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, recipe_id)
);

CREATE TABLE IF NOT EXISTS cooked_recipes (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, recipe_id)
);

CREATE TABLE IF NOT EXISTS meal_plans (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  meal_type TEXT NOT NULL,
  recipe_id UUID REFERENCES recipes(id) ON DELETE SET NULL,
  PRIMARY KEY (user_id, date, meal_type)
);

COMMIT;

-- =============================================================================
-- Index utiles (optionnel, idempotent)
-- =============================================================================
CREATE INDEX IF NOT EXISTS idx_favorites_user ON favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_recipe ON favorites(recipe_id);
CREATE INDEX IF NOT EXISTS idx_meal_plans_user_date ON meal_plans(user_id, date);
CREATE INDEX IF NOT EXISTS idx_cooked_user ON cooked_recipes(user_id);

-- =============================================================================
-- NETTOYAGE OPTIONNEL — uniquement si une table existe avec un mauvais schéma
-- et qu’elle est VIDE ou jetable. À commenter/décommenter avec précaution.
-- =============================================================================
-- La table "goals" fournie par certains templates Neon ne correspond pas à l’app
-- (colonnes title/description/…). L’app utilise user_goals à la place.
--
-- DROP TABLE IF EXISTS goals CASCADE;
--
-- Si "recipes" ou "ingredients" a été créée avec un autre schéma et bloque les INSERT :
-- sauvegarder les données, puis par exemple :
-- DROP TABLE IF EXISTS recipe_ingredients CASCADE;
-- DROP TABLE IF EXISTS recipe_steps CASCADE;
-- DROP TABLE IF EXISTS favorites CASCADE;
-- DROP TABLE IF EXISTS cooked_recipes CASCADE;
-- DROP TABLE IF EXISTS meal_plans CASCADE;
-- DROP TABLE IF EXISTS recipes CASCADE;
-- DROP TABLE IF EXISTS ingredients CASCADE;
-- … puis ré-exécuter uniquement les CREATE TABLE correspondantes de ce fichier.
