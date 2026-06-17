import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/supabase_service.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/admin/admin_scaffold.dart';

final _filtersProvider = StateProvider<Map<String, dynamic>>((ref) => {});

class AdminQuestionsScreen extends ConsumerWidget {
  const AdminQuestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters  = ref.watch(_filtersProvider);
    final qAsync   = ref.watch(adminQuestionsProvider(filters));

    return AdminScaffold(
      title: 'Gestión de Preguntas',
      actions: [
        IconButton(
          icon: const Icon(Icons.auto_fix_high_rounded, color: AppColors.gold),
          tooltip: 'Generar 30 preguntas nuevas',
          onPressed: () => _generateQuestions(context, ref),
        ),
      ],
      body: Column(
        children: [
          _FilterBar(filters: filters),
          Expanded(
            child: qAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:   (e, _) => Center(child: Text('Error: $e')),
              data:    (questions) => questions.isEmpty
                  ? const Center(child: Text('Sin preguntas con estos filtros',
                      style: TextStyle(color: AppColors.textHint)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: questions.length,
                      itemBuilder: (_, i) => _QuestionTile(
                        question: questions[i],
                        onToggle: () => _toggleQuestion(ref, questions[i], filters),
                        onEdit:   () => _showEditDialog(context, ref, questions[i], filters),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateQuestions(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Generar preguntas'),
        content: const Text(
          'Se generarán 30 preguntas nuevas usando Claude AI y se agregarán al caché.\n\n'
          'Distribución: 30% fácil, 40% media, 30% difícil.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Generar')),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generando preguntas... puede tomar 10-15 segundos')));

    final response = await SupabaseService.client.functions.invoke(
      'generate-questions', body: {'count': 30});

    if (!context.mounted) return;
    final ok = response.status == 200;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? '¡Preguntas generadas exitosamente!'
          : 'Error al generar preguntas'),
      backgroundColor: ok ? AppColors.success : AppColors.error,
    ));
    if (ok) ref.invalidate(adminQuestionsProvider);
  }

  Future<void> _toggleQuestion(
      WidgetRef ref, Map<String, dynamic> q, Map<String, dynamic> filters) async {
    await SupabaseService.client
        .from('questions')
        .update({'is_active': !(q['is_active'] as bool)})
        .eq('id', q['id']);
    ref.invalidate(adminQuestionsProvider);
  }

  void _showEditDialog(BuildContext context, WidgetRef ref,
      Map<String, dynamic> q, Map<String, dynamic> filters) {
    showDialog(
      context: context,
      builder: (_) => _QuestionEditDialog(
        question: q,
        onSave: (data) async {
          await SupabaseService.client
              .from('questions')
              .update(data)
              .eq('id', q['id']);
          ref.invalidate(adminQuestionsProvider);
        },
      ),
    );
  }
}

// ─── Filtros ───────────────────────────────────────────────────────────────
class _FilterBar extends ConsumerWidget {
  final Map<String, dynamic> filters;
  const _FilterBar({required this.filters});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    color: AppColors.primaryDark,
    child: Row(
      children: [
        Expanded(
          child: _FilterDropdown<int?>(
            label: 'Dificultad',
            value: filters['difficulty'] as int?,
            items: const [
              DropdownMenuItem(value: null, child: Text('Todas')),
              DropdownMenuItem(value: 1,    child: Text('Fácil')),
              DropdownMenuItem(value: 2,    child: Text('Media')),
              DropdownMenuItem(value: 3,    child: Text('Difícil')),
            ],
            onChanged: (v) => ref.read(_filtersProvider.notifier)
                .update((s) => {...s, 'difficulty': v}),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _FilterDropdown<bool?>(
            label: 'Estado',
            value: filters['is_active'] as bool?,
            items: const [
              DropdownMenuItem(value: null,  child: Text('Todas')),
              DropdownMenuItem(value: true,  child: Text('Activas')),
              DropdownMenuItem(value: false, child: Text('Inactivas')),
            ],
            onChanged: (v) => ref.read(_filtersProvider.notifier)
                .update((s) => {...s, 'is_active': v}),
          ),
        ),
        if (filters.values.any((v) => v != null))
          IconButton(
            icon: const Icon(Icons.clear, color: AppColors.textHint, size: 18),
            onPressed: () => ref.read(_filtersProvider.notifier).state = {},
          ),
      ],
    ),
  );
}

class _FilterDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    value: value,
    items: items,
    onChanged: onChanged,
    dropdownColor: AppColors.surfaceLight,
    style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontFamily: 'Poppins'),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 11, color: AppColors.textHint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      isDense: true,
    ),
  );
}

// ─── Tile de pregunta ──────────────────────────────────────────────────────
class _QuestionTile extends StatelessWidget {
  final Map<String, dynamic> question;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  const _QuestionTile({
    required this.question,
    required this.onToggle,
    required this.onEdit,
  });

  static const _diffColors = [AppColors.diffEasy, AppColors.diffMedium, AppColors.diffHard];
  static const _diffLabels = ['Fácil', 'Media', 'Difícil'];

  @override
  Widget build(BuildContext context) {
    final isActive    = question['is_active'] as bool;
    final difficulty  = (question['difficulty'] as int).clamp(1, 3) - 1;
    final successRate = question['success_rate'] as num;
    final timesUsed   = question['times_used'] as int;
    final color       = _diffColors[difficulty];

    return Opacity(
      opacity: isActive ? 1.0 : 0.55,
      child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(_diffLabels[difficulty],
                  style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(question['category'] as String,
                  style: const TextStyle(color: AppColors.textHint, fontSize: 10),
                  overflow: TextOverflow.ellipsis),
              ),
              IconButton(
                icon: Icon(isActive ? Icons.visibility : Icons.visibility_off,
                  color: AppColors.textHint, size: 18),
                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                onPressed: onToggle,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: AppColors.textHint, size: 18),
                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                onPressed: onEdit,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(question['question_text'] as String,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.3),
            maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Row(
            children: [
              _MiniStat('Usada', '$timesUsed veces'),
              const SizedBox(width: 12),
              _MiniStat('Aciertos', '$successRate%',
                color: successRate >= 60 ? AppColors.success
                     : successRate >= 30 ? AppColors.warning
                     : AppColors.error),
            ],
          ),
        ],
      ),
    ));
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _MiniStat(this.label, this.value, {this.color = AppColors.textSecondary});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('$label: ', style: const TextStyle(color: AppColors.textHint, fontSize: 10)),
      Text(value, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    ],
  );
}

// ─── Diálogo de edición ────────────────────────────────────────────────────
class _QuestionEditDialog extends StatefulWidget {
  final Map<String, dynamic> question;
  final Future<void> Function(Map<String, dynamic>) onSave;
  const _QuestionEditDialog({required this.question, required this.onSave});

  @override
  State<_QuestionEditDialog> createState() => _QuestionEditDialogState();
}

class _QuestionEditDialogState extends State<_QuestionEditDialog> {
  late final _text   = TextEditingController(text: widget.question['question_text'] as String);
  late final _a      = TextEditingController(text: widget.question['option_a'] as String);
  late final _b      = TextEditingController(text: widget.question['option_b'] as String);
  late final _c      = TextEditingController(text: widget.question['option_c'] as String);
  late final _d      = TextEditingController(text: widget.question['option_d'] as String);
  late String _correct = widget.question['correct_option'] as String;
  late int    _diff    = widget.question['difficulty'] as int;
  bool _loading = false;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: AppColors.surface,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text('Editar pregunta',
            style: TextStyle(color: AppColors.textPrimary,
              fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _tf(_text, 'Pregunta', maxLines: 3),
                  const SizedBox(height: 10),
                  _tf(_a, 'Opción A'), const SizedBox(height: 8),
                  _tf(_b, 'Opción B'), const SizedBox(height: 8),
                  _tf(_c, 'Opción C'), const SizedBox(height: 8),
                  _tf(_d, 'Opción D'), const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _correct,
                        dropdownColor: AppColors.surfaceLight,
                        decoration: const InputDecoration(labelText: 'Respuesta correcta', isDense: true),
                        style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Poppins'),
                        items: ['A','B','C','D'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                        onChanged: (v) => setState(() => _correct = v!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _diff,
                        dropdownColor: AppColors.surfaceLight,
                        decoration: const InputDecoration(labelText: 'Dificultad', isDense: true),
                        style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Poppins'),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Fácil')),
                          DropdownMenuItem(value: 2, child: Text('Media')),
                          DropdownMenuItem(value: 3, child: Text('Difícil')),
                        ],
                        onChanged: (v) => setState(() => _diff = v!),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2,
                          color: AppColors.primaryDark))
                    : const Text('Guardar'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _tf(TextEditingController c, String label, {int maxLines = 1}) =>
      TextFormField(
        controller: c, maxLines: maxLines,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        decoration: InputDecoration(labelText: label, isDense: true),
      );

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await widget.onSave({
        'question_text':  _text.text.trim(),
        'option_a':       _a.text.trim(),
        'option_b':       _b.text.trim(),
        'option_c':       _c.text.trim(),
        'option_d':       _d.text.trim(),
        'correct_option': _correct,
        'difficulty':     _diff,
      });
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
