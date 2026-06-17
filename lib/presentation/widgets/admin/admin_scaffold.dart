import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class AdminScaffold extends StatelessWidget {
  final String     title;
  final Widget     body;
  final List<Widget>? actions;
  final Widget?    floatingActionButton;

  const AdminScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: Text(title),
      actions: actions,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
    ),
    drawer: const _AdminDrawer(),
    body: body,
    floatingActionButton: floatingActionButton,
  );
}

class _AdminDrawer extends StatelessWidget {
  const _AdminDrawer();

  static const _items = [
    _DrawerItem(icon: Icons.dashboard_rounded,   label: 'Dashboard',  route: '/admin'),
    _DrawerItem(icon: Icons.card_giftcard_rounded,label: 'Premios',    route: '/admin/prizes'),
    _DrawerItem(icon: Icons.redeem_rounded,       label: 'Canjes',     route: '/admin/redemptions'),
    _DrawerItem(icon: Icons.quiz_rounded,         label: 'Preguntas',  route: '/admin/questions'),
    _DrawerItem(icon: Icons.people_rounded,       label: 'Usuarios',   route: '/admin/users'),
  ];

  @override
  Widget build(BuildContext context) => Drawer(
    backgroundColor: AppColors.surface,
    child: Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold, width: 1.5),
                ),
                child: const Icon(Icons.admin_panel_settings_rounded,
                  color: AppColors.gold, size: 28),
              ),
              const SizedBox(height: 12),
              const Text('Panel Admin',
                style: TextStyle(color: AppColors.textPrimary,
                  fontSize: 18, fontWeight: FontWeight.w700)),
              const Text('Preguntados Milton Ochoa',
                style: TextStyle(color: AppColors.textHint, fontSize: 11)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...(_items.map((item) => _DrawerTile(item: item))),
        const Spacer(),
        const Divider(color: AppColors.border),
        ListTile(
          leading: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
          title: const Text('Volver a la app',
            style: TextStyle(color: AppColors.textSecondary)),
          onTap: () { Navigator.pop(context); context.go('/home'); },
        ),
        const SizedBox(height: 8),
      ],
    ),
  );
}

class _DrawerItem {
  final IconData icon;
  final String   label;
  final String   route;
  const _DrawerItem({required this.icon, required this.label, required this.route});
}

class _DrawerTile extends StatelessWidget {
  final _DrawerItem item;
  const _DrawerTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final current = GoRouterState.of(context).matchedLocation;
    final isActive = current == item.route;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? AppColors.gold.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(item.icon,
          color: isActive ? AppColors.gold : AppColors.textSecondary, size: 22),
        title: Text(item.label,
          style: TextStyle(
            color: isActive ? AppColors.gold : AppColors.textPrimary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            fontSize: 14,
          )),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () { Navigator.pop(context); context.go(item.route); },
      ),
    );
  }
}
