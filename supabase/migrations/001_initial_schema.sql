-- ============================================================
-- PREGUNTADOS MILTON OCHOA — Esquema inicial de base de datos
-- ============================================================

-- Extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- PERFILES DE USUARIO (extiende auth.users de Supabase)
-- ============================================================
CREATE TABLE public.profiles (
  id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username      TEXT UNIQUE NOT NULL,
  display_name  TEXT NOT NULL,
  avatar_url    TEXT,
  total_points  INTEGER NOT NULL DEFAULT 0,
  level_id      INTEGER NOT NULL DEFAULT 1,
  games_played  INTEGER NOT NULL DEFAULT 0,
  games_won     INTEGER NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- NIVELES (configuración)
-- ============================================================
CREATE TABLE public.levels (
  id            INTEGER PRIMARY KEY,
  name          TEXT NOT NULL,
  min_points    INTEGER NOT NULL,
  max_points    INTEGER,
  badge_url     TEXT,
  color_hex     TEXT NOT NULL DEFAULT '#1E3A5F'
);

INSERT INTO public.levels (id, name, min_points, max_points, color_hex) VALUES
  (1, 'Aspirante',             0,      999,   '#8B9DC3'),
  (2, 'Saber',              1000,     4999,   '#4A90D9'),
  (3, 'Élite',              5000,    14999,   '#C9A84C'),
  (4, 'Leyenda Milton Ochoa', 15000,  NULL,   '#D4AF37');

-- ============================================================
-- PREGUNTAS (caché generado por Claude)
-- ============================================================
CREATE TABLE public.questions (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  question_text TEXT NOT NULL,
  option_a      TEXT NOT NULL,
  option_b      TEXT NOT NULL,
  option_c      TEXT NOT NULL,
  option_d      TEXT NOT NULL,
  correct_option CHAR(1) NOT NULL CHECK (correct_option IN ('A','B','C','D')),
  difficulty    INTEGER NOT NULL CHECK (difficulty IN (1, 2, 3)),
  category      TEXT NOT NULL,
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,
  times_used    INTEGER NOT NULL DEFAULT 0,
  times_correct INTEGER NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_questions_difficulty ON public.questions(difficulty) WHERE is_active = TRUE;
CREATE INDEX idx_questions_category   ON public.questions(category)   WHERE is_active = TRUE;

-- ============================================================
-- SALAS DE JUEGO
-- ============================================================
CREATE TYPE room_status AS ENUM ('waiting', 'starting', 'in_progress', 'finished', 'cancelled');
CREATE TYPE room_type   AS ENUM ('public', 'private');

CREATE TABLE public.rooms (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code            TEXT UNIQUE NOT NULL DEFAULT upper(substring(gen_random_uuid()::text, 1, 6)),
  host_id         UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  status          room_status NOT NULL DEFAULT 'waiting',
  room_type       room_type   NOT NULL DEFAULT 'public',
  max_players     INTEGER NOT NULL DEFAULT 4,
  current_round   INTEGER NOT NULL DEFAULT 0,
  total_rounds    INTEGER NOT NULL DEFAULT 10,
  waiting_until   TIMESTAMPTZ,
  started_at      TIMESTAMPTZ,
  finished_at     TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_rooms_status ON public.rooms(status);
CREATE INDEX idx_rooms_code   ON public.rooms(code);

-- ============================================================
-- JUGADORES EN SALA
-- ============================================================
CREATE TYPE player_status AS ENUM ('waiting', 'ready', 'playing', 'disconnected', 'finished');

CREATE TABLE public.room_players (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id     UUID NOT NULL REFERENCES public.rooms(id) ON DELETE CASCADE,
  user_id     UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  is_bot      BOOLEAN NOT NULL DEFAULT FALSE,
  bot_level   TEXT CHECK (bot_level IN ('novato', 'promedio', 'experto')),
  bot_name    TEXT,
  bot_avatar  TEXT,
  status      player_status NOT NULL DEFAULT 'waiting',
  seat_number INTEGER NOT NULL,
  score       INTEGER NOT NULL DEFAULT 0,
  correct_answers INTEGER NOT NULL DEFAULT 0,
  streak      INTEGER NOT NULL DEFAULT 0,
  max_streak  INTEGER NOT NULL DEFAULT 0,
  final_rank  INTEGER,
  points_earned INTEGER,
  joined_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (room_id, seat_number),
  UNIQUE (room_id, user_id)
);

CREATE INDEX idx_room_players_room   ON public.room_players(room_id);
CREATE INDEX idx_room_players_user   ON public.room_players(user_id);

-- ============================================================
-- RONDAS DE JUEGO (una fila por pregunta por partida)
-- ============================================================
CREATE TABLE public.game_rounds (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id       UUID NOT NULL REFERENCES public.rooms(id) ON DELETE CASCADE,
  round_number  INTEGER NOT NULL,
  question_id   UUID NOT NULL REFERENCES public.questions(id),
  started_at    TIMESTAMPTZ,
  ends_at       TIMESTAMPTZ,
  finished_at   TIMESTAMPTZ,
  UNIQUE (room_id, round_number)
);

CREATE INDEX idx_game_rounds_room ON public.game_rounds(room_id);

-- ============================================================
-- RESPUESTAS DE JUGADORES
-- ============================================================
CREATE TABLE public.player_answers (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  round_id        UUID NOT NULL REFERENCES public.game_rounds(id) ON DELETE CASCADE,
  room_player_id  UUID NOT NULL REFERENCES public.room_players(id) ON DELETE CASCADE,
  selected_option CHAR(1) CHECK (selected_option IN ('A','B','C','D')),
  is_correct      BOOLEAN,
  answer_time_ms  INTEGER,  -- milisegundos que tardó en responder
  points_earned   INTEGER NOT NULL DEFAULT 0,
  answered_at     TIMESTAMPTZ,
  UNIQUE (round_id, room_player_id)
);

-- ============================================================
-- COMODINES / POWER-UPS
-- ============================================================
CREATE TYPE powerup_type AS ENUM ('fifty_fifty', 'extra_time', 'skip');

CREATE TABLE public.user_powerups (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type        powerup_type NOT NULL,
  quantity    INTEGER NOT NULL DEFAULT 0,
  UNIQUE (user_id, type)
);

-- Registro de uso de comodines en partida
CREATE TABLE public.powerup_usage (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  round_id        UUID NOT NULL REFERENCES public.game_rounds(id) ON DELETE CASCADE,
  room_player_id  UUID NOT NULL REFERENCES public.room_players(id) ON DELETE CASCADE,
  type            powerup_type NOT NULL,
  used_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- RECARGA DIARIA DE COMODINES
-- ============================================================
CREATE TABLE public.daily_powerup_claims (
  id        UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id   UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  claimed_date DATE NOT NULL DEFAULT CURRENT_DATE,
  UNIQUE (user_id, claimed_date)
);

-- ============================================================
-- DESAFÍOS (para ganar comodines extra)
-- ============================================================
CREATE TABLE public.challenges (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title         TEXT NOT NULL,
  description   TEXT NOT NULL,
  requirement   JSONB NOT NULL,  -- {"type": "win_streak", "value": 3}
  reward_type   powerup_type NOT NULL,
  reward_qty    INTEGER NOT NULL DEFAULT 1,
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.user_challenges (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id      UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  challenge_id UUID NOT NULL REFERENCES public.challenges(id) ON DELETE CASCADE,
  progress     INTEGER NOT NULL DEFAULT 0,
  completed_at TIMESTAMPTZ,
  UNIQUE (user_id, challenge_id)
);

-- ============================================================
-- PREMIOS (configurados por admin)
-- ============================================================
CREATE TABLE public.prizes (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name            TEXT NOT NULL,
  description     TEXT,
  image_url       TEXT,
  points_required INTEGER NOT NULL,
  stock           INTEGER NOT NULL DEFAULT 0,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- SOLICITUDES DE CANJE
-- ============================================================
CREATE TYPE redemption_status AS ENUM ('pending', 'approved', 'rejected', 'delivered');

CREATE TABLE public.prize_redemptions (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  prize_id    UUID NOT NULL REFERENCES public.prizes(id) ON DELETE RESTRICT,
  status      redemption_status NOT NULL DEFAULT 'pending',
  notes       TEXT,
  admin_notes TEXT,
  points_spent INTEGER NOT NULL,
  requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at  TIMESTAMPTZ
);

CREATE INDEX idx_redemptions_user   ON public.prize_redemptions(user_id);
CREATE INDEX idx_redemptions_status ON public.prize_redemptions(status);

-- ============================================================
-- LEADERBOARD SEMANAL (tabla auxiliar, se reinicia cada lunes)
-- ============================================================
CREATE TABLE public.leaderboard_weekly (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  week_start  DATE NOT NULL,
  points      INTEGER NOT NULL DEFAULT 0,
  UNIQUE (user_id, week_start)
);

CREATE INDEX idx_leaderboard_week ON public.leaderboard_weekly(week_start, points DESC);

-- ============================================================
-- ROLES DE ADMINISTRADOR
-- ============================================================
CREATE TABLE public.admin_users (
  user_id     UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- FUNCIONES Y TRIGGERS
-- ============================================================

-- Trigger: crear perfil automáticamente al registrarse
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, display_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    NEW.raw_user_meta_data->>'avatar_url'
  );

  -- Inicializar comodines (1 de cada tipo)
  INSERT INTO public.user_powerups (user_id, type, quantity) VALUES
    (NEW.id, 'fifty_fifty', 1),
    (NEW.id, 'extra_time',  1),
    (NEW.id, 'skip',        1);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Trigger: actualizar nivel automáticamente al sumar puntos
CREATE OR REPLACE FUNCTION public.update_user_level()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.profiles
  SET level_id = (
    SELECT id FROM public.levels
    WHERE min_points <= NEW.total_points
      AND (max_points IS NULL OR max_points >= NEW.total_points)
    ORDER BY id DESC
    LIMIT 1
  )
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_points_updated
  AFTER UPDATE OF total_points ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_user_level();

-- Función: obtener preguntas aleatorias para una partida
CREATE OR REPLACE FUNCTION public.get_game_questions(
  p_total INTEGER DEFAULT 10
)
RETURNS SETOF public.questions AS $$
  -- 30% fácil, 40% medio, 30% difícil
  (SELECT * FROM public.questions WHERE difficulty = 1 AND is_active = TRUE ORDER BY RANDOM() LIMIT CEIL(p_total * 0.3))
  UNION ALL
  (SELECT * FROM public.questions WHERE difficulty = 2 AND is_active = TRUE ORDER BY RANDOM() LIMIT FLOOR(p_total * 0.4))
  UNION ALL
  (SELECT * FROM public.questions WHERE difficulty = 3 AND is_active = TRUE ORDER BY RANDOM() LIMIT CEIL(p_total * 0.3))
  LIMIT p_total;
$$ LANGUAGE SQL STABLE;

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

ALTER TABLE public.profiles          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rooms             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.room_players      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.game_rounds       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.player_answers    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_powerups     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.powerup_usage     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_powerup_claims ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_challenges   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prizes            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prize_redemptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leaderboard_weekly ENABLE ROW LEVEL SECURITY;

-- Profiles: lectura pública, escritura solo propia
CREATE POLICY "profiles_read_all"   ON public.profiles FOR SELECT USING (TRUE);
CREATE POLICY "profiles_update_own" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Rooms: lectura pública (para unirse), creación autenticada
CREATE POLICY "rooms_read_all"     ON public.rooms FOR SELECT USING (TRUE);
CREATE POLICY "rooms_insert_auth"  ON public.rooms FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "rooms_update_host"  ON public.rooms FOR UPDATE USING (auth.uid() = host_id);

-- Room players: ver todos en la misma sala, insertar solo para sí mismo
CREATE POLICY "room_players_read"   ON public.room_players FOR SELECT USING (TRUE);
CREATE POLICY "room_players_insert" ON public.room_players FOR INSERT WITH CHECK (
  auth.uid() = user_id OR is_bot = TRUE
);
CREATE POLICY "room_players_update" ON public.room_players FOR UPDATE USING (
  auth.uid() = user_id OR is_bot = TRUE
);

-- Game rounds: lectura para participantes de la sala
CREATE POLICY "game_rounds_read" ON public.game_rounds FOR SELECT USING (TRUE);

-- Player answers: solo ver las propias (la respuesta correcta se revela por Edge Function)
CREATE POLICY "answers_read_own"   ON public.player_answers FOR SELECT USING (
  room_player_id IN (
    SELECT id FROM public.room_players WHERE user_id = auth.uid()
  )
);
CREATE POLICY "answers_insert_own" ON public.player_answers FOR INSERT WITH CHECK (
  room_player_id IN (
    SELECT id FROM public.room_players WHERE user_id = auth.uid()
  )
);

-- Powerups: solo propios
CREATE POLICY "powerups_own"       ON public.user_powerups    FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "powerup_usage_own"  ON public.powerup_usage    FOR ALL USING (
  room_player_id IN (SELECT id FROM public.room_players WHERE user_id = auth.uid())
);
CREATE POLICY "daily_claims_own"   ON public.daily_powerup_claims FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "challenges_own"     ON public.user_challenges  FOR ALL USING (auth.uid() = user_id);

-- Prizes: lectura pública activas
CREATE POLICY "prizes_read_active" ON public.prizes FOR SELECT USING (is_active = TRUE);

-- Redemptions: solo propias
CREATE POLICY "redemptions_own"    ON public.prize_redemptions FOR ALL USING (auth.uid() = user_id);

-- Leaderboard: lectura pública
CREATE POLICY "leaderboard_read"   ON public.leaderboard_weekly FOR SELECT USING (TRUE);
CREATE POLICY "leaderboard_upsert" ON public.leaderboard_weekly FOR ALL USING (auth.uid() = user_id);

-- Levels y questions: lectura pública (sin RLS)
ALTER TABLE public.levels    DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.questions DISABLE ROW LEVEL SECURITY;

-- ============================================================
-- DATOS INICIALES DE DESAFÍOS
-- ============================================================
INSERT INTO public.challenges (title, description, requirement, reward_type, reward_qty) VALUES
  ('Primera Victoría',   'Gana tu primera partida',
   '{"type": "win_count", "value": 1}',    'fifty_fifty', 2),
  ('En Racha',           'Responde 5 preguntas seguidas correctamente',
   '{"type": "answer_streak", "value": 5}', 'extra_time', 2),
  ('Invencible',         'Gana 3 partidas consecutivas',
   '{"type": "win_streak", "value": 3}',   'skip', 3),
  ('Enciclopedia',       'Responde 100 preguntas correctamente',
   '{"type": "correct_answers", "value": 100}', 'fifty_fifty', 5),
  ('Leyenda en Progreso','Juega 50 partidas',
   '{"type": "games_played", "value": 50}', 'extra_time', 5);

-- Premios de ejemplo
INSERT INTO public.prizes (name, description, points_required, stock) VALUES
  ('Libro Milton Ochoa',        'Libro de matemáticas autografiado',     2000,  50),
  ('Curso Online Gratis',       'Acceso a un curso virtual de 1 mes',    5000,  100),
  ('Camiseta Oficial',          'Camiseta de la marca Milton Ochoa',     3000,  30),
  ('Tutoría Personalizada 1h',  'Sesión 1 a 1 con un tutor certificado', 8000,  20),
  ('Kit Escolar Completo',      'Cuadernos, lápices y más',              1500,  80);
