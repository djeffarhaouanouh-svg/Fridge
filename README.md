# Fridge App 🍽️

Application mobile de recettes basée sur le scan du frigo avec Flutter.

## ✨ Fonctionnalités

- 📷 **Scanner** : Détection d'ingrédients via caméra
- 🍽️ **Repas** : Suggestions de recettes basées sur ingrédients détectés
- 📅 **Plan** : Planning hebdomadaire de repas
- 👤 **Profil** : Objectifs, régime alimentaire, favoris
- 💎 **Premium** : Unlock recettes exclusives (RevenueCat + IAP)

## 🏗️ Architecture

```
lib/
├── core/
│   └── theme/
│       └── app_tokens.dart          # Design tokens (couleurs, espacements)
├── features/
│   ├── camera/
│   │   └── screens/
│   │       └── camera_screen.dart   # Écran scanner
│   ├── meals/
│   │   ├── models/
│   │   │   └── meal.dart           # Modèle Meal + Ingredient
│   │   ├── data/
│   │   │   └── mock_data.dart      # Données mock
│   │   ├── providers/
│   │   │   └── meals_provider.dart # State management Riverpod
│   │   └── screens/
│   │       ├── results_screen.dart # Liste des recettes
│   │       └── recipe_screen.dart  # Fiche recette détaillée
│   ├── plan/
│   │   └── screens/
│   │       └── plan_screen.dart    # Planning hebdo
│   ├── profile/
│   │   └── screens/
│   │       └── profile_screen.dart # Profil utilisateur
│   └── navigation/
│       └── widgets/
│           └── bottom_nav.dart     # Bottom Navigation Bar
└── main.dart                        # Point d'entrée
```

## 🚀 Installation

### 1. Cloner le projet

```bash
cd fridge_app
```

### 2. Installer les dépendances

```bash
flutter pub get
```

### 3. Générer les fichiers Hive

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 📱 Lancer l'app

### iOS
```bash
flutter run -d ios
```

### Android
```bash
flutter run -d android
```

## 🔧 Configuration backend (TODO)

### Supabase Setup

1. Créer un projet sur [supabase.com](https://supabase.com)
2. Créer la table `meals` :

```sql
CREATE TABLE meals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  title TEXT NOT NULL,
  emoji TEXT,
  type TEXT,
  kcal INTEGER,
  difficulty TEXT,
  time TEXT,
  photo TEXT,
  ingredients JSONB,
  steps TEXT[],
  is_favorite BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

3. Ajouter les clés dans `.env` :

```env
SUPABASE_URL=your_url_here
SUPABASE_ANON_KEY=your_anon_key_here
```

### Google Cloud Vision API

1. Créer un projet sur [Google Cloud Console](https://console.cloud.google.com)
2. Activer **Cloud Vision API**
3. Créer une clé API
4. Ajouter dans `.env` :

```env
GOOGLE_VISION_API_KEY=your_key_here
```

### RevenuCat (Paiements)

1. Créer un compte sur [revenuecat.com](https://www.revenuecat.com)
2. Configurer les produits IAP dans App Store Connect & Google Play Console
3. Ajouter dans `.env` :

```env
REVENUECAT_API_KEY_IOS=your_ios_key
REVENUECAT_API_KEY_ANDROID=your_android_key
```

## 🎨 Design

L'UI est basée sur le prototype HTML fourni avec :
- Police : **Syne** (titres) + **DM Sans** (corps)
- Couleurs : Dark mode avec accent vert (#82D28C)
- Navigation : Bottom Nav avec 4 tabs

## 📦 Stack Technique

- **Framework** : Flutter 3.x
- **State Management** : Riverpod
- **Backend** : Supabase
- **Storage local** : Hive
- **Paiements** : RevenuCat (IAP iOS/Android)
- **API IA** : Google Cloud Vision
- **API Recettes** : Spoonacular (optionnel)

## 🔐 Permissions

### iOS (`ios/Runner/Info.plist`)

```xml
<key>NSCameraUsageDescription</key>
<string>Scan des ingrédients de ton frigo</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Sélectionner des photos d'ingrédients</string>
```

### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
```

## 🚧 TODO

- [ ] Intégration Supabase (auth + database)
- [ ] Intégration Google Vision API
- [ ] Intégration RevenuCat
- [ ] Onboarding flow (3 écrans)
- [ ] Animations (fade, slide)
- [ ] Tests unitaires
- [ ] CI/CD (GitHub Actions)

## 📄 License

Propriétaire - Tous droits réservés
