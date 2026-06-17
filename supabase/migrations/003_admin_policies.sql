-- ============================================================
-- POLÍTICAS DE ADMINISTRADOR
-- ============================================================

-- Función auxiliar para verificar si el usuario actual es admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.admin_users WHERE user_id = auth.uid()
  );
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- ── Prizes: admin puede crear, editar y eliminar ──────────────
CREATE POLICY "prizes_admin_all" ON public.prizes
  FOR ALL USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ── Questions: admin puede editar y desactivar ───────────────
CREATE POLICY "questions_admin_all" ON public.questions
  FOR ALL USING (public.is_admin())
  WITH CHECK (public.is_admin());

ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;

-- Lectura pública de preguntas activas (para el juego)
CREATE POLICY "questions_read_active" ON public.questions
  FOR SELECT USING (is_active = TRUE OR public.is_admin());

-- ── Prize redemptions: admin puede ver y actualizar todas ────
CREATE POLICY "redemptions_admin_all" ON public.prize_redemptions
  FOR ALL USING (public.is_admin());

-- ── Admin users: solo admins pueden verse entre sí ───────────
ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "admin_users_read" ON public.admin_users
  FOR SELECT USING (public.is_admin());

-- ── Profiles: admin puede ver todos ─────────────────────────
CREATE POLICY "profiles_admin_read" ON public.profiles
  FOR SELECT USING (public.is_admin());

-- ── Rooms y estadísticas: admin puede ver todo ──────────────
CREATE POLICY "rooms_admin_read"        ON public.rooms         FOR SELECT USING (public.is_admin());
CREATE POLICY "room_players_admin_read" ON public.room_players  FOR SELECT USING (public.is_admin());
CREATE POLICY "game_rounds_admin_read"  ON public.game_rounds   FOR SELECT USING (public.is_admin());

-- ── Vista de estadísticas para admin ─────────────────────────
CREATE OR REPLACE VIEW public.admin_stats AS
SELECT
  (SELECT COUNT(*) FROM public.profiles)                                AS total_users,
  (SELECT COUNT(*) FROM public.profiles WHERE created_at >= NOW() - INTERVAL '7 days') AS new_users_week,
  (SELECT COUNT(*) FROM public.rooms WHERE status = 'finished')         AS total_games,
  (SELECT COUNT(*) FROM public.rooms WHERE status = 'in_progress')      AS active_games,
  (SELECT COUNT(*) FROM public.questions WHERE is_active = TRUE)        AS total_questions,
  (SELECT COUNT(*) FROM public.prize_redemptions WHERE status = 'pending') AS pending_redemptions,
  (SELECT SUM(total_points) FROM public.profiles)                       AS total_points_awarded;

-- Solo admin puede ver la vista
GRANT SELECT ON public.admin_stats TO authenticated;
CREATE POLICY "admin_stats_view" ON public.admin_stats
  FOR SELECT USING (public.is_admin());

-- ── Vista de preguntas más falladas ─────────────────────────
CREATE OR REPLACE VIEW public.question_stats AS
SELECT
  q.id,
  q.question_text,
  q.category,
  q.difficulty,
  q.times_used,
  q.times_correct,
  q.is_active,
  CASE WHEN q.times_used > 0
    THEN ROUND((q.times_correct::NUMERIC / q.times_used) * 100, 1)
    ELSE 0
  END AS success_rate
FROM public.questions q
ORDER BY success_rate ASC, q.times_used DESC;

GRANT SELECT ON public.question_stats TO authenticated;

-- ── Función: estadísticas de los últimos 7 días (gráfica) ────
CREATE OR REPLACE FUNCTION public.get_games_per_day(p_days INTEGER DEFAULT 7)
RETURNS TABLE (day DATE, games BIGINT) AS $$
  SELECT
    DATE(finished_at) AS day,
    COUNT(*) AS games
  FROM public.rooms
  WHERE status = 'finished'
    AND finished_at >= NOW() - (p_days || ' days')::INTERVAL
  GROUP BY DATE(finished_at)
  ORDER BY day;
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

-- ── Función: top usuarios de la semana ───────────────────────
CREATE OR REPLACE FUNCTION public.get_top_users(p_limit INTEGER DEFAULT 10)
RETURNS TABLE (
  display_name TEXT,
  avatar_url   TEXT,
  total_points INTEGER,
  games_won    INTEGER,
  level_name   TEXT
) AS $$
  SELECT
    p.display_name,
    p.avatar_url,
    p.total_points,
    p.games_won,
    l.name AS level_name
  FROM public.profiles p
  JOIN public.levels l ON l.id = p.level_id
  ORDER BY p.total_points DESC
  LIMIT p_limit;
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

-- ── Agregar primer admin manualmente (ejecutar una sola vez) ─
-- INSERT INTO public.admin_users (user_id)
-- VALUES ('UUID_DEL_USUARIO_ADMIN');
