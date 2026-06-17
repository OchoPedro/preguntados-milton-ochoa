-- ============================================================
-- Helpers para desafíos y comodines
-- ============================================================

-- Dar comodines como recompensa (llamado desde Edge Function)
CREATE OR REPLACE FUNCTION public.grant_powerup(
  p_user_id UUID,
  p_type    TEXT,
  p_qty     INTEGER DEFAULT 1
)
RETURNS VOID AS $$
BEGIN
  INSERT INTO public.user_powerups (user_id, type, quantity)
  VALUES (p_user_id, p_type::powerup_type, p_qty)
  ON CONFLICT (user_id, type)
  DO UPDATE SET quantity = user_powerups.quantity + EXCLUDED.quantity;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Leer inventario de comodines del usuario actual
CREATE OR REPLACE FUNCTION public.get_my_powerups()
RETURNS TABLE (type TEXT, quantity INTEGER) AS $$
  SELECT type::TEXT, quantity
  FROM public.user_powerups
  WHERE user_id = auth.uid();
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

-- Inicializar user_challenges para todos los desafíos activos
-- (se llama automáticamente al registrarse un nuevo usuario)
CREATE OR REPLACE FUNCTION public.init_user_challenges(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
  INSERT INTO public.user_challenges (user_id, challenge_id, progress)
  SELECT p_user_id, id, 0
  FROM   public.challenges
  WHERE  is_active = TRUE
  ON CONFLICT (user_id, challenge_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Actualizar trigger de nuevo usuario para inicializar desafíos
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

  -- Inicializar progreso en todos los desafíos activos
  INSERT INTO public.user_challenges (user_id, challenge_id, progress)
  SELECT NEW.id, id, 0
  FROM   public.challenges
  WHERE  is_active = TRUE;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Vista pública de desafíos con progreso del usuario actual
CREATE OR REPLACE VIEW public.my_challenges AS
SELECT
  c.id,
  c.title,
  c.description,
  c.requirement,
  c.reward_type,
  c.reward_qty,
  COALESCE(uc.progress, 0)      AS progress,
  (c.requirement->>'value')::INT AS target,
  uc.completed_at,
  CASE
    WHEN uc.completed_at IS NOT NULL THEN 'completed'
    WHEN COALESCE(uc.progress, 0) > 0 THEN 'in_progress'
    ELSE 'not_started'
  END AS status
FROM public.challenges c
LEFT JOIN public.user_challenges uc
  ON uc.challenge_id = c.id AND uc.user_id = auth.uid()
WHERE c.is_active = TRUE
ORDER BY
  CASE WHEN uc.completed_at IS NOT NULL THEN 2 ELSE 1 END,
  COALESCE(uc.progress, 0) DESC;

GRANT SELECT ON public.my_challenges TO authenticated;
