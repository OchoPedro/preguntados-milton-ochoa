import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/supabase_service.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/admin/admin_scaffold.dart';

class AdminPrizesScreen extends ConsumerWidget {
  const AdminPrizesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prizesAsync = ref.watch(adminPrizesProvider);

    return AdminScaffold(
      title: 'Gestión de Premios',
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.primaryDark,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo premio'),
        onPressed: () => _showPrizeDialog(context, ref, null),
      ),
      body: prizesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data:    (prizes) => prizes.isEmpty
            ? const Center(child: Text('Sin premios configurados',
                style: TextStyle(color: AppColors.textHint)))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: prizes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _PrizeTile(
                  prize: prizes[i],
                  onEdit:   () => _showPrizeDialog(context, ref, prizes[i]),
                  onToggle: () => _togglePrize(ref, prizes[i]),
                  onDelete: () => _confirmDelete(context, ref, prizes[i]),
                ),
              ),
      ),
    );
  }

  void _showPrizeDialog(BuildContext context, WidgetRef ref, Map<String, dynamic>? prize) {
    showDialog(
      context: context,
      builder: (_) => _PrizeFormDialog(
        prize: prize,
        onSave: (data) async {
          if (prize == null) {
            await SupabaseService.client.from('prizes').insert(data);
          } else {
            await SupabaseService.client.from('prizes')
                .update(data).eq('id', prize['id']);
          }
          ref.invalidate(adminPrizesProvider);
        },
      ),
    );
  }

  void _togglePrize(WidgetRef ref, Map<String, dynamic> prize) async {
    await SupabaseService.client.from('prizes')
        .update({'is_active': !(prize['is_active'] as bool)})
        .eq('id', prize['id']);
    ref.invalidate(adminPrizesProvider);
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Map<String, dynamic> prize) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('¿Eliminar premio?'),
        content: Text('Se eliminará "${prize['name']}". Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              await SupabaseService.client.from('prizes').delete().eq('id', prize['id']);
              ref.invalidate(adminPrizesProvider);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _PrizeTile extends StatelessWidget {
  final Map<String, dynamic> prize;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _PrizeTile({
    required this.prize,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = prize['is_active'] as bool;
    final stock    = prize['stock'] as int;

    return Opacity(
      opacity: isActive ? 1.0 : 0.6,
      child: Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? AppColors.border : AppColors.border.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.card_giftcard_rounded,
            color: isActive ? AppColors.gold : AppColors.textHint, size: 26),
        ),
        title: Text(prize['name'] as String,
          style: TextStyle(
            color: isActive ? AppColors.textPrimary : AppColors.textHint,
            fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Row(children: [
              _Chip('${prize['points_required']} pts', AppColors.gold),
              const SizedBox(width: 6),
              _Chip('Stock: $stock', stock > 0 ? AppColors.success : AppColors.error),
              const SizedBox(width: 6),
              _Chip(isActive ? 'Activo' : 'Inactivo',
                isActive ? AppColors.success : AppColors.textHint),
            ]),
          ],
        ),
        trailing: PopupMenuButton<String>(
          color: AppColors.surfaceLight,
          icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
          onSelected: (v) {
            if (v == 'edit')   onEdit();
            if (v == 'toggle') onToggle();
            if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit',
              child: Row(children: [Icon(Icons.edit_rounded, size: 16),
                SizedBox(width: 8), Text('Editar')])),
            PopupMenuItem(value: 'toggle',
              child: Row(children: [
                Icon(isActive ? Icons.visibility_off : Icons.visibility, size: 16),
                const SizedBox(width: 8),
                Text(isActive ? 'Desactivar' : 'Activar')])),
            const PopupMenuItem(value: 'delete',
              child: Row(children: [Icon(Icons.delete_rounded, size: 16, color: AppColors.error),
                SizedBox(width: 8), Text('Eliminar', style: TextStyle(color: AppColors.error))])),
          ],
        ),
      ),
    ));
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color  color;
  const _Chip(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
  );
}

// ─── Formulario de premio ──────────────────────────────────────────────────
class _PrizeFormDialog extends StatefulWidget {
  final Map<String, dynamic>? prize;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const _PrizeFormDialog({this.prize, required this.onSave});

  @override
  State<_PrizeFormDialog> createState() => _PrizeFormDialogState();
}

class _PrizeFormDialogState extends State<_PrizeFormDialog> {
  final _formKey    = GlobalKey<FormState>();
  late final _name  = TextEditingController(text: widget.prize?['name'] as String? ?? '');
  late final _desc  = TextEditingController(text: widget.prize?['description'] as String? ?? '');
  late final _pts   = TextEditingController(
      text: widget.prize?['points_required']?.toString() ?? '');
  late final _stock = TextEditingController(
      text: widget.prize?['stock']?.toString() ?? '');
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose(); _desc.dispose(); _pts.dispose(); _stock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AppColors.surface,
    title: Text(widget.prize == null ? 'Nuevo premio' : 'Editar premio'),
    content: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(_name, 'Nombre del premio', required: true),
            const SizedBox(height: 12),
            _field(_desc, 'Descripción (opcional)', required: false, maxLines: 2),
            const SizedBox(height: 12),
            _field(_pts, 'Puntos requeridos', keyboardType: TextInputType.number, required: true),
            const SizedBox(height: 12),
            _field(_stock, 'Stock disponible', keyboardType: TextInputType.number, required: true),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      ElevatedButton(
        onPressed: _loading ? null : _save,
        child: _loading
            ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDark))
            : Text(widget.prize == null ? 'Crear' : 'Guardar'),
      ),
    ],
  );

  Widget _field(TextEditingController ctrl, String label, {
    bool required = false, int maxLines = 1,
    TextInputType? keyboardType,
  }) => TextFormField(
    controller: ctrl,
    maxLines:   maxLines,
    keyboardType: keyboardType,
    style: const TextStyle(color: AppColors.textPrimary),
    decoration: InputDecoration(labelText: label),
    validator: required ? (v) => v == null || v.trim().isEmpty ? 'Campo requerido' : null : null,
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await widget.onSave({
        'name':             _name.text.trim(),
        'description':      _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        'points_required':  int.parse(_pts.text.trim()),
        'stock':            int.parse(_stock.text.trim()),
        'updated_at':       DateTime.now().toUtc().toIso8601String(),
      });
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
