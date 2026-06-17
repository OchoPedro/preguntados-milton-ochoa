# Preguntados Milton Ochoa

Juego de trivia multijugador en tiempo real para la empresa Milton Ochoa.

## Stack

- **Frontend/Mobile**: Flutter (iOS, Android, Web/PWA)
- **Backend**: Supabase (PostgreSQL + Auth + Realtime + Edge Functions)
- **Preguntas**: Claude API (`claude-haiku-4-5-20251001`)
- **Notificaciones**: Firebase Cloud Messaging

---

## Setup inicial

### 1. Clonar e instalar Flutter

```bash
# Instalar Flutter: https://docs.flutter.dev/get-started/install
flutter pub get
```

### 2. Crear proyecto en Supabase

1. Ir a [supabase.com](https://supabase.com) → New project
2. Copiar `Project URL` y `anon key`
3. Ejecutar las migraciones en orden:

```bash
# En el dashboard de Supabase → SQL Editor
# Ejecutar: supabase/migrations/001_initial_schema.sql
# Ejecutar: supabase/migrations/002_functions.sql
```

### 3. Configurar variables de entorno

```bash
cp .env.example .env
# Llenar SUPABASE_URL, SUPABASE_ANON_KEY, CLAUDE_API_KEY
```

### 4. Pasar variables a Flutter

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ... \
  --dart-define=CLAUDE_API_KEY=sk-ant-...
```

### 5. Desplegar Edge Functions

```bash
# Instalar Supabase CLI: https://supabase.com/docs/guides/cli
supabase login
supabase link --project-ref TU_PROJECT_ID

supabase functions deploy generate-questions
supabase functions deploy start-game
supabase functions deploy validate-answer

# Configurar secretos en las Edge Functions
supabase secrets set CLAUDE_API_KEY=sk-ant-...
```

### 6. Poblar preguntas iniciales

Una vez desplegadas las Edge Functions, llamar desde el dashboard:

```bash
curl -X POST https://TU_PROJECT.supabase.co/functions/v1/generate-questions \
  -H "Authorization: Bearer TU_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"count": 100}'
```

---

## Arquitectura de carpetas

```
lib/
├── main.dart                    # Entrada de la app
├── app.dart                     # MaterialApp + router
├── core/
│   ├── constants/
│   │   ├── app_colors.dart      # Paleta de colores Milton Ochoa
│   │   └── app_constants.dart   # Config del juego (puntos, tiempos, etc.)
│   ├── theme/app_theme.dart     # ThemeData oscuro
│   ├── router/app_router.dart   # GoRouter con guards de auth
│   └── utils/env.dart           # Variables de entorno
├── data/
│   ├── models/                  # PODOs serializables desde JSON
│   │   ├── profile_model.dart
│   │   ├── question_model.dart
│   │   ├── room_model.dart
│   │   └── game_round_model.dart
│   └── repositories/
│       └── room_repository.dart # Acceso a Supabase + Realtime
├── presentation/
│   ├── providers/
│   │   ├── game_provider.dart   # Estado del juego (StateNotifier)
│   │   └── profile_provider.dart
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── auth/                # Login, Register
│   │   ├── home/                # Home con botones de juego
│   │   ├── game/                # Lobby, GameScreen, Results
│   │   ├── profile/             # Perfil + comodines
│   │   ├── leaderboard/         # Ranking global y semanal
│   │   └── prizes/              # Tienda de premios
│   └── widgets/
│       ├── common/              # AppButton reutilizable
│       └── game/                # QuestionCard, TimerBar, etc.
└── services/
    ├── supabase_service.dart    # Inicialización + helpers de auth
    └── claude_service.dart      # Generación de preguntas vía API

supabase/
├── migrations/
│   ├── 001_initial_schema.sql   # Tablas, RLS, triggers
│   └── 002_functions.sql        # Funciones SQL del juego
└── functions/
    ├── generate-questions/      # Llama a Claude y cachea en BD
    ├── start-game/              # Inicia partida y primera ronda
    └── validate-answer/         # Valida respuesta server-side
```

---

## Publicación

### App Store (iOS)
```bash
flutter build ipa
# Subir a App Store Connect con Xcode o Transporter
```

### Play Store (Android)
```bash
flutter build appbundle
# Subir el .aab en Google Play Console
```

### Web (PWA)
```bash
flutter build web --release
# Desplegar la carpeta build/web en Vercel, Netlify o Firebase Hosting
```
