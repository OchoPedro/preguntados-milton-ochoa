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

    const { room_id } = await req.json()

    // 1. Verificar sala existe y está en espera
    const { data: room, error: roomErr } = await supabase
      .from('rooms')
      .select('*, room_players(count)')
      .eq('id', room_id)
      .eq('status', 'waiting')
      .single()

    if (roomErr || !room) {
      return new Response(JSON.stringify({ error: 'Sala no encontrada o ya inició' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    const playerCount = (room.room_players as any[])[0]?.count ?? 0
    if (playerCount < 2) {
      return new Response(JSON.stringify({ error: 'Se necesitan al menos 2 jugadores' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    // 2. Verificar caché de preguntas — regenerar si hay pocas
    const { count: questionCount } = await supabase
      .from('questions')
      .select('id', { count: 'exact', head: true })
      .eq('is_active', true)

    if ((questionCount ?? 0) < 30) {
      // Llamar a generate-questions para repoblar caché
      await supabase.functions.invoke('generate-questions', {
        body: { count: 30 },
      })
    }

    // 3. Cambiar sala a 'starting'
    await supabase.from('rooms').update({
      status:     'starting',
      started_at: new Date().toISOString(),
    }).eq('id', room_id)

    // 4. Marcar todos los jugadores como 'playing'
    await supabase.from('room_players')
      .update({ status: 'playing' })
      .eq('room_id', room_id)

    // 5. Pequeña pausa de cuenta regresiva (3s) → iniciar primera ronda
    await new Promise(r => setTimeout(r, 3000))

    // 6. Cambiar sala a 'in_progress' e iniciar ronda 1
    await supabase.from('rooms').update({
      status:        'in_progress',
      current_round: 1,
    }).eq('id', room_id)

    const { data: questions } = await supabase
      .rpc('get_game_questions', { p_total: 1 })

    if (!questions?.length) {
      return new Response(JSON.stringify({ error: 'Sin preguntas disponibles' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    const now    = new Date()
    const endsAt = new Date(now.getTime() + 15_000)

    await supabase.from('game_rounds').insert({
      room_id,
      round_number: 1,
      question_id:  questions[0].id,
      started_at:   now.toISOString(),
      ends_at:      endsAt.toISOString(),
    })

    return new Response(JSON.stringify({ success: true }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })

  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
})
