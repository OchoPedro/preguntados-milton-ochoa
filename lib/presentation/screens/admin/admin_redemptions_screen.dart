import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/supabase_service.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/admin/admin_scaffold.dart';

class AdminRedemptionsScreen extends ConsumerStatefulWidget {
  const AdminRedemptionsScreen({super.key});

  @override
  ConsumerState<AdminRedemptionsScreen> createState() => _AdminRedemptionsScreenState();
}

class _AdminRedemptionsScreenState extends ConsumerState<AdminRedemptionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _statuses = ['pending', 'approved', 'delivered', 'rejected'];
  final _labels   = ['Pendientes', 'Aprobados', 'Entregados', 'Rechazados'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AdminScaffold(
    title: 'Solicitudes de Canje',
    body: Column(
      children: [
        TabBar(
          controller: _tabs,
          isScrollable: true,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: _labels.map((l) => Tab(text: l)).toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: _statuses.map((s) => _RedemptionsList(
              status: s,
              onAction: _handleAction,
            )).toList(),
          ),
        ),
      ],
    ),
  );

  Future<void> _handleAction(
      String redemptionId, String action, String? notes) async {
    final response = await SupabaseService.client.functions.invoke(
      'approve-redemption',
      body: {
        'redemption_id': redemptionId,
        'action':        action,
        'admin_notes':   notes,
      },
    );

    if (!mounted) return;
    final ok = response.status == 200;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Acción realizada correctamente'
          : 'Error al procesar la solicitud'),
      backgroundColor: ok ? AppColors.success : AppColors.error,
    ));
    if (ok) {
      ref.invalidate(adminRedemptionsProvider('pending'));
      ref.invalidate(adminRedemptionsProvider('approved'));
      ref.invalidate(adminRedemptionsProvider('rejected'));
      ref.invalidate(adminRedemptionsProvider('delivered'));
      ref.invalidate(adminStatsProvider);
    }
  }
}

class _RedemptionsList extends ConsumerWidget {
  final String status;
  final Future<void> Function(String, String, String?) onAction;

  const _RedemptionsList({required this.status, required this.onAction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminRedemptionsProvider(status));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(child: Text('Error: $e')),
      data:    (rows) => rows.isEmpty
          ? Center(child: Text('Sin solicitudes ${_statusLabel(status)}',
              style: const TextStyle(color: AppColors.textHint)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              itemBuilder: (_, i) => _RedemptionCard(
                item:     rows[i],
                onAction: onAction,
              ),
            ),
    );
  }

  String _statusLabel(String s) => switch (s) {
    'pending'   => 'pendientes',
    'approved'  => 'aprobadas',
    'delivered' => 'entregadas',
    _           => 'rechazadas',
  };
}

class _RedemptionCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Future<void> Function(String, String, String?) onAction;

  const _RedemptionCard({required this.item, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final status      = item['status'] as String;
    final isPending   = status == 'pending';
    final isApproved  = status == 'approved';
    final userName    = (item['profiles'] as Map?)?['display_name'] as String? ?? 'Usuario';
    final prizeName   = (item['prizes']   as Map?)?['name']         as String? ?? 'Premio';
    final pts         = item['points_spent'] as int;
    final date        = DateTime.parse(item['requested_at'] as String).toLocal();
    final adminNotes  = item['admin_notes'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _statusColor(status).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 18, backgroundColor: AppColors.primary,
                child: Text(userName[0].toUpperCase(),
                  style: const TextStyle(color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName, style: const TextStyle(
                      color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                    Text('Solicitó: $prizeName',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_statusLabel(status),
                  style: TextStyle(color: _statusColor(status),
                    fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Detalles
          Row(children: [
            const Icon(Icons.star, color: AppColors.gold, size: 14),
            const SizedBox(width: 4),
            Text('$pts puntos gastados',
              style: const TextStyle(color: AppColors.gold, fontSize: 12)),
            const Spacer(),
            Text(
              '${date.day}/${date.month}/${date.year}',
              style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
          ]),
          if (adminNotes != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('Nota: $adminNotes',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ),
          ],
          // Acciones
          if (isPending || isApproved) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (isPending) ...[
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () => _showActionDialog(context, 'rejected'),
                      child: const Text('Rechazar', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () => _showActionDialog(context, 'approved'),
                      child: const Text('Aprobar', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
                if (isApproved)
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.local_shipping_rounded, size: 16),
                      label: const Text('Marcar entregado', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8)),
                      onPressed: () => _showActionDialog(context, 'delivered'),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showActionDialog(BuildContext context, String action) {
    final notesCtrl = TextEditingController();
    final label = switch (action) {
      'approved'  => 'Aprobar',
      'rejected'  => 'Rechazar',
      _           => 'Marcar entregado',
    };

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('$label solicitud'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('¿Confirmar "$label"?',
              style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Nota para el usuario (opcional)',
                hintText: 'ej: Se enviará por correo en 3 días'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await onAction(
                item['id'] as String,
                action,
                notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
              );
            },
            child: Text(label),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String s) => switch (s) {
    'pending'   => AppColors.warning,
    'approved'  => AppColors.info,
    'delivered' => AppColors.success,
    _           => AppColors.error,
  };

  String _statusLabel(String s) => switch (s) {
    'pending'   => 'Pendiente',
    'approved'  => 'Aprobado',
    'delivered' => 'Entregado',
    _           => 'Rechazado',
  };
}
