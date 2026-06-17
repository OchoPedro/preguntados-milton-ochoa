import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin':  '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
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

    const { round_id, room_player_id, selected_option, answer_time_ms } = await req.json()

    // 1. Verificar que la ronda existe y está activa
    const { data: round, error: roundErr } = await supabase
      .from('game_rounds')
      .select('*, questions(correct_option, difficulty), rooms(id, status)')
      .eq('id', round_id)
      .is('finished_at', null)
      .single()

    if (roundErr || !round) {
      return new Response(JSON.stringify({ error: 'Ronda no encontrada o ya terminó' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    // 2. Verificar que ends_at no ha pasado
    const endsAt = new Date(round.ends_at)
    if (new Date() > endsAt) {
      return new Response(JSON.stringify({ error: 'Tiempo agotado' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    // 3. Verificar que no haya respondido ya
    const { data: existing } = await supabase
      .from('player_answers')
      .select('id')
      .eq('round_id', round_id)
      .eq('room_player_id', room_player_id)
      .single()

    if (existing) {
      return new Response(JSON.stringify({ error: 'Ya respondiste esta pregunta' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    // 4. Evaluar respuesta
    const correctOption = round.questions.correct_option as string
    const isCorrect     = selected_option?.toUpperCase() === correctOption

    // 5. Calcular puntos
    let pointsEarned = isCorrect ? 10 : 0

    // Bonus por racha (leer racha actual)
    const { data: player } = await supabase
      .from('room_players')
      .select('streak, score')
      .eq('id', room_player_id)
      .single()

    const currentStreak = (player?.streak ?? 0) + (isCorrect ? 1 : 0)
    if (isCorrect && currentStreak % 3 === 0) {
      pointsEarned += 5  // bonus de racha
    }

    // 6. Guardar respuesta
    await supabase.from('player_answers').insert({
      round_id,
      room_player_id,
      selected_option: selected_option?.toUpperCase() ?? null,
      is_correct:      isCorrect,
      answer_time_ms,
      points_earned:   pointsEarned,
      answered_at:     new Date().toISOString(),
    })

    // 7. Actualizar score y racha del jugador
    await supabase.from('room_players').update({
      score:           (player?.score ?? 0) + pointsEarned,
      correct_answers: supabase.rpc('increment', { x: isCorrect ? 1 : 0 }),
      streak:          isCorrect ? currentStreak : 0,
      max_streak:      Math.max(currentStreak, player?.streak ?? 0),
    }).eq('id', room_player_id)

    // 8. Verificar si todos respondieron → cerrar ronda
    await _checkAndCloseRound(supabase, round_id, round.rooms.id)

    return new Response(
      JSON.stringify({ is_correct: isCorrect, correct_option: correctOption, points_earned: pointsEarned }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
})

async function _checkAndCloseRound(supabase: any, roundId: string, roomId: string) {
  const { data: players } = await supabase
    .from('room_players')
    .select('id')
    .eq('room_id', roomId)
    .neq('status', 'disconnected')

  const { data: answers } = await supabase
    .from('player_answers')
    .select('id')
    .eq('round_id', roundId)

  if (!players || !answers) return
  if (answers.length >= players.length) {
    // Todos respondieron → cerrar ronda
    await supabase.from('game_rounds')
      .update({ finished_at: new Date().toISOString() })
      .eq('id', roundId)

    // Avanzar a la siguiente ronda o terminar partida
    const { data: room } = await supabase
      .from('rooms')
      .select('current_round, total_rounds')
      .eq('id', roomId)
      .single()

    if (room.current_round >= room.total_rounds) {
      await _endGame(supabase, roomId)
    } else {
      await _startNextRound(supabase, roomId, room.current_round + 1)
    }
  }
}

async function _startNextRound(supabase: any, roomId: string, nextRound: number) {
  const { data: questions } = await supabase
    .rpc('get_game_questions', { p_total: 1 })

  if (!questions?.length) return

  const now   = new Date()
  const endsAt = new Date(now.getTime() + 15_000) // 15 segundos

  await supabase.from('game_rounds').insert({
    room_id:      roomId,
    round_number: nextRound,
    question_id:  questions[0].id,
    started_at:   now.toISOString(),
    ends_at:      endsAt.toISOString(),
  })

  await supabase.from('rooms').update({ current_round: nextRound }).eq('id', roomId)
}

async function _endGame(supabase: any, roomId: string) {
  // Obtener jugadores ordenados por score
  const { data: players } = await supabase
    .from('room_players')
    .select('id, user_id, score, correct_answers, is_bot')
    .eq('room_id', roomId)
    .order('score', { ascending: false })

  if (!players) return

  const rankPoints: Record<number, number> = { 1: 100, 2: 60, 3: 30, 4: 10 }

  for (let i = 0; i < players.length; i++) {
    const rank        = i + 1
    const basePoints  = rankPoints[rank] ?? 10
    const totalPoints = basePoints + players[i].score

    await supabase.from('room_players').update({
      final_rank:   rank,
      points_earned: totalPoints,
      status:       'finished',
    }).eq('id', players[i].id)

    // Actualizar perfil del jugador humano
    if (!players[i].is_bot && players[i].user_id) {
      await supabase.rpc('add_points_and_stats', {
        p_user_id:      players[i].user_id,
        p_points:       totalPoints,
        p_won:          rank === 1,
      })
    }
  }

  // Cerrar sala
  await supabase.from('rooms').update({
    status:      'finished',
    finished_at: new Date().toISOString(),
  }).eq('id', roomId)
}
