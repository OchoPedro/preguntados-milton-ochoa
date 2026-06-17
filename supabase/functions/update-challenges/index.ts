/**
 * Llamada al final de cada partida para actualizar el progreso
 * de desafíos del usuario. Invocada desde _endGame en validate-answer.
 */
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin':  '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface GameResult {
  user_id:         string
  won:             boolean
  correct_answers: number
  max_streak:      number
  games_played_total: number
  correct_answers_total: number
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    const result: GameResult = await req.json()

    // Cargar todos los desafíos activos
    const { data: challenges } = await supabase
      .from('challenges')
      .select('*')
      .eq('is_active', true)

    if (!challenges?.length) {
      return new Response(JSON.stringify({ updated: 0 }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    let updated = 0

    for (const challenge of challenges) {
      const req  = challenge.requirement as { type: string; value: number }
      let newProgress = 0

      switch (req.type) {
        case 'win_count':
          newProgress = result.won ? 1 : 0  // incremental (se suma en BD)
          break
        case 'answer_streak':
          newProgress = result.max_streak
          break
        case 'correct_answers':
          newProgress = result.correct_answers_total
          break
        case 'games_played':
          newProgress = result.games_played_total
          break
        case 'win_streak':
          // Se maneja por separado con un contador de racha de victorias
          continue
        default:
          continue
      }

      // Obtener progreso actual del usuario en este desafío
      const { data: existing } = await supabase
        .from('user_challenges')
        .select('id, progress, completed_at')
        .eq('user_id', result.user_id)
        .eq('challenge_id', challenge.id)
        .maybeSingle()

      if (existing?.completed_at) continue  // ya completado, omitir

      const currentProgress = existing?.progress ?? 0

      // Para tipos acumulativos (correct_answers, games_played) usamos el total
      // Para tipos de evento (win_count) sumamos al progreso actual
      let finalProgress: number
      if (['correct_answers', 'games_played', 'answer_streak'].includes(req.type)) {
        finalProgress = newProgress
      } else {
        finalProgress = currentProgress + newProgress
      }

      finalProgress = Math.min(finalProgress, req.value)

      const isNowComplete = finalProgress >= req.value
      const completedAt   = isNowComplete ? new Date().toISOString() : null

      // Upsert progreso
      await supabase
        .from('user_challenges')
        .upsert({
          user_id:      result.user_id,
          challenge_id: challenge.id,
          progress:     finalProgress,
          completed_at: completedAt,
        }, { onConflict: 'user_id,challenge_id' })

      // Si se completó: dar la recompensa
      if (isNowComplete && !existing?.completed_at) {
        await supabase
          .from('user_powerups')
          .upsert({
            user_id:  result.user_id,
            type:     challenge.reward_type,
            quantity: supabase.rpc('increment', { x: challenge.reward_qty }),
          }, { onConflict: 'user_id,type' })

        // Forma directa (más confiable)
        await supabase.rpc('grant_powerup', {
          p_user_id: result.user_id,
          p_type:    challenge.reward_type,
          p_qty:     challenge.reward_qty,
        })

        updated++
      }
    }

    return new Response(JSON.stringify({ updated }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })

  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})
