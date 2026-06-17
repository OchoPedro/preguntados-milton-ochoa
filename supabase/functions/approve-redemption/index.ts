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
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Sin autorización' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    // Verificar que el llamante es admin
    const supabaseUser = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } }
    )

    const { data: { user } } = await supabaseUser.auth.getUser()
    if (!user) {
      return new Response(JSON.stringify({ error: 'No autenticado' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    const { data: adminCheck } = await supabase
      .from('admin_users')
      .select('user_id')
      .eq('user_id', user.id)
      .single()

    if (!adminCheck) {
      return new Response(JSON.stringify({ error: 'No eres administrador' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    const { redemption_id, action, admin_notes } = await req.json()
    if (!['approved', 'rejected', 'delivered'].includes(action)) {
      return new Response(JSON.stringify({ error: 'Acción inválida' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    // Obtener la solicitud
    const { data: redemption, error: rErr } = await supabase
      .from('prize_redemptions')
      .select('*, profiles(display_name), prizes(name, points_required)')
      .eq('id', redemption_id)
      .single()

    if (rErr || !redemption) {
      return new Response(JSON.stringify({ error: 'Solicitud no encontrada' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    // Si se rechaza: devolver puntos al usuario
    if (action === 'rejected' && redemption.status === 'pending') {
      await supabase
        .from('profiles')
        .update({ total_points: supabase.rpc('increment_by', {
          row_id: redemption.user_id,
          amount: redemption.points_spent
        })})

      // Forma alternativa directa
      await supabase.rpc('add_points_and_stats', {
        p_user_id: redemption.user_id,
        p_points:  redemption.points_spent,
        p_won:     false,
      })
    }

    // Actualizar estado
    await supabase
      .from('prize_redemptions')
      .update({
        status:      action,
        admin_notes: admin_notes ?? null,
        resolved_at: new Date().toISOString(),
      })
      .eq('id', redemption_id)

    return new Response(
      JSON.stringify({ success: true, action, redemption_id }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
})
