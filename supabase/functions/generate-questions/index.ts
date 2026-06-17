import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin':  '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const CATEGORIES = [
  'Ciencia', 'Historia', 'Geografía', 'Tecnología',
  'Arte y Cultura', 'Entretenimiento', 'Matemáticas',
  'Colombia y Latinoamérica', 'Deportes', 'Literatura',
]

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )
    const claudeKey = Deno.env.get('CLAUDE_API_KEY')!

    const { count = 30 } = await req.json().catch(() => ({}))

    // Distribución: 30% fácil, 40% medio, 30% difícil
    const easy   = Math.round(count * 0.30)
    const medium = Math.round(count * 0.40)
    const hard   = count - easy - medium

    const allQuestions: any[] = []

    for (const [difficulty, qty] of [[1, easy], [2, medium], [3, hard]] as [number, number][]) {
      if (qty <= 0) continue
      const category   = CATEGORIES[Math.floor(Math.random() * CATEGORIES.length)]
      const diffLabel  = difficulty === 1 ? 'fácil' : difficulty === 2 ? 'media' : 'difícil'

      const prompt = `Genera exactamente ${qty} preguntas de trivia de cultura general.
- Categoría: ${category}
- Dificultad: ${diffLabel} (nivel ${difficulty} de 3)
- Formato: 4 opciones (A, B, C, D), solo una correcta
- Para jóvenes colombianos (14-25 años)
- Varía los temas dentro de la categoría

Responde ÚNICAMENTE con un JSON array, sin texto adicional:
[{"question_text":"...","option_a":"...","option_b":"...","option_c":"...","option_d":"...","correct_option":"A","difficulty":${difficulty},"category":"${category}"}]`

      const claudeRes = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': claudeKey,
          'anthropic-version': '2023-06-01',
        },
        body: JSON.stringify({
          model: 'claude-haiku-4-5-20251001',
          max_tokens: 4096,
          messages: [{ role: 'user', content: prompt }],
        }),
      })

      if (!claudeRes.ok) continue

      const claudeData = await claudeRes.json()
      const text       = claudeData.content?.[0]?.text ?? ''

      try {
        const start = text.indexOf('[')
        const end   = text.lastIndexOf(']') + 1
        const parsed = JSON.parse(text.substring(start, end))
        allQuestions.push(...parsed)
      } catch (_) { continue }
    }

    if (allQuestions.length === 0) {
      return new Response(JSON.stringify({ error: 'No se generaron preguntas' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    // Insertar en caché
    const { error: insertErr } = await supabase.from('questions').insert(
      allQuestions.map(q => ({
        question_text:  q.question_text,
        option_a:       q.option_a,
        option_b:       q.option_b,
        option_c:       q.option_c,
        option_d:       q.option_d,
        correct_option: (q.correct_option as string).toUpperCase(),
        difficulty:     q.difficulty,
        category:       q.category,
      }))
    )

    if (insertErr) throw insertErr

    return new Response(
      JSON.stringify({ success: true, generated: allQuestions.length }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
})
