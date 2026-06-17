-- ============================================================
-- Funciones auxiliares para el juego
-- ============================================================

-- Sumar puntos al perfil del jugador y actualizar estadísticas
CREATE OR REPLACE FUNCTION public.add_points_and_stats(
  p_user_id  UUID,
  p_points   INTEGER,
  p_won      BOOLEAN DEFAULT FALSE
)
RETURNS VOID AS $$
DECLARE
  v_week_start DATE := date_trunc('week', CURRENT_DATE)::DATE;
BEGIN
  -- Actualizar perfil
  UPDATE public.profiles
  SET
    total_points  = total_points + p_points,
    games_played  = games_played + 1,
    games_won     = games_won + (CASE WHEN p_won THEN 1 ELSE 0 END),
    updated_at    = NOW()
  WHERE id = p_user_id;

  -- Actualizar leaderboard semanal
  INSERT INTO public.leaderboard_weekly (user_id, week_start, points)
  VALUES (p_user_id, v_week_start, p_points)
  ON CONFLICT (user_id, week_start)
  DO UPDATE SET points = leaderboard_weekly.points + EXCLUDED.points;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Obtener leaderboard global (top 100)
CREATE OR REPLACE FUNCTION public.get_global_leaderboard(p_limit INTEGER DEFAULT 100)
RETURNS TABLE (
  rank         BIGINT,
  user_id      UUID,
  display_name TEXT,
  avatar_url   TEXT,
  level_id     INTEGER,
  total_points INTEGER,
  games_won    INTEGER
) AS $$
  SELECT
    ROW_NUMBER() OVER (ORDER BY p.total_points DESC) AS rank,
    p.id,
    p.display_name,
    p.avatar_url,
    p.level_id,
    p.total_points,
    p.games_won
  FROM public.profiles p
  ORDER BY p.total_points DESC
  LIMIT p_limit;
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

-- Obtener leaderboard semanal (top 100)
CREATE OR REPLACE FUNCTION public.get_weekly_leaderboard(p_limit INTEGER DEFAULT 100)
RETURNS TABLE (
  rank         BIGINT,
  user_id      UUID,
  display_name TEXT,
  avatar_url   TEXT,
  level_id     INTEGER,
  weekly_points INTEGER
) AS $$
  SELECT
    ROW_NUMBER() OVER (ORDER BY lw.points DESC) AS rank,
    p.id,
    p.display_name,
    p.avatar_url,
    p.level_id,
    lw.points
  FROM public.leaderboard_weekly lw
  JOIN public.profiles p ON p.id = lw.user_id
  WHERE lw.week_start = date_trunc('week', CURRENT_DATE)::DATE
  ORDER BY lw.points DESC
  LIMIT p_limit;
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

-- Reclamar comodines diarios
CREATE OR REPLACE FUNCTION public.claim_daily_powerups(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_today DATE := CURRENT_DATE;
BEGIN
  -- Verificar si ya reclamó hoy
  IF EXISTS (
    SELECT 1 FROM public.daily_powerup_claims
    WHERE user_id = p_user_id AND claimed_date = v_today
  ) THEN
    RETURN FALSE;
  END IF;

  -- Registrar el reclamo
  INSERT INTO public.daily_powerup_claims (user_id, claimed_date)
  VALUES (p_user_id, v_today);

  -- Sumar 1 de cada comodín
  UPDATE public.user_powerups
  SET quantity = quantity + 1
  WHERE user_id = p_user_id;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Canjear un comodín en partida
CREATE OR REPLACE FUNCTION public.use_powerup(
  p_user_id        UUID,
  p_powerup_type   TEXT,
  p_round_id       UUID,
  p_room_player_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
  -- Verificar stock
  IF NOT EXISTS (
    SELECT 1 FROM public.user_powerups
    WHERE user_id = p_user_id
      AND type = p_powerup_type::powerup_type
      AND quantity > 0
  ) THEN
    RETURN FALSE;
  END IF;

  -- Verificar que no lo usó en esta ronda
  IF EXISTS (
    SELECT 1 FROM public.powerup_usage
    WHERE round_id = p_round_id AND room_player_id = p_room_player_id
      AND type = p_powerup_type::powerup_type
  ) THEN
    RETURN FALSE;
  END IF;

  -- Descontar
  UPDATE public.user_powerups
  SET quantity = quantity - 1
  WHERE user_id = p_user_id AND type = p_powerup_type::powerup_type;

  -- Registrar uso
  INSERT INTO public.powerup_usage (round_id, room_player_id, type)
  VALUES (p_round_id, p_room_player_id, p_powerup_type::powerup_type);

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Canjear premio
CREATE OR REPLACE FUNCTION public.redeem_prize(
  p_user_id  UUID,
  p_prize_id UUID
)
RETURNS JSONB AS $$
DECLARE
  v_prize     public.prizes%ROWTYPE;
  v_profile   public.profiles%ROWTYPE;
BEGIN
  SELECT * INTO v_prize   FROM public.prizes   WHERE id = p_prize_id AND is_active = TRUE;
  SELECT * INTO v_profile FROM public.profiles WHERE id = p_user_id;

  IF v_prize.id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Premio no encontrado');
  END IF;

  IF v_prize.stock <= 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Premio sin stock');
  END IF;

  IF v_profile.total_points < v_prize.points_required THEN
    RETURN jsonb_build_object('success', false, 'error', 'Puntos insuficientes');
  END IF;

  -- Descontar puntos
  UPDATE public.profiles
  SET total_points = total_points - v_prize.points_required
  WHERE id = p_user_id;

  -- Reducir stock
  UPDATE public.prizes
  SET stock = stock - 1
  WHERE id = p_prize_id;

  -- Crear solicitud
  INSERT INTO public.prize_redemptions (user_id, prize_id, points_spent)
  VALUES (p_user_id, p_prize_id, v_prize.points_required);

  RETURN jsonb_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
